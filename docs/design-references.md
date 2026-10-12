# Exam Duel: design references

Newest first.

## 2026-10-12: motion references (10 X posts, 15 videos)

Frames: `docs/refs/motion/rNN_vN_NN.png`. Each file is a 4×3 sheet at 1 frame per second (r02 is 1 per 2 s), so fast easing and timing are inferred, not measured.

### The references

| # | Link | What it is | Best idea for us |
|---|---|---|---|
| r01 | [Onethirdesigner](https://x.com/Onethirdesigner/status/2103749509616648627) | "4 Week Streak Earned" celebration | Sunburst, a badge that pops with overshoot, confetti, blur-in text, buttons held back until the celebration ends, tap to re-burst |
| r02 | [kitesdesign](https://x.com/kitesdesign/status/2046661517173801388) | An AI design tool's product demo (desktop, 81 s) | Typewriter prompt, a shimmering "Editing…" label, a checklist ticking through steps, a chart morphing. The camera zooms are marketing-video style, not app UI |
| r03 v1 | [kitesdesign](https://x.com/kitesdesign/status/2109484910008496427) | Fashion shop with an AI orb | Card expands into a detail screen; Add-to-cart turns into a circle and flies to the cart badge |
| r03 v2 / r08 | same post / [kitesdesign](https://x.com/kitesdesign/status/2108258040051019879) | "Money AI" finance assistant | Home blurs into the assistant, the orb grows out of a card, the title types on, a skeleton reply turns into a chart with growing bars |
| r03 v3 | same post | Finance dashboard | Each tab loads as a skeleton, then sections reveal top to bottom; gauge arc draws in, number counters, bars grow with the active bar highlighted |
| r03 v4 / r05 | same post / [kitesdesign](https://x.com/kitesdesign/status/2108646171338322425) | "Mindora" voice AI (dark) | A living orb, live transcript and waveform; the answer arrives as stacked cards; a map route draws itself |
| r04 v1 / r10 | [kitesdesign](https://x.com/kitesdesign/status/2108975375527367064) / [kitesdesign](https://x.com/kitesdesign/status/2107725821972766761) | Trail and travel app | A stacked card deck; a card expands to a full-screen hero with a sheet sliding up; an elevation line draws itself |
| r04 v2 / r09 | same post / [kitesdesign](https://x.com/kitesdesign/status/2107803839118397734) | "AI Meal Genius" | Staggered cards, labels popping in like tilted stickers, stat tiles one by one, Save turns into a spinner, a tick and a badge |
| r04 v3 | same post | "Energiq" energy investing | Radial gauge counting up to 87%, skeleton blocks, visible tap ripple |
| r04 v4 | same post | "Zenora" sunrise app | Logo glides into the hero spot, a tick-bar scrubber with a tooltip, a sliding nav pill, an arc with a dot travelling along it |
| r06 | [kitesdesign](https://x.com/kitesdesign/status/2108492671996354959) | Doctor consultation | Counters count up; incoming-call screen with a pulsing ring; a prescription "prints" out of a slot; a download button fills, turns green and shows a notification |
| r07 | [kitesdesign](https://x.com/kitesdesign/status/2108196967419646327) | AI real-estate assistant | Bottom sheet with an orb and suggestion chips; button morphs into a spinner; a full-screen gradient wash with a check that pops in |

### Motion playbook for Exam Duel

The patterns that recur across the references, mapped to our flow. Difficulty is for Flutter.

1. **Eve thinking (Snap → Map wait):** Eve with a breathing glow or orb pulse, a typewriter line ("Eve is reading your notes…"), a checklist that ticks ("Found 12 topics → Linking → Building your map"), and a shimmering skeleton grid that turns into real tiles one by one, top to bottom. *From r02, r03 v2, r05, r07, r08. Easy (`flutter_animate`, `shimmer`); Eve's moods are Medium in code, or Rive later.*
2. **Map tiles:** staggered drop-in on generation; a tile flips and changes colour on mastery; gold shimmer; a mastery ring that draws in with a % count-up. *From r03 v3, r04 v2/v3. Easy–Medium.*
3. **Tile → practice/duel (shared element):** the tapped tile grows into the screen header in its own colour, then a sheet slides up and its stats appear one by one. *From r03 v1, r04 v1/v4, r09, r10. Medium (`Hero` plus a custom transition).*
4. **Morphing buttons:** "Send duel" or "Save map" turns into a circle, then a spinner, then a tick, then flies to the tab bar or the friend's avatar. *From r03 v1, r04 v2, r06, r07. Easy–Medium.*
5. **Duel question and reveal:** the question card sits above an answer dock; tapped answers fill; the card collapses to make room for Eve's explanation and "Show me where"; a blur-to-sharp change between question and reveal. *From r03 v4, r06. Medium.*
6. **Results:** pastel stat tiles (Accuracy, Speed, Streak, XP) appear one by one with count-up numbers; bars per question grow, with the best highlighted; "+30 XP" stickers pop in at slight angles; the share card "prints". *From r03 v3, r06, r08, r09, plus glide's dot chart. Easy–Medium.*
7. **Celebrations (streak, duel win, tile turns gold):** a sunburst behind Eve, Eve pops with overshoot, confetti, text that blurs into focus, buttons appear only after; tap Eve for another burst. *From r01. Easy (`flutter_animate` + `confetti`).*
8. **Duel invite:** an incoming-call layout with the friend's avatar in a pulsing ring and Accept/Decline. *From r06. Easy.*
9. **Navigation:** a floating pill nav with a sliding selection; content swaps behind it. *From r03 v3, r04 v4. Easy.*

### Guardrails

- **Blur and shaders are expensive on cheap Android phones.** Use them in hero moments only, with a flat-colour fallback.
- **The iridescent orb** is the only effect that needs a shader. A rotating gradient approximates it cheaply, and Eve can play that role.
- **Respect the app's Reduce-motion setting.** Swap staggers and morphs for simple fades.
- **Don't copy:** the photo-heavy look (we have no photos), the faint grey text, and the camera zooms from the r02 demo.

## 2026-10-12: "glide" swim-app concept (owner's reference)

- **Source:** [Eddie Lobanovskiy on X](https://x.com/lobanovskiy/status/2108242136336601296), a 22 s screen recording of an AI-generated iOS concept.
- **Frames:** `docs/refs/glide/key-screens.png` (the four main screens) and `frames-1.png`, `frames-2.png` (one frame per second).

### What's in it

There are four screens, in the order a session happens:
1. **Today:** a score hero card, three stat tiles, an "Up next" card.
2. **Live swim:** a live timer pill, an illustrated scene, a dot chart.
3. **Session complete:** a streak pill, a "DONE" scene, the result.
4. **Splits:** a detailed breakdown with a "New PB" pill.

### What to borrow

| Glide element | What it is | Exam Duel version |
|---|---|---|
| Score hero card | Soft gradient blob (blue to coral), big **dot-matrix (LED-style) numbers**, a ruler tick scale, "+4 vs yesterday" | The **readiness %** on the map screen ("62", "+5 since yesterday"). The dot-matrix numbers could become our signature number style. |
| Pastel stat tiles | Lavender, mint and lime tiles with a small round icon badge | Already matches our pastel bento: questions answered, accuracy, streak. |
| Illustrated scene with giant word behind it | A swimmer in front of huge pale "SWIM", "62" or "DONE" | **Eve** in front of a giant topic name, "DUEL", the score, or "DONE". It's distinctive, and one illustration style carries the whole brand. |
| Dot charts | Columns of dots, with the best one in red | A duel timeline: one dot column per question (height for speed, colour for right or wrong). The topic map could also use dots. |
| Segmented progress bar | Dark segments with red markers | Duel progress through 10 questions, with markers for misses. |
| Pills | Lime pills ("4-DAY STREAK", "NEW PB · SPLIT 14"), a white pill with a red dot ("LIVE · 00:48:34") | Streak pill, "NEW BEST · Mitosis", "LIVE · Q4/10". |
| Small monospace caps labels | "LAP 62 · STROKE RATE", "OLYMPIC POOL · 50 M · LANE 4" | "Q4 · CELL BIOLOGY · FROM YOUR NOTES". |
| Buttons | Big black primary, pale blue secondary, round black icon button (share), red stop | Same hierarchy: black "Start duel", pale "Solo", round share button. |
| Floating bottom nav | A pill with 4 icons, floating above the content | Map · Duels · Snap (+) · Profile. |
| Flow | Today → Live → Complete → Splits | Map → Duel (live) → Duel done → Breakdown (which questions, the source in your notes, tiles that changed). |

### Adapt, don't copy

- **Glide is calm and premium; Exam Duel needs more energy for learners everywhere.** Keep the structure, spacing and polish, but add Eve's reactions, bounces and celebrations on wins and streaks.
- **Glide uses one strong accent (red).** We can keep one "hot" accent for live and important moments, alongside our pastels.
- **Contrast:** the pale grey text on light backgrounds in glide is too faint to be accessible. Our captions need 4.5:1 contrast.
- **Dot-matrix numbers:** use them only for big hero numbers. They're hard to read at small sizes.
