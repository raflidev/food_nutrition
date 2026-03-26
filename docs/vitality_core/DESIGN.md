```markdown
# Design System Strategy: The Living Lab

## 1. Overview & Creative North Star
The North Star for this design system is **"The Living Lab."** 

In the saturated world of health and nutrition, we move away from the "clinical" or the "utilitarian." Instead, we embrace a high-end editorial aesthetic that feels both scientifically precise and organically alive. We achieve this by rejecting the rigid, boxed-in layouts of standard apps in favor of **Organic Asymmetry** and **Tonal Depth**. 

The interface should feel like a premium wellness magazine: breathing room is a functional requirement, not a luxury. By layering soft whites over vibrant, energetic greens, we create a sense of momentum and growth. We don't just display data; we curate a lifestyle.

---

## 2. Colors & Surface Philosophy
Color is not used for decoration; it is used to define space without the need for structural lines.

### The Palette
- **Primary Focus:** Use `primary` (#006a28) for high-impact brand moments and `primary_container` (#5cfd80) for energetic backgrounds that demand attention.
- **The Neutrals:** `surface` (#f5f7f5) serves as our "Soft White" canvas. `on_surface` (#2c2f2e) is our "Charcoal" for maximum readability.

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning. We define boundaries through background color shifts. To separate a section, transition from `surface` to `surface_container_low`. This creates a sophisticated, seamless flow that feels integrated rather than "boxed."

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
- Use `surface_container_lowest` (#ffffff) for the most elevated "top-layer" cards.
- Place these on a `surface_container` (#e6e9e7) or `surface` (#f5f7f5) base. 
- This "Tone-on-Tone" nesting replaces the need for dividers and creates a tactile, high-end feel.

### The "Glass & Gradient" Rule
To inject "soul" into the digital experience:
- **Glassmorphism:** For floating headers or navigation bars, use `surface` at 80% opacity with a `backdrop-blur` of 20px. 
- **Signature Gradients:** For Hero CTAs and Progress Rings, use a linear gradient from `primary` (#006a28) to `primary_fixed_dim` (#4bee74) at a 135-degree angle. This mimics the natural variegation found in plant life.

---

## 3. Typography
We use a dual-font system to balance authoritative clear-headedness with modern friendliness.

- **Display & Headlines (Manrope):** Chosen for its geometric precision. Use `display-lg` and `headline-lg` for daily goals or "Big Wins." The wide apertures of Manrope convey openness and energy.
- **Body & Labels (Plus Jakarta Sans):** A modern sans-serif with a slightly "bubbly" personality. This keeps the technical nutrition data (macros, calories) feeling approachable rather than intimidating.

**Editorial Hierarchy:** Use `display-md` for numerical data (e.g., "1,200 kcal") paired immediately with `label-md` in `on_surface_variant` (#595c5b) for the descriptor. This high-contrast scale mimics premium fitness journals.

---

## 4. Elevation & Depth
We eschew "Material" shadows in favor of **Atmospheric Depth.**

- **The Layering Principle:** Use the Spacing Scale (specifically `spacing-4` to `spacing-8`) to create "Gaps" of light. A `surface_container_lowest` card on a `surface_dim` background provides enough contrast to imply depth without a single shadow.
- **Ambient Shadows:** Where a floating effect is required (e.g., a "Log Meal" FAB), use a shadow with a blur radius of `32px`, an Y-offset of `8px`, and an opacity of 6%. The color must be a tinted version of `on_surface` (#2c2f2e) to ensure the shadow feels like a part of the environment, not a grey smudge.
- **The "Ghost Border" Fallback:** If a border is required for accessibility, use `outline_variant` at 15% opacity. Never use 100% opaque outlines.
- **Curvature:** Utilize the `xl` (1.5rem) roundedness for large containers and `full` (9999px) for buttons. This high-radius look feels friendly and ergonomic.

---

## 5. Components

### Buttons
- **Primary:** `primary` background with `on_primary` text. Use `full` rounding. Ensure a subtle gradient from `primary` to `primary_dim` to give the button "weight."
- **Tertiary/Ghost:** No background. Use `primary` text. These should be used for secondary actions like "View Details" to keep the layout uncluttered.

### Cards (The "Living" Card)
- **Style:** Forbid divider lines. Use `spacing-5` (1.25rem) padding. 
- **Structure:** A `surface_container_lowest` card with an `xl` corner radius. 
- **Interaction:** On tap, the card should slightly scale (0.98) rather than changing color, maintaining the "paper-like" integrity.

### Input Fields
- **Style:** "Soft Inputs." Use `surface_container_high` as the fill color. No border. On focus, transition the background to `surface_container_lowest` and add a `2px` "Ghost Border" using `primary`.

### Progressive Progress Bars
- Use `surface_container_highest` for the track and the `primary` gradient for the fill. The bar should have `full` rounded caps to maintain the "energetic" aesthetic.

### Additional Suggested Component: "The Health Score Orbit"
An asymmetrical, circular data visualization component using `tertiary` (#00656f) and `primary` rings, layered with glassmorphism to show overlapping nutrition goals.

---

## 6. Do’s and Don’ts

### Do:
- **Do** use whitespace as a separator. If in doubt, add more padding.
- **Do** use `primary_container` for "Positive State" backgrounds (e.g., "Goal Reached").
- **Do** use `manrope` for any number larger than 24pt to emphasize the "Lab" precision.

### Don't:
- **Don't** use black (#000000). Always use `on_surface` (Charcoal) for text to maintain a premium, softer look.
- **Don't** use 1px dividers to separate list items. Use a 1px vertical gap of the background color or a subtle `surface` shift.
- **Don't** use "Alert Red" for everything. Use `error` (#b02500) sparingly, and consider `secondary` (#515d64) for neutral "empty" or "warning" states to keep the vibe energetic and positive.
- **Don't** clutter the screen. If a piece of information isn't vital to the "Living Lab" experience, hide it behind a "more info" tertiary link.```