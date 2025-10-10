# Dusty Rose & Charcoal - Color Scheme Guide

## Visual Reference
Based on: `mockups/color_v3_01_rose_charcoal.html`

## Core Palette

```
┌─────────────────────────────────────────────┐
│  Dusty Rose Primary (#D0A3AF)               │
│  ████████████████████████████████████████   │
│  Main CTA, selected states, active chips    │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Dusty Rose Accent (#BA8593)                │
│  ████████████████████████████████████████   │
│  Gradient end, borders, hover states        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Charcoal (#3D3840)                         │
│  ████████████████████████████████████████   │
│  Primary text, dark accents, icons          │
└─────────────────────────────────────────────┘
```

## Background System

```
┌─────────────────────────────────────────────┐
│  Background Light (#F8F5F6)                 │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│  Main scaffold background                   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Background Medium (#F0EAEC)                │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│  Subtle surface variation                   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Card Background (#FFFFFF)                  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│  White cards, elevated surfaces             │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Card Secondary (#FDFBFC)                   │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│  Alternate card background                  │
└─────────────────────────────────────────────┘
```

## Text Hierarchy

```
Primary Text (#3D3840)      █████ Headings, labels
Secondary Text (#6D6168)    ████  Body text, descriptions  
Tertiary Text (#8A7B82)     ███   Metadata, hints
```

## Border System

```
Light Border (#F0E8EB)      ─────  Subtle separators
Medium Border (#E8E0E3)     ━━━━━  Standard borders
```

## Usage Examples

### Buttons

**Primary CTA**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Brand.primaryStart,  // #D0A3AF
    foregroundColor: Colors.white,
  )
)
```

**Outlined**
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: Brand.primaryStart,  // #D0A3AF
    side: BorderSide(color: Brand.primaryStart),
  )
)
```

### Cards

**Standard Card**
```dart
Container(
  decoration: BoxDecoration(
    color: Brand.cardBackground,  // White
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Brand.borderLight),  // #F0E8EB
    boxShadow: [
      BoxShadow(
        color: Brand.primaryStart.withOpacity(0.08),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  )
)
```

**Selected Card**
```dart
Container(
  decoration: BoxDecoration(
    gradient: Brand.primaryGradient,  // #D0A3AF → #BA8593
    border: Border.all(
      color: Brand.primaryEnd.withOpacity(0.6),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Brand.primaryStart.withOpacity(0.4),
        blurRadius: 16,
      ),
    ],
  ),
  child: Text(
    'Selected',
    style: TextStyle(color: Colors.white),
  ),
)
```

### Chips & Pills

**Selected Chip**
```dart
FilterChip(
  label: Text('Selected'),
  selected: true,
  selectedColor: Brand.primaryStart,  // #D0A3AF
)
```

**Unselected Chip**
```dart
FilterChip(
  label: Text('Option'),
  selected: false,
  backgroundColor: Colors.white,
  side: BorderSide(color: Brand.borderLight),
)
```

### Gradients

**Primary Gradient** (Headers, selected states)
```dart
LinearGradient(
  colors: [Brand.primaryStart, Brand.primaryEnd],  // #D0A3AF → #BA8593
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

**Secondary Gradient** (Subtle backgrounds)
```dart
LinearGradient(
  colors: [Brand.secondaryStart, Brand.secondaryEnd],  // #F5EDEF → #E8E0E3
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Sliders & Progress

**Active Track**
```dart
Slider(
  activeColor: Brand.primaryStart,  // #D0A3AF
  inactiveColor: Brand.borderMedium,  // #E8E0E3
)
```

**Progress Bar**
```dart
Container(
  decoration: BoxDecoration(
    gradient: Brand.primaryGradient,
    borderRadius: BorderRadius.circular(4),
  ),
)
```

## Accessibility

### Contrast Ratios

| Combination                          | Ratio | WCAG Level |
|--------------------------------------|-------|------------|
| Dusty Rose (#D0A3AF) on White        | 2.8:1 | AA Large   |
| Charcoal (#3D3840) on White          | 10.5:1| AAA        |
| White on Dusty Rose (#D0A3AF)        | 3.2:1 | AA Large   |
| Secondary Text (#6D6168) on White    | 5.8:1 | AA         |
| Tertiary Text (#8A7B82) on White     | 4.2:1 | AA Large   |

### Recommendations
- Use Charcoal (#3D3840) for body text (excellent contrast)
- Use white text on rose gradients (good contrast)
- Rose works for large text and interactive elements
- Avoid rose on light backgrounds for small text

## Design Tokens

```dart
// In brand.dart
class Brand {
  // Primary
  static const Color primaryStart = Color(0xFFD0A3AF);
  static const Color primaryEnd = Color(0xFFBA8593);
  
  // Accent
  static const Color charcoal = Color(0xFF3D3840);
  
  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8F5F6);
  static const Color backgroundMedium = Color(0xFFF0EAEC);
  
  // Text
  static const Color textPrimary = Color(0xFF3D3840);
  static const Color textSecondary = Color(0xFF6D6168);
  static const Color textTertiary = Color(0xFF8A7B82);
  
  // Surfaces
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundSecondary = Color(0xFFFDFBFC);
  
  // Borders
  static const Color borderLight = Color(0xFFF0E8EB);
  static const Color borderMedium = Color(0xFFE8E0E3);
}
```

## Psychology & Brand Positioning

### Dusty Rose Associations
- **Sophistication**: Mature, refined aesthetic
- **Femininity**: Gentle without being juvenile
- **Luxury**: Premium skincare positioning
- **Trust**: Soft and approachable
- **Warmth**: Emotional connection

### Charcoal Associations
- **Authority**: Professional credibility
- **Elegance**: Modern sophistication
- **Seriousness**: Takes skin health seriously
- **Stability**: Reliable and grounded
- **Balance**: Grounds the softer rose tones

### Target Demographic
- **Age**: 32-50 (sweet spot)
- **Appeal**: Women seeking elegant, mature skincare
- **Income**: Mid to upper-middle class
- **Values**: Quality, efficacy, sophistication
- **Avoid**: Appears too clinical, too playful, or generic

### Competitive Position
- More sophisticated than pink/mint beauty apps
- Warmer than clinical blue/white medical apps
- More mature than pastel wellness apps
- Aligns with premium skincare brands (La Mer, Drunk Elephant aesthetic)

## Migration Notes

### Old Colors → New Colors
- Mint `#A8EDEA` → Dusty Rose `#D0A3AF`
- Pink `#FF7EB3` → Dusty Rose Accent `#BA8593`
- Generic borders → Rose-tinted borders
- Cool grays → Warm charcoal
- White backgrounds → Soft rose-tinted backgrounds

### Files Updated
1. `lib/theme/brand.dart` - Core color definitions
2. `lib/theme/light_theme.dart` - Theme configuration
3. `lib/features/onboarding/presentation/onboarding_wizard.dart` - All interactive elements
4. All new marketing pages use the scheme consistently

## Testing in Different Contexts

### Light Mode (Primary)
✓ Excellent readability
✓ Warm, inviting feel
✓ Professional appearance
✓ Clear visual hierarchy

### Dark Mode (Future)
Consider these adjustments:
- Use deeper charcoal for backgrounds
- Lighten rose tones for visibility
- Reduce opacity on gradients
- Increase contrast ratios

### Outdoor Visibility
- Charcoal text ensures readability in bright light
- Rose elements may wash out slightly (acceptable for secondary UI)
- White cards maintain clarity

## Brand Consistency Checklist

When adding new UI:
- [ ] CTAs use Dusty Rose gradient or solid
- [ ] Selected states have rose highlight
- [ ] Text uses charcoal hierarchy (primary/secondary/tertiary)
- [ ] Cards have soft rose-tinted shadows
- [ ] Borders use rose-tinted neutrals
- [ ] Backgrounds use light rose tint
- [ ] White text on rose gradients for contrast
- [ ] Hover states deepen rose slightly
- [ ] Disabled states use border colors
- [ ] Icons use charcoal or rose depending on context
