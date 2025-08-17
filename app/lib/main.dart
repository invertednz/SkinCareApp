import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/env.dart';
import 'services/analytics_service.dart';
import 'services/error_handler.dart';
import 'services/notifications_service.dart';
import 'widgets/error_widget.dart';
import 'theme/light_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/session.dart';
import 'features/profile/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handling
  ErrorHandler.initialize();
  
  // Set custom error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorWidget(
      error: details.exception,
      title: 'App Error',
      showDetails: true,
    );
  };
  
  // Wrap app initialization in try/catch boundary
  try {
    await Env.load();
    final url = Env.supabaseUrl;
    final key = Env.supabaseAnonKey;
    if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: key);
      // Ensure auth listener is attached now that Supabase is initialized
      SessionService.instance.rebind();
      // Bind profile service to session changes and fetch profile
      ProfileService.instance.rebind(SessionService.instance);
    }
    await AnalyticsService.init(apiKey: Env.posthogKey, host: Env.posthogHost);
    
    // Initialize notifications service
    await NotificationsService().initialize();
    
    runApp(MyApp(router: AppRouter.create()));
  } catch (error, stackTrace) {
    // Log initialization error and show fallback app
    debugPrint('App initialization failed: $error');
    debugPrint('Stack trace: $stackTrace');
    
    // Run a minimal fallback app
    runApp(
      MaterialApp(
        title: 'Skincare App',
        theme: LightTheme.theme,
        home: Scaffold(
          body: AppErrorWidget(
            error: error,
            title: 'Failed to Start App',
            showDetails: true,
            onRetry: () {
              // Restart the app by calling main again
              main();
            },
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});
  final RouterConfig<Object> router;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Skincare App',
      theme: LightTheme.theme,
      routerConfig: router,
    );
  }
}

// Placeholder demo widgets removed. Real screens will be added per tasks.
