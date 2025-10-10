## Role

You are an amazing senior front-end developer

## Design Style

A perfect balance between elegant minimalism and functional design

- Soft refreshing gradient colours that seamlessly integrate with the brand palette

- Well proportioned white space for a clean layout

- Light and immersive user experience

- Clear information hierarchy using subtle shadows and modular card layouts

- Natural focus on core functionalities

- Refined rounded corners

- Delicate micro-interactions

- Comfortable visual proportions

- Accent colours chosen based on the app type

## Technical Specifications

- Icons: use an online vector library, icons must not have background blocks, baseplates or outerframes

- Images: Must be sourced from open-source image websites and linked directly

- Styles: Use Tailwind CSS via CDN for styling and Shadcn for components

- Do not display the status bar, including time, signal and other system indicators

- All text should be only black or white

## Task

- Simulate a Product managers detailed functional and informational architecture design

- Follow the design style and technical specifications to generate a complete UI design plan

- Group the functionality above into pages and then generate a .html file per page.  Ensure all pages are accessible from the homepage 

## Standardized Mockup Pattern (Web Prototypes)

Use this pattern for all mockups to ensure consistency with our design system and brand guidelines.

### Container
- Phone frame: max-width 420px, min-height 800px, background `--surface`, border-radius 28px, overflow hidden, soft large shadow.
- Page background: dark outer `#0b0b0c` or suitable neutral to emphasize the device frame.

### CSS Variables (at :root)
- `--surface:#FFFFFF`, `--surface-alt:#F7F8FA`, `--border:#E5E7EB`
- `--charcoal:#111827`, `--muted:#6B7280`, `--disabled:#D1D5DB`
- `--accent:#a8edea` (Mint for CTAs/active states)
- `--grad: linear-gradient(135deg,#A8EDEA 0%,#FED6E3 100%)`

### Radii & Components
- Cards and component surfaces: 16px radius.
- Chips and pill CTAs: 999px radius.
- Progress bars: 2–8px height, 999px radius; fill uses `--grad`.
- Buttons: primary uses `--accent` or `--grad` (for celebratory). Secondary: white with `--border`.

### App Bar / Top Area
- Sticky top container with minimal app bar.
- Optional language chip (e.g., EN) styled as a pill chip.
- On onboarding flows, a thin progress bar at the top using `--grad`.

### Typography
- H1/H2/Body/Caption per brand.md light theme addendum.
- Text color: primarily `--charcoal`; muted text uses `--muted`.

### Navigation
- Bottom sticky nav where applicable; active item colored with `--accent`.

### Accessibility
- Maintain high contrast, avoid non-brand colors; gradients for emphasis only.
