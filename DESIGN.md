# Design Brief

## Direction

Frėjos žurnalas — a soft, warm baby-tracking journal (Lithuanian UI) where daily care logs live in calm, pastel cards.

## Tone

Gentle, nurturing minimalism — baby-friendly pastels with a warm peach/pink warmth; calm and trustworthy, never clinical.

## Differentiation

A cozy "family journal" warmth: soft pink/purple primary, peach secondary, and rounded friendly cards that make daily logging feel tender, not like data entry.

## Color Palette

| Token      | OKLCH (light) | Role                                  |
| ---------- | ------------- | ------------------------------------- |
| background | 0.98 0.02 40  | Warm off-white canvas                 |
| foreground | 0.2 0.02 20   | Primary text                          |
| card       | 1 0 0         | Elevated surfaces                     |
| primary    | 0.65 0.18 330 | Soft pink/purple — primary actions    |
| secondary  | 0.92 0.04 50  | Warm peach — secondary surfaces       |
| accent     | 0.88 0.08 280 | Pastel lavender highlight             |
| muted      | 0.95 0.02 40  | Subtle fill / borders                 |
| success    | 0.58 0.16 155 | Export/import success feedback        |
| warning    | 0.78 0.14 80  | Restore confirmation / attention      |
| destructive| 0.6 0.22 25   | Error / rejected import               |

Dark mode: desaturated charcoal neutrals with the same pink/purple primary and tuned success/warning.

## Typography

- Display: system sans (no bundled font — existing app uses system stack; kept for consistency)
- Body: system sans — clean, readable for log entries
- Scale: h1 semibold 2xl, h2 semibold xl, label text-sm font-medium, body text-base

## Elevation & Depth

Card-based surface hierarchy: `bg-card` on `bg-background` with subtle `border-border`; shadows kept soft and minimal to preserve the airy pastel feel.

## Structural Zones

| Zone    | Background  | Border   | Notes                              |
| ------- | ----------- | -------- | ---------------------------------- |
| Header  | bg-card     | border-b | Sticky app header with logo/theme  |
| Content | bg-background | —      | Alternating bg-muted/30 sections   |
| Footer  | bg-muted/40 | border-t | App footer                         |

## Backup / Restore Screen

- Dedicated backup page (Lithuanian) with two distinct action cards on `bg-card` with `border-border`.
- **Export**: primary (pink/purple) button "Eksportuoti atsarginę kopiją" → one-tap JSON download; success uses `success` token with a check confirmation.
- **Import**: secondary/outline action "Importuoti atsarginę kopiją" → file picker, then a `warning`-tinted confirmation dialog (import writes data), then `success` summary (restored vs skipped) or `destructive` rejection for invalid files.
- Uses existing card/button/badge patterns; no new layout primitives.

## Spacing & Rhythm

Generous card padding (p-6) with consistent section gaps (gap-6); micro-spacing 2/4px for labels and badges.

## Component Patterns

- Buttons: rounded-lg, primary pink/purple fill for primary actions, outline/secondary for secondary; hover darkens slightly.
- Cards: rounded-lg (radius 0.75rem), bg-card, subtle border, minimal shadow.
- Badges: rounded-full, muted/secondary fills; success badge for restored counts.

## Motion

- Entrance: subtle fade/slide on dialog and summary; ~200ms ease.
- Hover: gentle button darken and card border emphasis.
- Decorative: none — keep calm and restrained for a productivity app.

## Constraints

- App UI language is Lithuanian.
- Backup format must round-trip all data losslessly (JSON).
- Keep changes scoped — reuse existing tokens; only success/warning added for feedback.
- No per-child selective export/import; no CSV export.

## Signature Detail

Warm pastel "family journal" warmth carried into the backup screen via soft pink export action and a peach-toned restore confirmation — data safety that still feels gentle.
