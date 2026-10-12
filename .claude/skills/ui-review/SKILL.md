---
name: ui-review
description: Review a screen or widget of Exam Duel and list what to improve (hierarchy, consistency with the theme, accessibility, responsiveness, game feel, states, copy). Use after creating or changing UI in lib/screens, lib/widgets or lib/theme, or when the user asks to check or critique a screen. Runs on Sonnet in a separate context. Reports only; doesn't edit code.
model: sonnet
effort: medium
context: fork
background: false
argument-hint: <screen or file, or empty for the UI files changed in git>
---

# UI review

Target: $ARGUMENTS. If empty, review the UI files changed since the last commit:
`git diff --name-only HEAD -- lib/screens lib/widgets lib/theme` (if nothing is
changed, use the last commit's files).

## 1. See it

Pick the best option available and say which one you used:
1. Screenshots the user attached or named.
2. A running app: if the dart-flutter MCP is connected (`dtd` to find the app),
   use `widget_inspector` for the tree and `flutter_driver_command` for a screenshot.
3. Code only: read the widget files and `lib/theme/app_theme.dart`, and picture
   the layout at 360 px wide (phone) and 1280 px (web, ≥900 px layout in
   `lib/widgets/responsive.dart`).

## 2. Check

- **Hierarchy**: one clear primary action per screen; the eye lands on the right thing.
- **Consistency**: colours, type and radii come from `app_theme.dart` (`context.c`,
  `Pastel`, accent choice). Flag hard-coded `Color(0x…)`, font sizes or paddings
  that should be tokens. Spacing and card style should match sibling screens.
- **Accessibility**: tap targets ≥48 dp, text contrast ≥4.5:1 (3:1 for large text)
  in light **and** dark mode, `Semantics` labels on icon-only buttons, layout
  survives 1.3× text scale, "Reduce motion" setting respected by animations.
- **Responsive**: no overflow at 360 px; the web layout uses the space well; keyboard
  answers (1–4 / A–D) still work.
- **States**: loading, empty, error, offline (no Supabase keys), slow network,
  reconnecting mid-game, long nicknames, 12 players in a room.
- **Game feel**: feedback on every tap (spring button, haptics), clear correct/wrong
  reveal, timer urgency, celebration moments (confetti, streaks), and Eve used to
  react, not just decorate.
- **Copy**: short, friendly, clear about what happens next.

## 3. Report

- **Top 3 fixes** first, most impact first.
- Then a table: severity (High/Med/Low) · issue · `path:line` · suggested fix.
- End with 1–2 things that already work well, so they don't get "fixed".
For deeper visual ideas, suggest running `/design-references <screen>`.
