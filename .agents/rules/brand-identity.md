---
trigger: always_on
---

# Tara Travel — Brand Identity (Default)

Default, always-on brand reference for Tara Travel. Apply these tokens to all
UI/UX work — components, screens, marketing surfaces — unless the user
explicitly overrides them for a specific task.

Full visual reference (logo variants, swatches, type specimens, component
previews): `0_Brand_identity.html` in the project repo. Open it manually (@
mention) when you need to see things rendered — don't load it every turn.

## Logo

- App icon: rounded-square badge, orange gradient fill, white "T" that resolves
  into a dashed road/path. Master asset: `logo.png` (1024×1024).
- Wordmark: "Tara" (Playfair Display Bold) + "TRAVEL" (Playfair Display Italic,
  uppercase, letter-spaced) stacked underneath, icon to the left.
- Tagline: "Your journey, your way."

## Color palette

| Name        | Hex       | Role       |
| ----------- | --------- | ---------- |
| Coral       | `#D85A30` | Primary    |
| Light coral | `#F0997B` | Secondary  |
| Sand        | `#FAECE7` | Background |
| Sunset      | `#EF9F27` | Accent     |
| Deep earth  | `#2C1A14` | Dark       |
| Warm white  | `#F7F4F0` | Surface    |

## Typography

- **DM Sans** — The primary font, applied as the default body font and UI elements (`font-dm-sans`). Medium for UI labels, Regular for body copy.
- **Playfair Display** — A decorative serif mapped for headings/display text (`font-playfair` / `font-heading`). Bold for headlines, Italic for taglines.
- **Georgia (serif)** — Used as a direct inline fallback in specific display spots, such as the loading splash ("Tara TRAVEL" logo) and the Home page greeting name.

## Components

- **Buttons** — 12px radius. Primary: coral fill / white text. Secondary: sand
  fill / coral-brown text, 1px light-coral border. Ghost: transparent, coral
  text, 1.5px coral border.
- **Badges** — pill-shaped (20px radius), color-coded by status (upcoming =
  coral, planning = sand, draft = amber, completed = green, featured =
  deep-earth bg / light-coral text).
- **Inputs** — 12px radius, 1px `#e8e8e8` border by default, 1.5px coral border
  when focused/active.

## Brand voice

Local-first (built for Filipino & Southeast Asian travelers) · travel together
(group planning, bill splitting, shared itineraries) · worry-free (offline mode,
secure data) · go anywhere (local to international).
