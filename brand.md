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

### Accent Colors
- **Accent Pink**: `#ff7eb3` (Pink) — decorative highlights only; avoid for primary CTAs/active states.

### Interactive Accent
- **Mint**: `#a8edea` — use for primary CTAs, selected states, and active UI (e.g., tabs, nav).

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
// Primary gradient (used for main headers, celebratory CTAs, progress accents)
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
- Use a light, gender-neutral primary CTA: solid **Mint** `#a8edea` with white text.
- Optional: for celebratory or recommended actions, use the **Primary Gradient** fill.
- Secondary CTA: white background with `#E5E7EB` border and charcoal text; optional mint icon/text accent.
- Disabled state: background `#E5E7EB`, text `#9CA3AF`.
- Keep **Accent Pink** (`#ff7eb3`) for decorative highlights only. Use **Mint** (`#a8edea`) for chips, toggles, progress fills, and other active states.

### Secondary Elements
- Use **Secondary Gradient** for cards, secondary buttons, and decorative elements
- Use light purple/blue tones for supporting UI elements

### Navigation
- Use **Mint** (`#a8edea`) for active navigation items
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

---

## Light Theme Addendum (inspired by viral onboarding flow)

This addendum introduces neutral surfaces and component specs while keeping our light color scheme and existing gradients.

### Neutral Palette
- **Surface / Page**: `#FFFFFF`
- **Surface Alt**: `#F7F8FA`
- **Border / Divider**: `#E5E7EB`
- **Shadow**: `rgba(0,0,0,0.08)` (soft, wide)
- **Text Primary (Charcoal)**: `#111827`
- **Text Secondary (Muted)**: `#6B7280`
- **Disabled**: `#D1D5DB`

### Typography
- **H1**: 32/36, weight 700 (used for onboarding questions)
- **H2**: 24/30, weight 700
- **Body**: 16/24, weight 400
- **Caption**: 14/20, weight 400 (muted)
Font family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif.

### Spacing & Radius
- Base spacing: 4px grid (8, 12, 16, 20, 24)
- Card padding: 16–20px
- Button height: 52–56px
- **Radius**: 16px for cards, 999px for pill CTAs and chips

### Progress Indicator (Onboarding)
- Thin top bar (2–4px) with background `#EEF2F4` and fill using the **Primary Gradient**.
- Minimal app bar: back chevron on left, optional language chip on right.

### Components
- **Choice Pills (Full-width)**
  - Unselected: white surface, border `#E5E7EB`, text `#111827`.
  - Selected: **Mint** `#a8edea` background (or Primary Gradient), white text.
  - Height: 56px, radius: 16px.

- **Radio Cards with Subtitle**
  - Card surface white with soft shadow, 16px radius.
  - Leading dot/icon, title (16/600) + subtitle muted (14/400).

- **Slider (Goal Speed / Intensity)**
  - Track: active segment **Mint** `#a8edea`; rest `#E5E7EB`. Handle border `#a8edea`.
  - Optional helper icons above the track; value label centered.

- **Sticky Bottom CTA**
  - Rounded pill spanning safe area.
  - Primary state **Mint** `#a8edea`; disabled grey; alternative gradient for “Recommended”.

- **Success / Completion**
  - Large "All done!" / "Thank you" headline, muted subtitle.
  - Micro-confetti decoration; CTA continues the flow.

### Data Cards & Analytics (In-app)
- White cards on `#F7F8FA` background.
- Tag-style metric chips; soft progress bars using gradients.
- Tabs use pill chips; active chip charcoal text on white with border, or accent gradient underline.

### Do’s
- Keep backgrounds light and airy.
- Use our gradients for progress, emphasis, and delightful moments.
- Keep text contrast high with charcoal on white.

### Don’ts
- Do not introduce green as a brand color (only for system states if required).
- Avoid heavy drop shadows; keep elevation soft.
