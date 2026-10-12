---
name: feature-scout
description: Research features that could make Exam Duel more fun, sticky or shareable (competitor apps, player reviews, retention mechanics, trends) and add the best new ones, deduplicated, to docs/feature-ideas.md. Use when the user asks for feature ideas or what to build next, or once after a feature is finished and committed. Runs on Sonnet in the background.
model: sonnet
effort: medium
context: fork
argument-hint: <optional focus, e.g. "retention", "multiplayer", "monetisation">
---

# Feature scout

Focus: $ARGUMENTS (empty means anything).

## 1. Know what exists

Read the README ("What's in it", "Ideas for next"), `docs/feature-ideas.md` (if
any) and `docs/STATUS.md` (if any). Never re-suggest something already built or
already listed.

## 2. Research

Use WebSearch (`standard`; `extended` for recent trends) and WebFetch:
- What players praise and complain about in Kahoot!, Trivia Crack, QuizUp, HQ
  Trivia, Jackbox, Duolingo, Wordle and similar (store reviews, Reddit threads).
- Retention and social mechanics that work for party and quiz games: daily
  challenges, streaks, seasons, friend leagues, sharing, invites, deep links.
- Recent launches or trends in casual multiplayer and AI-generated content.

## 3. Add to `docs/feature-ideas.md`

Add a dated section with 3–7 ideas, each with:
- **Idea**: one line.
- **Why**: the evidence, with a source link.
- **Fit**: how it would work in Exam Duel (Eve, rooms, streaks, Ask Eve).
- **Effort**: S/M/L, and whether it needs backend changes (Supabase).
Keep older sections. Mark an older idea "Done" if the README shows it's built.

## 4. Reply

Reply with the top 3 ideas (one line each) and the file path. Don't edit code.
