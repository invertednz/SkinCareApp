# UI Cleanup and Branding Checklist

## Brand Standards
- Headers/app bars: deep-gradient with white text
- Active nav item: Mint (#a8edea)
- Cards: white backgrounds, brand gradients only for small elements (icon circles)
- Photo upload: accent hover styles
- Typography/spacing: consistent and accessible
- Progress bars/toggles: brand styles

## Pages
- [x] index.html
  - [x] Header deep-gradient
  - [x] Cards white bg; gradients only in icon circles
  - [x] Remove non-brand gradients
  - [x] Typography/spacing
- [x] chat.html
  - [x] Header deep-gradient
  - [x] Photo upload button accent color border/text
  - [x] Bot/user bubbles use brand styles
- [x] insights.html
  - [x] Header deep-gradient
  - [x] Replace non-brand badges with brand gradients
  - [x] Cards white bg; progress bars brand classes
  - [x] Accent color replaces green/yellow trends
- [x] routine.html
  - [x] Header deep-gradient
  - [x] Header icon accent
  - [x] Cards white bg; small icon circles use brand gradients
- [x] diet.html
  - [x] Header deep-gradient
  - [x] Header icon accent
  - [x] Completed water intake section; bottom nav; date script
  - [x] Cards white bg; small icon circles use brand gradients
- [x] supplements.html
  - [x] Header deep-gradient; icon accent
  - [x] Fix date script; close tags
  - [x] Cards white bg; small icon circles use brand gradients
- [x] symptoms.html
  - [x] Header deep-gradient; icon accent
  - [x] Fix missing closing tag; add bottom nav; date script
  - [x] Cards white bg; small icon circles use brand gradients
- [x] skin-health.html
  - [x] Header deep-gradient; icon accent
  - [x] Weekly progress and controls conform to brand styles

## Relevant Files
- Edited: [index.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/index.html:0:0-0:0), [chat.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/chat.html:0:0-0:0), [insights.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/insights.html:0:0-0:0), [routine.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/routine.html:0:0-0:0), [diet.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/diet.html:0:0-0:0), [supplements.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/supplements.html:0:0-0:0), [symptoms.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/symptoms.html:0:0-0:0), [skin-health.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/skin-health.html:0:0-0:0)
- Reference: [styles.css](cci:7://file:///c:/Trae%20Apps/SkinCareApp/styles.css:0:0-0:0), [brand.md](cci:7://file:///c:/Trae%20Apps/SkinCareApp/brand.md:0:0-0:0)

## Notes
- Gradients allowed on small accent elements (icon circles), not on whole cards.
- Primary CTAs use Mint (#a8edea); use Primary Gradient for celebratory/recommended actions.

## Changelog
- Completed brand header normalization and icon accenting across all pages; verified deep-gradient headers are consistent across all pages.
- Removed non-brand gradients from cards; standardized spacing/typography.
- Fixed minor markup/JS issues in [supplements.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/supplements.html:0:0-0:0), [symptoms.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/symptoms.html:0:0-0:0), [diet.html](cci:7://file:///c:/Trae%20Apps/SkinCareApp/diet.html:0:0-0:0); increased card/component border radius to 16px and normalized CSS variables in [styles.css](cci:7://file:///c:/Trae%20Apps/SkinCareApp/styles.css:0:0-0:0) (primary/secondary gradients, deep-gradient, accent Mint #a8edea).
- Switched interactive/CTA color to Mint (#a8edea); updated brand.md, styles.css, and onboarding/home mockups.