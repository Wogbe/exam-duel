# Exam Duel: feature ideas

Newest first. Effort: S (days), M (1-2 weeks), L (more). "Backend" says whether Supabase changes are needed.

## 2026-10-12 (2): AI learning for anyone, worldwide

**Direction (overrides the earlier exam-prep framing):** Exam Duel is an AI-powered, gamified learning app for anyone learning anything, anywhere. The user types or uploads what they are learning ("WAEC Biology", "AWS Solutions Architect", "French A2", notes, PDF, photo, link) and AI builds the topic map, questions and explanations. Duels, Eve, streaks and XP stay. This section does not repeat the section below; ideas 1 to 7 there still stand, but "syllabus tagging" (idea 1) becomes "AI builds the topic map from what the user names or uploads", and Afrilearn/Seneca-style fixed syllabi stop being the benchmark. The README says Ask Eve already generates questions; the gap is that it is category-only, not source-grounded.

**Research limits:** Web search returned mostly review blogs, aggregators and vendor comparisons. Very few Reddit or App Store/Play primary reviews surfaced, and Brainly returned nothing usable. Claims below are marked where they come from a commercially interested source. Prices conflict between sources; re-check before relying on any number.

### 1. Apps the first pass missed

| App | Core loop | What users like | Top complaints | Pricing pain |
|---|---|---|---|---|
| **Kahoot!** | Teacher hosts a timed live quiz; players join by PIN; leaderboard after each question | Easy to make or find a quiz; students enjoy it ([Trustpilot, via search](https://au.trustpilot.com/review/kahoot.com)) | Useful features paywalled; building quizzes by hand (finding images) is slow; reviewer said they had to pay to create a quiz from a vocab list | Plan sprawl (a competitor claims 22 plans, treat with caution, [AhaSlides](https://ahaslides.com/?p=60815)); no one-month option per a Trustpilot reviewer; a law firm is soliciting claimants over billing increases and hard cancellation (a recruitment page, not a finding: [Chimicles](https://chimicles.com/kahoot-class-action/)) |
| **Gimkit** | Answer questions to earn in-game cash, spend it on upgrades; students can add questions (KitCollab) | In-game economy gives strategy depth ([Jotform](https://www.jotform.com/blog/blooket-vs-gimkit/)) | More to learn, more complex to run | Reviews disagree on whether the free tier is usable; Pro cited at about $4.99/mo billed yearly, $14.99 flexible; homework assignment is paid on both Gimkit and Blooket ([Nibble](https://nibble-app.com/blog/blooket-vs-gimkit)) |
| **Blooket** | Question sets wrapped in many mini-game modes, live or homework | Variety of game modes, generous free tier | Fewer analytics and customisation options | Plus about $4.99/mo yearly; teachers still say they refuse to pay for any of these ([school paper quoted in search](https://tenthstreettimes.waukeeschools.org.staging3.juiceboxint.com/news/2022/09/quizlets-costly-charging)) |
| **Quizizz (now Wayground)** | Self-paced and live quizzes, now an "AI Generation Hub" that turns one file into several formats | Free plan kept; AI pitched as background help ([THE Journal](https://thejournal.com/Articles/2025/06/24/Quizizz-Rebrands-as-Wayground-Announces-New-AI-Features.aspx)) | Rebrand confusion; features moving behind a paywall (aggregator summaries only: [GetApp](https://www.getapp.com/all-software/a/quizizz/), [tooliverse](https://tooliverse.ai/tools/wayground)) | Advanced AI and deep LMS integration need a paid plan |
| **Photomath** | Snap a maths problem, get step-by-step solution | 4.6/5 on the App Store from about 729k ratings per an aggregator; step-by-step is the draw ([Kimola](https://kimola.com/reports/explore-photomath-app-feedback-insights-for-success-app-store-us-148152), [MyEngineeringBuddy](https://www.myengineeringbuddy.com/blog/photomath-reviews-alternatives-pricing-offerings/)) | Features once free moved to Plus; accuracy on handwriting and complex equations | Plus about $9.99/mo or $69.99/yr |
| **Knowt** | Notes to flashcards and quizzes with AI | Free Quizlet alternative, unlimited cards on free plan | Features creeping behind the Ultra plan; AI is text-only (no audio capture, mind maps) per a competitor's blog; smaller shared library | Ultra quoted at $24.99/mo or $149.99/yr by two sources, which conflicts with older tiers elsewhere ([Headway](https://makeheadway.com/blog/knowt-review/), [Nibble](https://nibble-app.com/blog/knowt-vs-quizlet)) |
| **Brainly** | Community Q&A for homework | Not verified | Not verified: no usable source found | Not verified |

**Pattern across all of them:** the loop is teacher-led (Kahoot, Gimkit, Blooket) or solver-led (Photomath), not friend-led, and the universal complaint is paywall creep. An independent comparison of 1 to 3 star reviews finds the main theme is a shift from free student tools toward subscriptions and AI upsells ([Unstar](https://unstar.app/blog/quizlet-anki-brainscape-knowt-studysmarter-flashcard-study-apps-ranked-2026), commercial blog). Making the AI core free and cheap to run is therefore a position, not just a cost.

### 2. AI-native study apps (the real competitors)

- **Quizlet:** AI tools (Magic Notes, Q-Chat, summaries) launched in 2023 ([Fortune](https://fortune.com/education/articles/quizlet-ai-powered-tools-q-chat-magic-notes-quick-summary-gpt)). Sources disagree on whether Q-Chat still exists (one review says it ended June 2025; another updated July 2026 still lists it), so treat its current feature set as unverified. Complaints: paywall for the full AI set, crashes and freezes in older app-store reviews ([Kimola](https://kimola.com/reports/unlock-insights-quizlet-ai-flashcards-customer-feedback-report-app-store-us-148155)). Reviewers note AI can misread abbreviations and oversimplify, and is weak at multi-step maths.
- **Knowt, StudyFetch, Mindgrasp, Coconote, Gizmo:** all turn audio, video, PDFs and links into notes, flashcards and quizzes. Mindgrasp advertises citations to sources and 35+ languages; Coconote advertises 100+ languages ([ClickUp roundup](https://clickup.com/blog/mindgrasp-ai-alternatives/), [Toolradar](https://toolradar.com/alternatives/coconote)). No independent accuracy tests found for any of them; Stork's compare pages show "no reviews yet". Revisely not found. Honest conclusion: generating cards from a PDF is now table stakes and nobody has proven quality.
- **Google NotebookLM:** quizzes, flashcards, audio overviews and mind maps from uploaded sources, with answers grounded in the sources. A University of Michigan review says hallucination "feels much lower" but is unproven and still produces synthesis errors, and output only reflects the quality of what you upload ([UMich](https://sites.lsa.umich.edu/learningteachingconsulting/2026/03/12/a-critical-look-at-notebooklm/)). Free-tier multimedia limits apply. It is solo and document-shaped, with no game loop.
- **Duolingo Max:** AI roleplay and video call. Explain My Answer became free for all in January 2026 per one guide, so Max now differs mainly by conversation; roleplay is described as short and scripted; price about $30/mo or $168/yr in the US ([Nibble](https://nibble-app.com/blog/is-duolingo-max-worth-it)). Lesson: the AI that cost real money got commoditised in about two years.
- **Khanmigo:** Khan Academy admits it has made maths mistakes and misjudged whether a student's steps were right, and added a calculator tool for arithmetic ([Khan Academy](https://blog.khanacademy.org/why-were-deeply-invested-in-making-ai-better-at-math-tutoring-and-what-weve-been-up-to-lately/)). Pricing figures conflict ($4 to $9/mo); teachers free.
- **ChatGPT Study Mode (July 2025) and Gemini Guided Learning (Aug 2025):** Socratic, step-by-step, and free-tier available; Gemini adds quizzes and visuals using LearnLM. Both are optional modes a student can switch off, so they are "more suggestion than solution" ([TechCrunch](https://techcrunch.com/2025/08/06/google-takes-on-chatgpts-study-mode-with-new-guided-learning-tool-in-gemini/), [Maginative](https://www.maginative.com/article/google-launches-guided-learning-for-gemini-joining-the-ai-tutor-arms-race/)). The free general assistants have eaten the "chat with your notes" space; a standalone app must win on the loop around the AI (friends, duels, habits), not the AI itself.

### 3. AI quality and trust

- **Generated MCQs have known failure modes:** ambiguous keys, implausible distractors, and questions on material not actually covered ([Springer study](https://link.springer.com/article/10.1007/s42979-024-02963-6), [ACL distractor paper](https://aclanthology.org/2023.eval4nlp-1.2)). In one study teachers judged only about 53% of generated distractors usable as-is even with retrieval help. Rubric checks ("is the key clearly right to someone who read the text; are distractors clearly wrong") are the reported validation method ([arXiv 2602.03704](https://arxiv.org/pdf/2602.03704)). No study found that tests source-faithfulness of each question directly, so the verification design below is ours, not borrowed.
- **Cheap verification pass:** (a) require the generator to quote the supporting span from the user's text and reject any question whose quote is not an exact substring; (b) a second model call answers the question blind from the source; mismatch with the key discards it; (c) similarity filter on distractors. Mindgrasp's cited-source feature shows users value this.
- **Report-a-wrong-question:** one tap, per-question; after N reports (or one report plus a failed blind re-check) the question is quarantined from duels and Eve apologises. In duels a disputed answer should refund the point, which also stops the "AI cheated me" feeling.
- **Difficulty calibration:** start with the model's guess, then replace it with the observed correct-rate across all players on that question (Elo-style per item). This only works at volume, so use a cold-start label (easy/medium/hard) and do not promise precision.
- **Source-less topics ("AWS Solutions Architect"):** without user text there is nothing to cite, which is where hallucination bites. Show an "Eve's own knowledge, not checked against your notes" badge on those questions and prefer well-known public syllabus outlines.
- **Young users:** the amended US COPPA rule had a compliance deadline of 22 April 2026; operators are liable for AI vendors, privacy notices must name third parties, and sending children's data to train AI needs separate parental consent; chatbot prompts can count as personal information ([Promise Legal](https://blog.promise.legal/coppa-april-2026-amendments-edtech/), [AI subprocessor note](https://blog.promise.legal/ai-subprocessor-disclosure-childrens-apps/); law-firm blogs, check the FTC text). Enforcement example: CARU against Buddy AI for no children's privacy policy and no parental consent ([Hunton](https://www.hunton.com/hunton-retail-law-resource/caru-takes-privacy-action-against-buddy-ai-childrens-learning-program)). GDPR-K and the UK Age Appropriate Design Code were not covered by search results and need a separate check. Practical stance: no free-text chat between players, preset reactions only (already the Spell Clash pattern), no training on user uploads, an under-13 mode that disables uploads and links, and a "private by default" note on uploaded notes.

### 4. Worldwide reach

- **Language quality is uneven and the gap is large for the audience you most want.** On West African exam questions GPT-4o scored over 90% in English but under 40% in African languages; the authors blame data imbalance ([AfricaNLP 2025](https://aclanthology.org/2025.africanlp-1.22)). Another benchmark found more false claims in low-resource African languages, and a Yoruba study found noisy input hurt far more than in English ([arXiv 2504.06536](https://arxiv.org/abs/2504.06536v1)). No direct measurement of question generation in these languages was found. Implication: ship the UI in many languages cheaply, but generate questions in English or well-resourced languages first, and mark other languages "beta, tell Eve if a question is wrong". Use the report button as the quality signal.
- **Data cost, not phone cost, is the barrier:** South Africa has over 72% smartphone ownership yet data cost remains the barrier; zero-rating and reverse billing (a sponsor pays for the app's data) are the proposed fixes ([Business Report](https://businessreport.co.za/careers/2025-10-31-stretch-every-megabyte-opera-mini-keeps-students-online-longer-this-exam-season/)). ULesson in Nigeria started by shipping lessons on SD cards and USB, then moved to downloadable offline content ([startup guide](https://startupguide.com/chalkboard-education), MIT Solve listing). Offline-first is described as the equity fix and also cuts cloud cost ([Marketinsyte](https://marketinsytedigest.beehiiv.com/p/bridging-the-digital-divide-through-offline-edtech-solutions)).
- **Design for it:** generation needs the network once; the generated deck (text JSON, a few KB per 20 questions) is cached on the device so practice, revision and solo play work offline, and a duel only needs tiny messages. Photos and PDFs should be reduced and text-extracted on the phone before upload (OCR on-device) to save data. Aim for a small APK and avoid video and heavy Rive assets in the default build.
- **On-device AI is possible but not yet a plan:** Gemini Nano needs supported hardware and has about 1,024-token prompts, so it will not run on the cheapest phones; open options like Qwen3 0.6B on LiteRT target low-end phones but no quality benchmark was found ([Android Developers](https://android-developers.googleblog.com/2024/06/top-3-updates-for-building-with-ai-on-android-google-io-24.html), [local-llms-on-android](https://github.com/dineshsoudagar/local-llms-on-android)). Use cloud generation with on-device caching for now.
- **Pricing:** Duolingo prices vary by country (lower in places like Turkey and India per a low-quality source; unconfirmed). Competitor paid tiers ($25/mo Knowt Ultra, $30/mo Duolingo Max) are out of reach in most markets. Suggested stance: free core loop with a daily AI-generation allowance, a small cheap pack or a weekly pass priced by region, and "sponsor a class" or telco zero-rating later. Not researched: Apple/Google regional price tiers, mobile-money payments. That needs a follow-up.

### Top new ideas

**N1. Turn anything into a duel (the signature candidate)**
- **Idea:** paste notes, a link, a PDF, or snap a photo; Eve turns it into a 10-question duel in seconds and gives a join code to send a friend.
- **Why:** NotebookLM, Knowt, StudyFetch and Wayground all generate quizzes from files, but all are solo or teacher-hosted (sources above); none ends with "send this to a friend and play now". Kahoot users complain about the time cost of making quizzes ([Trustpilot](https://au.trustpilot.com/review/kahoot.com)).
- **Fit:** Ask Eve already writes questions; this adds input types and room creation. The deck is attached to the room so friends need no account and no upload.
- **Effort:** M. Needs a Supabase edge function change (accept text, return questions with quoted source spans), storage for decks, and on-device OCR for photos. Cost control: per-user daily generation cap.

**N2. Source-checked questions with "Show me where" and Report**
- **Idea:** every AI question links to the exact sentence in the user's own material that justifies it (tap "Show me where"); questions with no matching quote are dropped; one-tap Report removes a bad question mid-duel and refunds the point.
- **Why:** hallucinated and ambiguous questions are the documented risk ([Springer](https://link.springer.com/article/10.1007/s42979-024-02963-6)); Khanmigo and Photomath both have public accuracy complaints ([Khan Academy](https://blog.khanacademy.org/why-were-deeply-invested-in-making-ai-better-at-math-tutoring-and-what-weve-been-up-to-lately/)); Mindgrasp cites sources as a selling point.
- **Fit:** the Explain-why screen (older idea 2) gains the quote; Eve says "this is from your notes, line 3". It also makes the learning loop real: you see the source after every miss.
- **Effort:** M. Generation prompt and a verify call; a `question_reports` table; reveal path already exists.

**N3. Offline decks and low-data mode**
- **Idea:** every generated deck downloads once and plays offline; Quick Fire, revision and solo duels with an Eve bot need no network; duels queue and sync.
- **Why:** data cost is the main barrier in Africa despite high smartphone ownership ([Business Report](https://businessreport.co.za/careers/2025-10-31-stretch-every-megabyte-opera-mini-keeps-students-online-longer-this-exam-season/)); ULesson and Chalkboard built on offline; Duolingo and Quizlet gate offline behind paid tiers ([search result](https://androidworld.nl/apps/duolingo-offline/)).
- **Fit:** the local store (`player_store.dart`) already holds per-question state in the older plan; add deck JSON and a "download for offline" chip. A free offline mode is a clear contrast with competitors.
- **Effort:** S to M. No backend change for solo; duel sync later.

**N4. Learn-anything topic map with starter packs**
- **Idea:** the user types a goal ("French A2", "driving theory, Kenya"); Eve proposes 8 to 12 topics with a one-line description, the user edits them, and questions are generated per topic. Popular goals become shared, human-checked packs.
- **Why:** NotebookLM has no topic-level progress; Duolingo and UWorld show people pay for structured paths ([UWorld](https://collegeprep.uworld.com/our-difference/uworld-sat-vs-khan-academy-sat)). Without source text, questions are the riskiest, so shared packs that players have rated are safer than generating fresh each time.
- **Fit:** replaces the 8 flat categories; feeds the Readiness Grid.
- **Effort:** M. Supabase tables for topic maps and packs; reporting data feeds pack quality.

**N5. Kinder AI limits: no free-text chat, a privacy-first under-13 mode**
- **Idea:** keep duel chat to preset reactions; no upload, link or free-text Ask Eve in the under-13 mode; no use of uploads for training; clear "what Eve sends to the AI" notice.
- **Why:** COPPA's amended rule (compliance date 22 April 2026) puts liability on the operator for AI vendors and can treat prompts as personal information ([Promise Legal](https://blog.promise.legal/coppa-april-2026-amendments-edtech/)); CARU acted against a children's AI tutor ([Hunton](https://www.hunton.com/hunton-retail-law-resource/caru-takes-privacy-action-against-buddy-ai-childrens-learning-program)).
- **Fit:** Spell Clash already uses presets-only reactions; same pattern here.
- **Effort:** S for the settings and copy; legal review is the real cost. Needs a date-of-birth or age-band gate, which touches onboarding.

### 5. Signature feature, re-evaluated

The Readiness Grid assumed a fixed syllabus. With AI building the topic map from whatever the user is learning, it survives but changes shape: it becomes "Eve's Map of whatever you're learning". The risk is that the AI-built map is only as trustworthy as the source, and for an uploaded set of notes the grid is just a list of the headings the AI found, which is less meaningful than a real exam syllabus and less recognisable as a shared image (two friends rarely have the same map). Its screenshot value drops unless the topics are common ones (shared packs).

New candidates:
- **Turn anything into a duel (N1):** the signature moment is the 10-second magic: photo or paste, then a duel code. Recognisable in a demo or a short video, shareable as a link, and the receiver plays instantly with no account.
- **Source-checked questions (N2):** a trust feature, not a signature; it makes N1 credible but nobody screenshots it.

| | Recognisability | Learning value | Fit with name and Eve | Buildability |
|---|---|---|---|---|
| A. Readiness Grid (AI-built map) | Medium (high only for common goals) | High | Good / Good | Good, needs N4 |
| B. Sure-or-Maybe Duel | Medium (live only) | High | Strong / Good | Good, small SQL change |
| D. Turn anything into a duel | High (demo-able in 10 seconds, link-shareable) | Medium to high (retrieval on the user's own material; depends on N2) | Strongest: "Duel" is in the name, Eve makes the questions | Good for text and photo; PDFs and links add cost; needs generation caps |

**Recommendation:** make **D, "Turn anything into a duel"**, the signature, with **N2 (show-me-where and Report)** shipped alongside it because an unverifiable generated duel will lose trust the first time a friend spots a wrong answer, and keep **A, the Readiness Grid**, as the second layer fed by the same topics (and B as the duel mechanic). Why: the Readiness Grid was chosen because it was screenshot-friendly on a fixed syllabus, which no longer holds; D is the only candidate that is both new (every AI competitor stops at solo cards or teacher-hosted quizzes) and tied to the name, and it solves Kahoot's main complaint (making quizzes takes long). The AI competitors have commoditised "make flashcards from my PDF" (see Duolingo's Explain My Answer going free and the free ChatGPT and Gemini study modes), so the thing worth owning is what happens after generation: a friend, a duel and a streak.

### Surprising findings

- Duolingo moved its headline AI feature (Explain My Answer) from paid to free within about two years, and ChatGPT and Gemini now give Socratic study modes free. AI explanation is not a moat; the social loop is.
- Even the best-grounded tool (NotebookLM) only claims "lower" hallucination, and no AI study app has published accuracy figures. A visible quote-the-source feature would be rare.
- Language quality falls off a cliff (90% to under 40% on the same exams) just where emerging-market growth is. Launching in many UI languages is cheap; generating questions in them is not.
- Almost every competitor's top complaint is paywall creep, not quality. Staying free where they gate (offline, homework-style assignment, AI generation allowance) is an easy contrast.
- Kahoot, Gimkit and Blooket are all teacher-led; none appears to serve a student who wants to challenge a friend on their own notes.

---

## 2026-10-12: exam-prep direction (all levels, learning-first, still a game)

**Already built or listed in the README (not re-suggested):** online rooms and duels, server scoring, Ask Eve AI questions, the 99-question bank, Fact of the Day, streaks and freezes, Quick Fire, XP/coins/wardrobe, emotes. The README's "Ideas for next" already lists a daily challenge (same 10 questions for everyone), category leaderboards and join deep links. Idea 5 below builds on the daily challenge rather than repeating it.

**Where the app stands today:** the question model is a flat bank with 8 trivia categories. There is no notion of level, subject, syllabus, topic, difficulty or explanation. Every idea below starts from fixing that, because nothing else in an exam app works without it.

### What the research says (short)

- **Retrieval and spacing beat re-reading.** Reviews of study techniques rank practice testing and distributed practice highest, and a 2021 synthesis of 242 studies reportedly agrees ([summary](https://evidencebased.education/resource/retrieval-and-spaced-practice-study-strategies-that-must-be-combined/)). Caveat: effects are smaller in real courses than in labs; a 2024 study across nine STEM courses found spacing helped in only two ([paper](https://stemeducationjournal.springeropen.com/articles/10.1186/s40594-024-00468-5)). So spacing should be cheap and invisible, not a chore.
- **Confidence plus feedback fixes errors.** Wrong answers given with high confidence are corrected more often once the answer is shown (hypercorrection), but they come back after a week unless re-tested ([Duke](https://today.duke.edu/2012/02/hypercorrection), [classroom study](https://pubmed.ncbi.nlm.nih.gov/29781391/)).
- **Interleaving helps, but is not magic.** Mixed practice nearly doubled next-day scores for 4th graders ([Taylor and Rohrer](https://digitalcommons.usf.edu/psy_facpub/1760/)); a Nigerian field trial found +0.28 SD short-term, no effect on year-end exams, and gains mostly for lower achievers ([NBER w31853](https://nber.org/system/files/working_papers/w31853/w31853.pdf)). Use it for revision sets, not first learning.
- **Gamification: levels and progress help, leaderboards are double-edged.** A programming-education meta-analysis (d about 0.4) credited levels, not badges or leaderboards ([review](https://ir.unimas.my/id/eprint/47028/)). Leaderboards motivate the top third and can discourage the rest ([same source](https://ir.unimas.my/id/eprint/47028/)).
- **Streaks backfire when they replace learning.** Users report keeping a streak while "going through the motions" and burnout ([arXiv case study](https://arxiv.org/pdf/2203.16175), [PCWorld](https://www.pcworld.com/article/2924235/why-i-fell-out-of-love-with-duolingo.html), [Decision Lab](https://thedecisionlab.com/insights/consumer-insights/streak-creep-the-perils-of-too-much-gamification)). The existing streak should count real review, not just opening the app.

### What competitors do and what students complain about

- **Quizlet:** paywalled Learn and Test modes in 2022 (5 Learn rounds and 1 test per set free); students were angry that a formerly free feature became paid ([Quizlet restrictions](https://waghostwriter.com/?p=84703), [student reaction](https://bmgator.org/33901/news/changes-to-quizlet-cause-frustration-among-students/)). Lesson: keep the core study loop free.
- **Anki:** the best spaced repetition, but the learning curve and setup time are the complaint ([forum](https://forums.ankiweb.net/t/anki-in-schools/24611?page=3)). Lesson: spaced repetition has to be automatic.
- **UWorld:** loved for explanations that say why each wrong option is a trap, topic-wise practice and performance tracking ([UWorld](https://collegeprep.uworld.com/our-difference/uworld-sat-vs-khan-academy-sat)); cost is the complaint.
- **Seneca:** UK exam-board-aligned courses, spaced repetition, XP, and teacher data ([Common Sense](https://www.commonsense.org/education/reviews/seneca-learning)).
- **Khan Academy:** a mastery-level system per skill ([help centre](https://support.khanacademy.org/hc/en-us/sections/18411186533517-Understanding-the-Khan-Academy-Mastery-system)).
- **Afrilearn (closest regional rival):** WAEC/NECO/JAMB/BECE past questions with solutions, class notes JSS1 to SS3, progress analytics, peer competition and points ([App Store](https://apps.apple.com/app/afrilearn/id6473706235), [Wikipedia](https://en.wikipedia.org/wiki/Afrilearn)). It does not have a live friend duel with a character; that is the gap.
- Not verified from searches: Kahoot, Gimkit, Blooket, Quizizz, Brainly, Photomath and Knowt complaints. Treat any claim about them as unchecked.

### Ideas

**1. Exam setup and syllabus tagging (the foundation)**
- **Idea:** onboarding asks level (primary, JHS/BECE, SHS/WASSCE, GCSE, SAT, university), subjects and exam date; every question gets `level`, `subject`, `topic`, `difficulty` and a written `explanation`.
- **Why:** Seneca and Afrilearn are organised by exam board and class; UWorld is loved for topic practice and explanations ([UWorld](https://collegeprep.uworld.com/our-difference/uworld-sat-vs-khan-academy-sat), [Afrilearn](https://apps.apple.com/app/afrilearn/id6473706235)).
- **Fit:** replaces the 8 flat categories with Subject > Topic. Eve greets by exam: "34 days to your BECE." Rooms get a subject/topic filter. Ask Eve gets "write questions for WAEC Biology, Genetics, SHS2."
- **Effort:** M. Local JSON first (extend `assets/data/questions.json`). Backend only later (add columns, update `build_seed.mjs`). Content writing is the real cost; Ask Eve can draft, a human must check.

**2. Explain-why feedback on every answer**
- **Idea:** after each answer, Eve shows the right answer, a one-line reason, and why the picked wrong option was tempting. Wrong answers go into a "Mistakes" list.
- **Why:** UWorld's explanations are its signature praise ([UWorld](https://collegeprep.uworld.com/our-difference/uworld-sat-vs-khan-academy-sat)); corrective feedback is what drives error correction ([Duke](https://today.duke.edu/2012/02/hypercorrection)).
- **Fit:** the duel reveal screen already shows the answer and a mini leaderboard; add an Eve speech bubble and "Save to review." Ask Eve returns the explanation field with each question.
- **Effort:** S for UI once the field exists; M for writing 99+ explanations. No backend for solo; online needs the explanation returned at reveal only (add to `room_question_keys` reveal path).

**3. Confidence call: "Sure" or "Maybe"**
- **Idea:** before locking an answer, tap Sure or Maybe. Sure-and-right earns bonus; Sure-and-wrong costs a feather and is flagged "Eve's catch" and re-asked soon.
- **Why:** high-confidence errors are the most correctable and the most dangerous if not re-tested ([hypercorrection, Duke](https://today.duke.edu/2012/02/hypercorrection)).
- **Fit:** one extra tap beside the answer grid; scoring multiplier in the server function for duels; a "Sure but wrong" counter on the results screen. Fits the "duel" idea: you are betting on yourself.
- **Effort:** S solo, M online (scoring rule in SQL).

**4. Smart revision: Mistakes deck and Weak-topic drill (automatic spacing)**
- **Idea:** wrong and "Maybe" answers return after 1, 3, 7 days inside a daily "Eve's Revision" set mixed with other topics (light interleaving). A Weak Topics card on home launches a 10-question drill.
- **Why:** spaced retrieval is the best-supported technique, but Anki's setup is the complaint, so make it zero-config ([evidence](https://evidencebased.education/resource/retrieval-and-spaced-practice-study-strategies-that-must-be-combined/), [forum](https://forums.ankiweb.net/t/anki-in-schools/24611?page=3)). Interleaving helps most lower achievers, so mix easy topics in ([NBER](https://nber.org/system/files/working_papers/w31853/w31853.pdf)).
- **Fit:** local store (`player_store.dart`) keeps per-question box and due date. The streak counts completing the day's revision, not opening the app. Reuses Quick Fire UI.
- **Effort:** M. No backend (local); sync later.

**5. Exam countdown and daily study plan**
- **Idea:** pick an exam date; Eve builds a plan ("today: 10 mins, Maths: Algebra + review"), shows days left and a readiness percentage, and nudges with one notification.
- **Why:** study-plan and progress tracking are what Seneca and Afrilearn sell ([Seneca](https://www.commonsense.org/education/reviews/seneca-learning), [Afrilearn](https://apps.apple.com/app/afrilearn/id6473706235)). Extends the README's "daily challenge" idea into something exam-specific.
- **Fit:** home hero card under the Fact of the Day. Plan length is 10 minutes by default to avoid streak burnout. "Rest day" tokens reuse streak freezes.
- **Effort:** M. No backend; needs local notifications.

**6. Past-paper mode (timed mock)**
- **Idea:** a timed paper of N questions in a real exam format (WAEC/BECE objective, SAT section), with a score by topic at the end and a "fix these" button feeding idea 4.
- **Why:** past questions with solutions are the headline of Afrilearn and the UWorld/Khan SAT comparison ([Afrilearn](https://apps.apple.com/app/afrilearn/id6473706235), [UWorld](https://collegeprep.uworld.com/our-difference/uworld-sat-vs-khan-academy-sat)).
- **Fit:** reuses the solo screen with a paper timer. Online variant: "Mock duel," same paper, scored at the end, friends' scores compared.
- **Effort:** M. Real past papers raise copyright questions; start with original exam-style questions.

**7. Kinder leagues and shared revision rooms**
- **Idea:** weekly leagues sized to similar levels, ranked by improvement and topics mastered (not raw XP); show a rank band, not 'last place'; add shared study rooms with a topic and a goal.
- **Why:** leaderboards help the top third and discourage others, and levels beat badges for learning ([review](https://ir.unimas.my/id/eprint/47028/)).
- **Fit:** extends the README's "category leaderboards" idea. Friend-only by default.
- **Effort:** L. Needs backend (league tables, weekly reset).

### Gamification guardrails

Keep XP, streaks and the wardrobe, but pay them for learning actions (finishing revision, fixing a mistake, mastering a topic), not for time spent. Keep Learn/Test-style core modes free. Show progress (levels, mastery) more than rank.

## Signature feature: candidates and recommendation

The signature is the one thing people recognise at a glance and talk about, like the Duolingo streak owl, Wordle's coloured grid or BeReal's dual photo. It should also work as a screenshot, and it must carry learning value.

### A. The Readiness Grid ("Eve's Exam Map")

A grid of tiles, one per syllabus topic, coloured by mastery: grey (unseen), amber (shaky), green (solid), gold (exam-ready). It fills in as you duel and revise. It has a shareable text/image form, e.g. `Exam Duel · WAEC Maths · 34 days 🟩🟩🟨⬜🟩🟨🟩🟩 62%`, and the tiles are the home screen.
- Recognisability: high; screenshots instantly, a Wordle-style share.
- Learning value: high; it is the weak-topic targeting view and drives revision (ideas 1 and 4).
- Fit: strong with Eve (she sits on the grid and says "Genetics is amber, shall we?") and with the exam countdown; a duel can be launched on any tile. Weaker tie to the "Duel" in the name.
- Buildability: good. Needs topic tags (idea 1) and per-topic stats stored locally; the grid is a simple widget. No backend.

### B. Sure-or-Maybe Duel (the confidence bet)

Every duel answer is a bet: lock "Sure" for double points or lose a feather if wrong. Eve calls out "Sure but wrong!" and the friend sees your bet. The signature moment is the flip of two players' confidence marks at the reveal.
- Recognisability: medium; clear in a live duel, but hard to see in a screenshot, so less viral.
- Learning value: high; matches hypercorrection and calibration research ([Duke](https://today.duke.edu/2012/02/hypercorrection)).
- Fit: strongest tie to the name "Exam Duel" (head to head, bluffing, risk); Eve can act as the referee.
- Buildability: good. One extra tap and a scoring rule; a server change for online (SQL).

### C. Eve grows with your readiness (the Exam Nest)

Eve's look and the nest change as exam day approaches: eggs hatch into a fledgling that grows feathers by topic mastered, and on exam day she wears a graduation cap. A countdown owl lives on the home screen and the app icon badge.
- Recognisability: medium-high; a mascot that visibly changes is Duolingo-like and memorable.
- Learning value: medium; motivating, but it rewards progress, not specific retrieval.
- Fit: strongest with Eve and the existing wardrobe (outfits, eye colours); the countdown ties to exam date.
- Buildability: medium. Needs new Eve art or Rive states; the logic is simple.

### Comparison

| | Recognisability | Learning value | Fit with name and Eve | Buildability |
|---|---|---|---|---|
| A. Readiness Grid | High (shareable image) | High | Good / Good | Good, no backend |
| B. Sure-or-Maybe Duel | Medium (live only) | High | Strong / Good | Good, small SQL change |
| C. Exam Nest | Medium-high | Medium | Good / Strong | Medium (art-heavy) |

### Recommendation

Build **A, the Readiness Grid**, as the signature, with **B** as the duel mechanic that feeds it (a "Sure" answer that is right turns a tile greener faster; "Sure but wrong" turns it amber and queues revision) and **C** as a later layer (Eve's plumage mirrors the grid). A is the only one that is both a screenshot people share and the plan the student actually studies from, so it spreads the app and drives revision. It also depends only on idea 1 (topic tags) and local storage, so it fits the "UI first, before backend/auth" order.

Suggested build order: 1 (tags), 2 (explanations), grid UI over local stats, 4 (revision), 3 (confidence), 5 (countdown), 6 (mock), 7 (leagues).

### Caveats on this research

Most gamification evidence here comes from programming and general e-learning, not exam prep specifically; Duolingo critiques are mostly small-scale or opinion. Kahoot, Gimkit, Blooket, Quizizz, Brainly, Photomath and Knowt were not covered by the searches. Re-check Quizlet's current limits before citing them.
