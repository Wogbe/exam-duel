---
name: design-references
description: Find the best real-world design references (apps, Dribbble/Behance shots, Mobbin-style screen patterns, game UI) for a screen, component or feature of Exam Duel, and say what to borrow. Use before designing or redesigning a screen, or when the user asks for inspiration or references. Runs on Sonnet in a separate context and saves its findings to docs/design-references.md.
model: sonnet
effort: medium
context: fork
argument-hint: <screen, component or feature, e.g. "lobby", "results podium">
---

# Design references

Target: $ARGUMENTS (if empty, cover the screens in `lib/screens/`).

## 1. Know the current direction first

Read `lib/theme/app_theme.dart` and the README's first paragraph. Exam Duel is a
party trivia game: pastel bento cards, Urbanist + Figtree fonts, Eve the owl
mascot with moods and outfits, dark mode, reduced motion. References must fit
this direction. Don't propose a new visual identity unless the user asked for one.

## 2. Search

Use WebSearch (`standard`; `extended` for niche patterns) and WebFetch. Good sources:
- Shipped party and quiz games: Kahoot!, Trivia Crack, QuizUp, HQ Trivia, Jackbox,
  Gartic Phone, Duolingo (streaks, mascots, celebrations), Wordle-style sharing.
- Pattern galleries: Mobbin, Dribbble, Behance, Game UI Database, Page Flows.
- Pastel or bento UI and mascot-led apps.

Prefer shipped apps over concept shots, since they've been tested with real players.

## 3. Write `docs/design-references.md`

Create the file, or add a dated section for this target and keep earlier sections.
For each screen or component:
- 3–5 references, each with a link, one line on what makes it good, and **what
  to borrow** concretely (layout, motion, feedback, copy, an empty state).
- **Avoid**: one or two patterns that look nice but hurt clarity, speed or accessibility.
- **Suggested change for Exam Duel**: short and specific, naming the file in
  `lib/screens` or `lib/widgets` it would touch.

## 4. Reply

Reply with the top 3 recommendations (one line each) and the file path. Don't
paste the whole file. Don't edit code.
