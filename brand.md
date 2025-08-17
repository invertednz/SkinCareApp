# SkinCare App Brand Guidelines

## Brand Colors

### Primary Gradient
- **Primary Gradient**: `linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)`
  - Start: `#a8edea` (Light Aqua/Mint)
  - End: `#fed6e3` (Light Pink)

### Secondary Gradient  
- **Secondary Gradient**: `linear-gradient(135deg, #e0c3fc 0%, #8ec5fc 100%)`
  - Start: `#e0c3fc` (Light Purple)
  - End: `#8ec5fc` (Light Blue)

### Accent Color
- **Accent Color**: `#ff7eb3` (Pink)

### Additional Brand Colors
- **Purple**: `#6A11CB` (Deep Purple)
- **Blue**: `#2575FC` (Bright Blue)

## Flutter Color Implementation

### Primary Colors
```dart
// Primary gradient colors
Color(0xFFA8EDEA) // Light Aqua/Mint
Color(0xFFFED6E3) // Light Pink

// Secondary gradient colors  
Color(0xFFE0C3FC) // Light Purple
Color(0xFF8EC5FC) // Light Blue

// Accent color
Color(0xFFFF7EB3) // Pink

// Deep brand colors
Color(0xFF6A11CB) // Deep Purple
Color(0xFF2575FC) // Bright Blue
```

### Gradient Definitions
```dart
// Primary gradient (used for main headers, primary buttons)
LinearGradient(
  colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Secondary gradient (used for secondary elements, cards)
LinearGradient(
  colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Deep gradient (used for app bars, primary UI elements)
LinearGradient(
  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

## Usage Guidelines

### Headers & App Bars
- Use the **Deep Gradient** (`#6A11CB` to `#2575FC`) for app bars and main headers
- White text on gradient backgrounds

### Primary Actions
- Use **Primary Gradient** for main call-to-action buttons
- Use **Accent Color** (`#ff7eb3`) for highlights and active states

### Secondary Elements
- Use **Secondary Gradient** for cards, secondary buttons, and decorative elements
- Use light purple/blue tones for supporting UI elements

### Navigation
- **Accent Color** (`#ff7eb3`) for active navigation items
- Gray tones for inactive navigation items

## Colors to Avoid
- **Green hues**: The brand does not use green colors
- **Red**: Avoid red except for error states
- **Yellow/Orange**: Not part of the brand palette

## Accessibility
- Ensure sufficient contrast ratios when using gradients with text
- Use white text on dark gradients
- Use dark text on light backgrounds
- Test color combinations for accessibility compliance
