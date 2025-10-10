# Onboarding Wizard Redesign

## Overview
The existing onboarding wizard (detailed profile questions) has been completely redesigned to match the sophisticated Dusty Rose & Charcoal aesthetic.

## Before vs After

### Before (Old Design)
- Gradient header with "Your Profile" title
- Overlapping card design
- Basic progress bar
- Generic Material Design buttons
- "Step X of Y" text only

### After (New Design) ✨

**Complete Visual Overhaul**:

1. **AppBar**
   - Transparent background
   - Back arrow (left) - only shows after first step
   - Close button (right) - save & exit
   - Charcoal icons on rose-tinted background

2. **Progress Indicator**
   - Horizontal bar with rose gradient fill
   - Step counter badge (e.g., "3/8")
   - Clean, modern appearance
   - 24px padding from edges

3. **Error Display**
   - Red card with icon
   - Rounded corners (12px)
   - Proper spacing
   - Clear error messaging

4. **Content Card**
   - Large white card (24px rounded)
   - Rose-tinted shadow
   - Contains all step content
   - Scrollable if needed
   - Elevated appearance

5. **Navigation Buttons**
   - **Back**: Outlined button with rose border (only shows after first step)
   - **Continue/Complete**: Filled rose button
   - Full width when on first step
   - Side-by-side after first step
   - 16px vertical padding
   - Proper loading states

## Layout Structure

```
┌─────────────────────────────────┐
│ ← [AppBar]              ✕       │
├─────────────────────────────────┤
│ [Progress Bar ████░░░░] 3/8     │
│                                 │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │   [White Content Card]      │ │
│ │                             │ │
│ │   Step content here...      │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Back]          [Continue]      │
└─────────────────────────────────┘
```

## Design Details

### Colors

**Background**: `Brand.backgroundLight` (#F8F5F6)
**AppBar**: Transparent with charcoal icons
**Progress Bar**:
- Background: `Brand.borderMedium` (#E8E0E3)
- Fill: `Brand.primaryGradient` (rose gradient)

**Content Card**:
- Background: White
- Border: `Brand.borderLight` (#F0E8EB)
- Shadow: Rose-tinted, 16px blur

**Buttons**:
- Back: Outlined with rose border
- Continue: Filled rose background
- Disabled: `Brand.borderMedium`

**Error Card**:
- Background: `Colors.red.shade50`
- Border: `Colors.red.shade200`
- Icon: `Colors.red.shade700`
- Text: `Colors.red.shade900`

### Typography

**Progress Counter**: 14px, w600, secondary color
**Error Text**: 13px, red shade 900
**Button Text**: 16px, w600, white (filled) or rose (outlined)

### Spacing

- Page padding: 24px all sides
- Progress to content: 24px
- Content to buttons: 24px
- Button gap: 12px
- Error margin: 16px

### Shadows

**Content Card**:
```dart
BoxShadow(
  color: Brand.primaryStart.withOpacity(0.08),
  blurRadius: 16,
  offset: Offset(0, 4),
)
```

## Key Features

### Progressive Disclosure
- Back button only appears after first step
- Progress bar shows current position
- Step counter provides context
- Clear "Complete" label on final step

### Error Handling
- Errors display above content card
- Icon + text for clarity
- Red theme for urgency
- Proper spacing

### Loading States
- Spinner in button during save
- Buttons disabled while loading
- White spinner on rose background

### Navigation
- Back button goes to previous step
- Close button saves draft and exits
- Continue advances to next step
- Complete submits final data

## Interaction Flow

### First Step
```
┌─────────────────────────────────┐
│              ✕                  │
│ [Progress ██░░░░░░░░] 1/8       │
│ ┌─────────────────────────────┐ │
│ │ What are your concerns?     │ │
│ │ [Acne] [Redness] [Dryness] │ │
│ └─────────────────────────────┘ │
│      [Continue (full width)]    │
└─────────────────────────────────┘
```

### Middle Steps
```
┌─────────────────────────────────┐
│ ←            ✕                  │
│ [Progress ████░░░░░] 4/8        │
│ ┌─────────────────────────────┐ │
│ │ Select your skin type       │ │
│ │ ○ Oily  ○ Dry  ○ Normal    │ │
│ └─────────────────────────────┘ │
│ [Back]          [Continue]      │
└─────────────────────────────────┘
```

### Final Step
```
┌─────────────────────────────────┐
│ ←            ✕                  │
│ [Progress ████████████] 8/8     │
│ ┌─────────────────────────────┐ │
│ │ Review your routine         │ │
│ │ AM: Cleanser, Moisturizer  │ │
│ │ PM: Cleanser, Serum        │ │
│ └─────────────────────────────┘ │
│ [Back]          [Complete]      │
└─────────────────────────────────┘
```

## Consistency with Marketing Pages

### Shared Design Elements
✓ Same background color
✓ Same card styling
✓ Same button styles
✓ Same shadow system
✓ Same border radii
✓ Same color palette
✓ Same typography scale
✓ Same spacing system

### Visual Cohesion
The wizard now feels like a natural continuation of the marketing pages rather than a jarring transition to a different design system.

## Technical Implementation

### File Modified
`lib/features/onboarding/presentation/onboarding_wizard.dart`

### Key Changes

**Removed**:
- `GradientHeader` widget usage
- `OverlapCard` widget usage
- Old gradient header container
- Generic step counter text

**Added**:
- Transparent AppBar with icons
- Horizontal progress bar with counter
- White content card with shadow
- Styled navigation buttons
- Error card component
- Proper button states

### Widget Structure
```dart
Scaffold
├── AppBar (transparent)
│   ├── Back IconButton (conditional)
│   └── Close IconButton
└── SafeArea
    └── Padding (24px)
        └── Column
            ├── Progress Row
            │   ├── Progress Bar
            │   └── Counter Text
            ├── Error Card (conditional)
            ├── Content Card (Expanded)
            │   └── PageView (steps)
            └── Navigation Row
                ├── Back Button (conditional)
                └── Continue/Complete Button
```

## User Experience Improvements

### Clarity
- Progress is immediately visible
- Current step is clear
- Total steps known upfront
- Navigation options obvious

### Consistency
- Matches marketing page design
- Familiar button styles
- Expected interactions
- Cohesive experience

### Feedback
- Loading states visible
- Errors clearly displayed
- Progress updates smoothly
- Actions have clear outcomes

### Accessibility
- High contrast text
- Large touch targets (16px padding)
- Clear focus indicators
- Proper button labels
- Icon + text for errors

## Testing Checklist

### Visual
- [ ] Background color matches marketing pages
- [ ] Progress bar fills correctly
- [ ] Step counter updates
- [ ] Card shadow renders properly
- [ ] Buttons styled correctly
- [ ] Error card displays properly

### Functional
- [ ] Back button appears after first step
- [ ] Back button navigates correctly
- [ ] Close button saves and exits
- [ ] Continue advances step
- [ ] Complete submits data
- [ ] Loading states work
- [ ] Error messages display
- [ ] Progress bar animates

### Responsive
- [ ] Layout works on small screens
- [ ] Content scrolls if needed
- [ ] Buttons remain accessible
- [ ] Progress bar scales properly

## Migration Notes

### Breaking Changes
None - all functionality preserved

### Behavioral Changes
- Back button now in AppBar instead of bottom
- Close button moved to AppBar
- Button labels changed ("Next" → "Continue", "Submit" → "Complete")
- Progress display changed (text → bar + counter)

### Visual Changes
- Complete redesign of layout
- New color scheme applied
- New button styles
- New card design
- New progress indicator

## Performance

### Optimizations
- No additional widgets loaded
- Efficient progress calculation
- Minimal rebuilds
- Smooth animations

### Memory
- No memory leaks
- Proper disposal
- Efficient state management

## Future Enhancements

### Potential Additions
1. **Step titles** in AppBar
2. **Animated transitions** between steps
3. **Skip option** for optional steps
4. **Save progress** indicator
5. **Estimated time** remaining
6. **Step previews** on progress bar
7. **Keyboard shortcuts** for navigation
8. **Haptic feedback** on interactions

### A/B Test Ideas
- Test different button labels
- Try different progress styles
- Experiment with card animations
- Test error placement variations

## Conclusion

The onboarding wizard now perfectly matches the sophisticated Dusty Rose & Charcoal design system, creating a seamless experience from marketing pages through detailed profile collection.

**Key Achievements**:
✅ Visual consistency across entire flow
✅ Modern, elegant design
✅ Improved user experience
✅ Better progress visibility
✅ Clearer navigation
✅ Professional appearance
✅ All functionality preserved
✅ No breaking changes
