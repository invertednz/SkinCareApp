import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../services/analytics.dart';
import '../../../services/analytics_events.dart';
import 'subscription_repository.dart';

/// Service for handling In-App Purchases (IAP) on iOS and Android
class IAPService {
  static final IAPService _instance = IAPService._internal();
  static IAPService get instance => _instance;
  IAPService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Product IDs - these will need to match the products created in App Store Connect and Google Play Console
  static const String monthlyProductId = 'skincare_monthly_9'; // $9/month
  static const String annualProductId = 'skincare_annual_47'; // $47/year (base annual plan)
  static const String payItForwardProductId = 'skincare_pay_it_forward_57'; // $57/year (annual + $10 donation)
  
  // Product configuration
  static const Set<String> productIds = {
    monthlyProductId,
    annualProductId,
    payItForwardProductId,
  };
  
  // Cached products from stores
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  // Purchase stream subscription
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the IAP service and set up purchase stream listener
  Future<bool> initialize() async {
    try {
      // Check if IAP is available on this platform
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('IAP not available on this platform');
        return false;
      }
      
      // Set up purchase stream listener
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (error) {
          debugPrint('Purchase stream error: $error');
          AnalyticsService.capture('purchase_failure', {
            'error': error.toString(),
            'stage': 'stream_error',
          });
        },
      );
      
      // Load products from stores
      await _loadProducts();
      
      _isInitialized = true;
      debugPrint('IAP service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize IAP service: $e');
      AnalyticsService.capture(AnalyticsEvents.iapInitFailure, {
        AnalyticsProperties.error: e.toString(),
      });
      return false;
    }
  }
  
  /// Load product details from app stores
  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        AnalyticsService.capture(AnalyticsEvents.productLoadFailure, {
          AnalyticsProperties.error: response.error.toString(),
        });
        return;
      }
      
      _products = response.productDetails;
      debugPrint('Loaded ${_products.length} products');
      
      // Log any products that weren't found
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
        AnalyticsService.capture(AnalyticsEvents.productsNotFound, {
          'missing_ids': response.notFoundIDs,
        });
      }
    } catch (e) {
      debugPrint('Exception loading products: $e');
      AnalyticsService.capture(AnalyticsEvents.productLoadException, {
        AnalyticsProperties.error: e.toString(),
      });
    }
  }
  
  /// Get product details by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      debugPrint('Product not found: $productId');
      return null;
    }
  }
  
  /// Get monthly subscription product
  ProductDetails? get monthlyProduct => getProduct(monthlyProductId);
  
  /// Get annual subscription product
  ProductDetails? get annualProduct => getProduct(annualProductId);
  
  /// Get pay-it-forward subscription product
  ProductDetails? get payItForwardProduct => getProduct(payItForwardProductId);
  
  /// Start purchase flow for a product
  Future<bool> purchaseProduct(String productId) async {
    try {
      final ProductDetails? product = getProduct(productId);
      if (product == null) {
        debugPrint('Product not found for purchase: $productId');
        AnalyticsService.capture('purchase_failure', {
          'product_id': productId,
          'error': 'product_not_found',
        });
        return false;
      }
      
      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      
      // Start purchase flow
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (success) {
        AnalyticsService.capture('purchase_initiated', {
          'product_id': productId,
          'price': product.price,
        });
      } else {
        AnalyticsService.capture('purchase_failure', {
          'product_id': productId,
          'error': 'failed_to_initiate',
        });
      }
      
      return success;
    } catch (e) {
      debugPrint('Exception during purchase: $e');
      AnalyticsService.capture('purchase_failure', {
        'product_id': productId,
        'error': e.toString(),
      });
      return false;
    }
  }
  
  /// Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      AnalyticsService.capture('restore_purchases_initiated');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Exception during restore purchases: $e');
      AnalyticsService.capture('restore_purchases_failure', {
        'error': e.toString(),
      });
    }
  }
  
  /// Handle purchase updates from the stream
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _handlePurchaseUpdate(purchaseDetails);
    }
  }
  
  /// Handle individual purchase update
  void _handlePurchaseUpdate(PurchaseDetails purchaseDetails) {
    switch (purchaseDetails.status) {
      case PurchaseStatus.pending:
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
        AnalyticsService.capture('purchase_pending', {
          'product_id': purchaseDetails.productID,
        });
        break;
        
      case PurchaseStatus.purchased:
        debugPrint('Purchase successful: ${purchaseDetails.productID}');
        AnalyticsService.capture('purchase_success', {
          'product_id': purchaseDetails.productID,
          'transaction_id': purchaseDetails.purchaseID,
        });
        _handleSuccessfulPurchase(purchaseDetails);
        break;
        
      case PurchaseStatus.error:
        debugPrint('Purchase error: ${purchaseDetails.error}');
        AnalyticsService.capture('purchase_failure', {
          'product_id': purchaseDetails.productID,
          'error': purchaseDetails.error?.message ?? 'unknown_error',
          'error_code': purchaseDetails.error?.code ?? 'unknown_code',
        });
        break;
        
      case PurchaseStatus.restored:
        debugPrint('Purchase restored: ${purchaseDetails.productID}');
        AnalyticsService.capture('purchase_restored', {
          'product_id': purchaseDetails.productID,
        });
        _handleSuccessfulPurchase(purchaseDetails);
        break;
        
      case PurchaseStatus.canceled:
        debugPrint('Purchase canceled: ${purchaseDetails.productID}');
        AnalyticsService.capture('purchase_canceled', {
          'product_id': purchaseDetails.productID,
        });
        break;
    }
    
    // Complete the purchase (required for iOS)
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  /// Handle successful purchase - validate with server
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Import subscription repository at the top of the file
      final subscriptionRepo = SubscriptionRepository.instance;
      
      // Sync purchase with server for validation
      final success = await subscriptionRepo.syncPurchaseWithServer(
        productId: purchaseDetails.productID,
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
        transactionId: purchaseDetails.purchaseID,
      );
      
      if (success) {
        debugPrint('Purchase successfully validated and synced');
      } else {
        debugPrint('Failed to validate purchase with server');
        // Store locally for retry later
        await _storePurchaseToken(purchaseDetails);
      }
      
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
      AnalyticsService.capture('purchase_validation_error', {
        'product_id': purchaseDetails.productID,
        'error': e.toString(),
      });
      
      // Store locally for retry later
      await _storePurchaseToken(purchaseDetails);
    }
  }
  
  /// Store purchase token/receipt for server validation
  Future<void> _storePurchaseToken(PurchaseDetails purchaseDetails) async {
    // TODO: Store in local database or send directly to server
    // This is a placeholder for the actual implementation
    debugPrint('Storing purchase token for: ${purchaseDetails.productID}');
  }
  
  /// Dispose of resources
  void dispose() {
    _purchaseSubscription.cancel();
    _isInitialized = false;
  }
  
  /// Get formatted price for display
  String getFormattedPrice(String productId) {
    final ProductDetails? product = getProduct(productId);
    return product?.price ?? 'Price unavailable';
  }
  
  /// Get localized price for a yearly plan as monthly equivalent
  String getYearlyMonthlyEquivalent(String productId) {
    final ProductDetails? product = getProduct(productId);
    if (product == null) return 'Price unavailable';
    
    try {
      final String priceString = product.price.replaceAll(RegExp(r'[^\d.]'), '');
      final double yearlyPrice = double.parse(priceString.isEmpty ? '0' : priceString);
      if (yearlyPrice == 0) return 'Price unavailable';
      final double monthlyEquivalent = yearlyPrice / 12;
      return '\$${monthlyEquivalent.toStringAsFixed(2)}/month';
    } catch (e) {
      debugPrint('Error calculating monthly equivalent: $e');
      return 'Price unavailable';
    }
  }
  
  /// Get annual plan monthly equivalent
  String getAnnualMonthlyEquivalent() => getYearlyMonthlyEquivalent(annualProductId);
  
  /// Get pay-it-forward plan monthly equivalent
  String getPayItForwardMonthlyEquivalent() => getYearlyMonthlyEquivalent(payItForwardProductId);
}
