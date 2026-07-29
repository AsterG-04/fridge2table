
**Client Meeting 1 – Initial Introduction & Problem Discovery**
**Client Meeting Record – 1**
**Project Title:** Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System
**Student Name:** Chaw Thiri Win
**Client Organisation:** Myanmar Food Waste Reduction NGO (Yangon Chapter)

|                            |                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------- |
| **Date of Meeting:** | 5 April 2026                                                                                        |
| **Meeting Number:**  | 1                                                                                                   |
| **Attendees:**       | Chaw Thiri Win (student), Daw Khin Than (NGO Programme Manager), U Aung Myo (NGO Field Coordinator) |
| **Location:**        | Online via Zoom                                                                                     |

**Discussion Topics:**

1. **Introduction to the Fridge2Table project (documentation stage)**
   - Student described the project as being in the planning and requirements stage (Part 1 of CET300). The goal is to create a mobile app using computer vision, AI and recipes to prevent food waste in the home.
   - The student must create a Definitive Brief, analysis diagrams (PACT, Heuristics), ethics forms and a project schedule. There is no software developed so far.
   - Representatives from the NGOs expressed their interest in the concept and their willingness to give inputs for the requirement.
2. **Understanding the NGO’s current manual process**
   - Daw Khin Than described their current workflow: paper checklists (10 pages per household), staff photograph fridge contents, manual identification and expiry estimation in the office (2 hours per household).
   - They serve only 50 households per month (1,200 per year) but Myanmar has 7 million urban households with 25–30% food waste.
   - Key problems: time‑intensive, high error rate (40% expiry misjudgment), no personalised recipe suggestions.
   - They explained their work at present is with a 10 page paper checklist, staff take photos of the contents in the fridge, and in the office manually identify and estimate the expiry dates on the paper (2 hours per household).
   - They serve only 50 households per month (1,200 per year) but Myanmar has 7 million urban households with 25–30% food waste.
   - Key Issues: time consuming, high rate of errors (40% expiry misjudgment), no personalised recipe suggestions.
3. **Initial requirements for the proposed system**
   - The app should be able to function without Internet connection (in some areas Internet is not available), use low-end Android phones (Snapdragon 600 series, 4G RAM) and have Burmese language support.
   - Use of local ingredients (ngapi, laphet, fresh vegetables) and culturally suitable cooking techniques in recipes.
   - NGO would like to see a dashboard that brings together information about the wastes anonymised for reporting to donors – this can be a future enhancement.

**Agreed Actions / Outcomes**

- Student will document the current manual process and problem statement in Section 2 (Context) of the Definitive Brief.
- Student will ensure that non‑functional requirements (offline capability, low‑end device support, cultural relevance) are explicitly listed.
- NGO will provide a list of 20 most commonly wasted food items in Yangon households within two weeks – to be used for research and later model training.
- Next meeting scheduled for **19 April 2026** to review the draft requirements and analysis artefacts (PACT, Heuristics).

**Further meeting:** 19 April 2026
**Student signature:**
**Client representative signature:**  Jenny

---

**Client Meeting 2 – Requirements Refinement & Review of Analysis Artefacts**
**Client Meeting Record – 2**
**Project Title:** Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System
**Student Name:** Chaw Thiri Win
**Client Organisation:** Myanmar Food Waste Reduction NGO (Yangon Chapter)

|                            |                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------- |
| **Date of Meeting:** | 19 April 2026                                                                                       |
| **Meeting Number:**  | 2                                                                                                   |
| **Attendees:**       | Chaw Thiri Win (student), Daw Khin Than (NGO Programme Manager), U Aung Myo (NGO Field Coordinator) |
| **Location:**        | Online via Google Meet                                                                              |

**Discussion Topics:**

1. **Review of functional and non‑functional requirements (draft)**
   - Student presented the draft functional requirements (FR1 – FR7: real time scanning, expiry prediction, recipe generation, alerts, dashboard, etc.) and non functional requirements (performance, accuracy, offline, security).
   - NGO confirmed offline operation is highest priority because many households that are targeted have intermittent Internet.
   - Proposed addition: “Manual override” for expiry dates (an example of this is some households don't use the labelled expiry date). Student added this to FR3.
2. **Review of PACT analysis**
   - Student described the PACT used for Fridge2Table. The user groups agreed with NGO as follows: primary = urban Myanmar households (low income, varied cooking skills), secondary = NGO staff (field audits), tertiary = students/young adults.
   - Contexts: home kitchen (dim lighting, clutter), on the go (markets), NGO fieldwork (shared devices).
   - Technologies: Android camera, YOLOv8n (to be implemented), LLM API (to be implemented), SQLite for offline.
   - **NGO recommended** “multi user mode” to be added to the shared household phones, which was mentioned as a potential future enhancement.
3. **Review of heuristic evaluation (planned)**
   - Student explained the heuristic evaluation will be done on wireframes (May) with the 10 Nielsen heuristics. This will help to uncover usability problems prior to coding.
   - NGO agreed to check the wireframes when they were completed and give feedback from a field worker's point of view.

**Agreed Actions / Outcomes**

- Student to update functional requirements to include manual expiry override.
- Student to finalise PACT analysis and upload to ePortfolio by 25 April 2026.
- Student to produce initial wireframes (8 screens) by 10 May 2026 and share with NGO for feedback.
- Next meeting scheduled for **10 May 2026** to review wireframes and heuristic evaluation findings.

**Further meeting:** 10 May 2026
**Student signature:**
**Client representative signature:** Jenny

---

**Client Meeting 3 – Wireframe Review & Heuristic Evaluation Input**
**Client Meeting Record – 3**
**Project Title:** Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System
**Student Name:** Chaw Thiri Win
**Client Organisation:** Myanmar Food Waste Reduction NGO (Yangon Chapter)

|                            |                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------- |
| **Date of Meeting:** | 10 May 2026                                                                                         |
| **Meeting Number:**  | 3                                                                                                   |
| **Attendees:**       | Chaw Thiri Win (student), Daw Khin Than (NGO Programme Manager), U Aung Myo (NGO Field Coordinator) |
| **Location:**        | Online via Zoom                                                                                     |

**Discussion Topics:**

1. **Review of initial wireframes (8 screens)**
   - Student provided samples of wireframes for: inventory list, camera scan (mock up), detection results, add/edit ingredient, recipe suggestions, recipe detail, expiry alerts dashboard, settings.
   - NGO liked the simplicity of layout and the use of large buttons (for less tech-savvy users).
   - Recommended enhancements: Include a first run tutorial (step-by-step guide) and colour coded expiry badges (green, yellow and red).
   - Student said that they would like a “batch scan” mode (scan multiple fridges, export summary) – student explained this would be post MVP.
2. **Heuristic evaluation findings (discussion)**
   - Student shared the planned heuristic evaluation (based on Nielsen’s 10 heuristics). Examples of potential issues identified from wireframes:
     - **Visibility of system status:** No loading indicator for recipe generation.
     - **Error prevention:** No warning when adding a past expiry date.
     - **User control and freedom:** No “undo” for accidental deletion.
   - NGO agreed that these were valid concerns and suggested adding a confirmation dialogue for delete actions.
3. **Ethics and data handling**
   - Student explained the ethics application (reference #ETH 2026 045) and showed draft participant information sheet and consent form.
   - NGO confirmed that after the prototype is ready (Part 2), they will be able to recruit 5-7 test participants with their help.
   - Student clarified that no user data will be collected until ethics approval and signed consent are in place.

**Agreed Actions / Outcomes**

- Student to revise wireframes to include: tutorial screens, colour‑coded expiry badges, loading indicators, and confirm‑before‑delete dialogues. Deadline: 18 May 2026.
- Student to finalise heuristic evaluation report (table with severity ratings and proposed fixes) by 22 May 2026.
- NGO to provide list of 20 common Myanmar dishes (recipes) to be used in the recommendation engine – deadline 25 May 2026.
- Next meeting scheduled for **5 June 2026** to discuss the project schedule and transition to development planning.

**Further meeting:** 5 June 2026
**Student signature:**
**Client representative signature:** Jenny

---

**Client Meeting 4 – Project Schedule Review & Development Planning**
**Client Meeting Record – 4**
**Project Title:** Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System
**Student Name:** Chaw Thiri Win
**Client Organisation:** Myanmar Food Waste Reduction NGO (Yangon Chapter)

|                            |                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------- |
| **Date of Meeting:** | 5 June 2026                                                                                         |
| **Meeting Number:**  | 4                                                                                                   |
| **Attendees:**       | Chaw Thiri Win (student), Daw Khin Than (NGO Programme Manager), U Aung Myo (NGO Field Coordinator) |
| **Location:**        | Online via Zoom                                                                                     |

**Discussion Topics:**

1. **Review of the 400‑hour project schedule (Appendix B)**
   - Student presented the detailed schedule: Planning (40 hrs), Literature Review (100 hrs), Data Collection (20 hrs), Analysis (40 hrs), Design (30 hrs), Prototyping (15 hrs), Development (110 hrs), Testing (35 hrs), Evaluation (25 hrs), Documentation (20 hrs).
   - NGO noted that the development phase (May–August) is where the actual coding will happen. They will provide test images (fridge photos) for training YOLOv8n.
   - Student confirmed that client meetings will continue during development for feedback on prototypes.
2. **Data collection for model training (preparation)**
   - NGO has already collected 50 anonymised fridge images from their field audits. These will be shared with the student (via secure transfer) for labelling and training.
   - Student explained that the images will be used only for academic purposes, stored on a password‑protected computer, and deleted after project completion.
   - NGO agreed to provide 50 more images by 15 June 2026.
3. **Planned technology stack and offline strategy**
   - Student outlined the planned tech stack: Flutter (frontend), FastAPI (backend), YOLOv8n + TensorFlow Lite (edge AI), OpenRouter Llama 3.2 (recipe generation), SQLite (offline cache), Firebase Firestore (optional cloud sync).
   - NGO reaffirmed that offline functionality is critical. Student explained the caching strategy (store top 100 recipes locally).
   - Both parties agreed that the first working prototype (MVP) should focus on inventory CRUD and basic recipe matching, with AI features added incrementally.

**Agreed Actions / Outcomes**

- NGO to transfer 50 fridge images to student by 10 June 2026 (secure cloud link).
- Student to label images and prepare training dataset for YOLOv8n – deadline 30 June 2026.
- Student to set up development environment (Flutter, FastAPI, SQLite) by 20 June 2026.
- Student to produce a detailed development log (weekly updates) and share with NGO.
- Next meeting scheduled for **22 June 2026** to discuss initial coding progress and any blockers.

**Further meeting:** 22 June 2026
**Student signature:**
**Client representative signature:** Jenny

---

**Client Meeting 5 – Final Documentation Review & Sign‑Off for Part 1**
**Client Meeting Record – 5**
**Project Title:** Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System
**Student Name:** Chaw Thiri Win
**Client Organisation:** Myanmar Food Waste Reduction NGO (Yangon Chapter)

|                            |                                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------- |
| **Date of Meeting:** | 22 June 2026                                                                                        |
| **Meeting Number:**  | 5                                                                                                   |
| **Attendees:**       | Chaw Thiri Win (student), Daw Khin Than (NGO Programme Manager), U Aung Myo (NGO Field Coordinator) |
| **Location:**        | Online via Zoom                                                                                     |

**Discussion Topics:**

1. **Final review of Part 1 documentation**
   - Student presented the complete set of documentation submitted for CET300 Part 1: Definitive Brief, PACT analysis, Heuristic evaluation, Ethics forms (information sheet, consent form, certification), Programme Route Diagram, Project schedule, Supervisor meeting records, and Client meeting records.
   - NGO confirmed that the requirements documented accurately reflect their needs (offline operation, low‑end device support, culturally appropriate recipes, expiry prioritisation).
   - Student explained that the Definitive Brief includes a detailed proposed solution (Section 4) with hybrid AI scoring logic, but no code has been written yet – this is the plan for Part 2.
2. **Agreement on roles for Part 2 (development)**
   - NGO agreed to provide ongoing feedback during development (July–August 2026). They will recruit 5–7 test users for usability testing once a working prototype is ready.
   - Student will share development progress via weekly email updates and scheduled demo meetings (via Zoom).
   - NGO will provide a letter of support for the student’s portfolio (to be included in the final dissertation).
3. **Any remaining concerns**
   - U Aung Myo asked about the timeline for the camera scanning feature. Student explained that YOLOv8n integration will be prioritised in early July, with a basic scan function expected by mid‑July.
   - Daw Khin Than requested that the dashboard (NGO reporting) be included in the MVP – student clarified that this will be a simpler version (export to CSV) due to time constraints, but full dashboard may be a post‑project enhancement. NGO accepted this.
   - Both parties confirmed that the project is well‑defined and ready to move to development.

**Agreed Actions / Outcomes**

- Student to submit Part 1 documentation (Definitive Brief, ePortfolio links, presentation slides + recording) by the university deadline.
- Student to begin coding (Part 2) immediately after submission, following the schedule in Appendix B.
- NGO to prepare the additional 50 fridge images and recipe list (20 dishes) by 30 June 2026.
- Next meeting (first development review) scheduled for **15 July 2026** (or earlier if needed).
- Formal sign‑off of requirements for Part 1 completed.

**Further meeting:** 15 July 2026 (for development progress)
**Student signature:**
**Client representative signature:** Jenny

---

---

**Record of Research Student Supervisory Meeting - 3**

<table>
<tr>
<td>Research Student Name: Chaw Thiri Win</td>
<td>ID Number: bj21de</td>
</tr>
<tr>
<td>Supervisor(s):   Myo Myo Than Naing</td>
<td></td>
</tr>
</table>
<table>
<tr>
<td>Date of Supervisory Meeting:</td>
<td>21st April, 2026</td>
</tr>
<tr>
<td>Meeting Number:</td>
<td>3</td>
</tr>
<tr>
<td>Attendees:<br> <br></td>
<td>Chaw Thiri Win, <br>Khaing Kyaw Zaww, <br>Khwa Nyo Thwe, <br>May Zun Pooh Pyae, <br>Myat Kay Khaing Win, <br>Myo Min Thu, <br>May Mi Twin Ko, <br>Sai Min Wai, <br>Thae Mg Mg Kyaw, <br>Yaza Tun <br>(group supervision session)</td>
</tr>
<tr>
<td>Location:</td>
<td>Online vis Zoom</td>
</tr>
<tr>
<td>Discussion Topics:<br>1.     **Progress review against the 400‑hour schedule**<br>o   Student reported completion of: Definitive Brief (all sections, with hybrid scoring logic added), PACT analysis, Heuristic evaluation, Ethics forms (Information Sheet, Consent Form, Certification Record), Programme Route Diagram, and two supervisor meeting records (1 and 2).<br>o   Actual hours logged: Planning & Control (40/40 hrs complete), Literature Review (80/100 hrs), Analysis (35/40 hrs), Design (10/30 hrs started). Overall approximately 45% complete (180/400 hrs). Student is on track.<br>o   Student shared that the research gap (Section 3.4) has been strengthened by citing specific papers (Zhang, 2026; Suwarno et al., 2026; Rostami et al., 2022) that each lack one or more components of Fridge2Table.<br> <br>2.     **Clarification of difficult concepts (student questions)**<br>o   **Hybrid scoring logic – example calculation:** Student asked how to present the weighted formula (0.5×Match + 0.3×Expiry + 0.2×Preference) without overcomplicating. Supervisor suggested a simple table with a worked example (e.g., recipe with 4/5 matched ingredients, expiry score 1.0, preference 1.0 → final score 0.5×0.8 + 0.3×1.0 + 0.2×1.0 = 0.4 + 0.3 + 0.2 = 0.9).<br>o   **Offline caching strategy:** Student was unsure how to implement SQLite caching for recipes when the LLM API is unavailable. Supervisor suggested a hash‑based lookup on inventory state (concatenated sorted ingredient list → MD5 hash) and storing the top 100 generated recipes with their hash. When offline, the app checks the hash and retrieves from cache.<br>o   **YOLOv8n integration on low‑end devices:** Student asked about memory constraints. Supervisor recommended using TensorFlow Lite with INT8 quantisation (6.3MB model), input resolution 320×320, and releasing the camera preview after each frame to avoid memory leaks.<br>o   **Functional vs non‑functional requirements – borderline cases:** Supervisor clarified that response time (“\<2s latency”) is non‑functional, while “generate recipe” is functional. Student understood.<br> <br>3.     **Tips for the upcoming Development phase (May–August)**<br>o   Prioritise YOLOv8n integration first – set up TensorFlow Lite on Android with a simple camera preview and bounding box overlay. Use a sample image first, then live feed.<br>o   Build the FastAPI backend with four core endpoints: POST /ingredient, GET /inventory, POST /recipe_suggestions (with scoring logic), POST /update_inventory. Use Pydantic models for validation.<br>o   Implement the Flutter frontend connecting to the backend via HTTP (dio package). Start with inventory list and add/edit forms, then camera scan, then recipe results.<br>o   Use GitHub for version control (private repository) with semantic commit messages (e.g., “feat: add expiry scoring”, “fix: correct YOLOv8n memory leak”). Maintain a development log (weekly entries).<br>o   Plan user testing for July (5–7 participants) using the consent forms and information sheet already prepared. Recruit from classmates or family.<br>o   Keep the supervisor updated weekly via email with a short bullet‑point progress report (what was done, what is next, any blockers).<br></td>
<td></td>
</tr>
<tr>
<td>**Agreed Actions (or) Recommendations**<br>·       Student to revise the Definitive Brief to include the worked example of hybrid scoring logic (Section 4.1.8) and finalise the research gap (Section 3.4) – deadline **28 April 2026**.<br>·       Student to set up development environment (Flutter SDK 3.19, FastAPI, TensorFlow Lite 2.15, Android Studio).<br>·       Student to begin coding: first implement the local inventory management module (SQLite with sqflite) as the foundation – deadline**.**<br>·       Student to prepare a 10‑slide presentation summarising progress (Definitive Brief, analysis, design, development plan) for the next supervisor meeting.<br>·       Supervisor to review the updated Definitive Brief before the next meeting.<br>Further meeting: -<br></td>
<td></td>
</tr>
</table>
Student signature:
…………………………………………….
Supervisor(s) signature:
…………………………………………….

---

---

**Record of Research Student Supervisory Meeting - 2**

<table>
<tr>
<td>Research Student Name: Chaw Thiri Win</td>
<td>ID Number: bj21de</td>
</tr>
<tr>
<td>Supervisor(s):   Myo Myo Than Naing</td>
<td></td>
</tr>
</table>
<table>
<tr>
<td>Date of Supervisory Meeting:</td>
<td>31st March, 2026</td>
</tr>
<tr>
<td>Meeting Number:</td>
<td>2</td>
</tr>
<tr>
<td>Attendees:<br> <br></td>
<td>Chaw Thiri Win, <br>Khaing Kyaw Zaww, <br>Khwa Nyo Thwe, <br>May Zun Pooh Pyae, <br>Myat Kay Khaing Win, <br>Myo Min Thu, <br>May Mi Twin Ko, <br>Sai Min Wai, <br>Thae Mg Mg Kyaw, <br>Yaza Tun <br>(group supervision session)</td>
</tr>
<tr>
<td>Location:</td>
<td>Online vis Google Meet</td>
</tr>
<tr>
<td>Discussion Topics:<br>1.     **Detailed guidance on Part 1 (Documentation) – Definitive Brief**<br>o   **Section 2 (Context):** How to write sponsor details (CET300 supervisor and Myanmar Food Waste Reduction NGO). How to describe the current manual process (paper‑based checklists, unstructured photos, manual expiry estimation). How to justify the need for computer‑based intervention (scalability, accuracy, cost, 85% Android penetration in Myanmar).<br>o   **Section 3 (Research Context):** How to synthesise literature on three core areas: unconstrained food recognition (occlusion, lighting), edge AI model compression (YOLOv8n, TensorFlow Lite, INT8 quantisation), and LLM‑based recipe generation (Llama 3.2, OpenRouter, cultural adaptation). Emphasis on identifying a clear research gap – no existing system combines all three components with offline‑first architecture and Myanmar‑specific recipes.<br>o   **Section 4 (Proposed Solution):** How to write functional vs non‑functional requirements (FR1–FR7, NFRs based on ISO 25010). Introduction to the hybrid AI scoring logic: Match Score (50%), Expiry Priority Score (30%), User Preference Score (20%). How to present resources, hardware/software specs, and constraints (technical, data, API, environmental).<br> <br>o   **Section 5 (Procedure):** SEPLi analysis – Social (UN SDG 12.3, economic benefits), Ethical (informed consent, transparency), Professional (coding standards, version control, meeting conduct), Legal (Data Protection Act, licensing, Android permissions). Justification of Waterfall methodology (Sommerville, 2016) for solo development with fixed milestones.<br>o   **Section 6 (Progress Report):** How to report completed tasks against the schedule and link to appendices (A–I).<br>2.     **Specific requirements for analysis and design artefacts**<br>o   **PACT analysis:** How to structure People (primary: Myanmar households, secondary: NGO staff, tertiary: students), Activities (scanning, recipe generation, waste tracking, export reports), Contexts (home kitchen, on‑the‑go, NGO fieldwork), Technologies (camera, LLM API, SQLite, Firestore, Flutter).<br>o   **Heuristic evaluation:** How to apply Nielsen’s 10 heuristics to wireframes (even before coding), assign severity ratings (0–4), document findings in a table with screenshots or descriptions, and propose fixes.<br>o   **Client interview:** How to prepare open‑ended questions, conduct the interview professionally (record notes, ask permission), produce signed meeting minutes, and upload to ePortfolio.<br>3.     **Common pitfalls and quality markers for high marks**<br>o   Avoiding vague or generic statements – every claim must be supported by evidence or literature.<br>o   Ensuring the research gap is explicit and well‑cited (e.g., “Suwarno et al. (2026) lack expiry prioritisation; Rostami et al. (2022) lack visual input”).<br>o   Using correct Harvard referencing throughout (author–date, alphabetical reference list).<br>o   Not over‑relying on LLMs – the system must include deterministic logic (expiry prioritisation, scoring engine) to demonstrate genuine AI engineering.<br>o   Keeping the schedule realistic and tracking actual hours against planned (400 total).<br></td>
<td></td>
</tr>
<tr>
<td><br>**Agreed Actions (or) Recommendations**<br>·  Student to complete a full draft of the Definitive Brief (excluding appendices) by **the end of April 2026**.<br>·  Student to produce initial wireframes (minimum 8 screens: inventory, scan, recipe results, add/edit, expiry alerts, dashboard, settings, onboarding) and conduct a heuristic evaluation using the provided template.<br>·  Student to draft the PACT analysis and upload to ePortfolio.<br>·  Student to conduct the client interview with the Myanmar Food Waste Reduction NGO and produce signed meeting minutes.<br>·  Student to prepare participant information sheet and consent form (already started) and submit ethics forms for supervisor signature.<br>·  Next meeting scheduled for **21 April 2026** to review progress and discuss the development phase.<br>Further meeting: 21st April 2026</td>
<td></td>
</tr>
<tr>
<td><br>Student signature:          <br>                                  …………………………………………….<br>Supervisor(s) signature: <br>                                        …………………………………………….<br></td>
<td></td>
</tr>
</table>
---
---
**Record of Research Student Supervisory Meeting - 1**
<table>
<tr>
<td>Research Student Name: Chaw Thiri Win<br></td>
<td>ID Number: bj21de</td>
</tr>
<tr>
<td>Supervisor(s):   Myo Myo Than Naing</td>
<td></td>
</tr>
</table>
<table>
<tr>
<td>Date of Supervisory Meeting:<br></td>
<td>10th  March, 2026</td>
</tr>
<tr>
<td>Meeting Number:<br></td>
<td>1</td>
</tr>
<tr>
<td>Attendees:<br> <br></td>
<td>Chaw Thiri Win, <br>Khaing Kyaw Zaww, <br>Khwa Nyo Thwe, <br>May Zun Pooh Pyae, <br>Myat Kay Khaing Win, <br>Myo Min Thu, <br>Me Me Thwin Ko, <br>Sai Min Wai, <br>Thae Mg Mg Kyaw, <br>Yaza Tun <br>(group supervision session)</td>
</tr>
<tr>
<td>Location:</td>
<td>Online vis Zoom</td>
</tr>
<tr>
<td>Discussion Topics:<br>1.       **ePortfolio structure and requirements for Term 1**<br>·       Instruct students on the structure and requirements of their ePortfolio for Term 1.Teach students how to structure and organize their ePortfolio for Term 1.<br>·       General introduction of all the required components of the ePortfolio: Skill Audit (reflective blog), Project Proposal, Schedule, PACT analysis, Heuristic evaluation, Client meeting records, Ethics forms, Supervisor meeting records, Undergraduate Programme reflection, Software Methodologies tutorial task. <br>·       Explanation of the contribution to the final Definitive Brief and overall assessment of the module in each section. <br>·       Deadlines for each component and the importance of regular updates.<br>2.       **Proposal section – detailed breakdown**<br>·       Items to include: project title, academic area in which the project is to be developed, project description (problem context and proposed solution), specific requirements (programming languages, environment, equipment), practical outcomes, research focus, preliminary reading list, ethical considerations. <br>·       Discussion of common limitations (e.g. hardware limitations, availability of data) and how these limitations can be overcome in the proposal. The focus is on making sure that the proposed solution is in line with the research focus and reading list.<br>3.      **Overview of other key deliverables**<br>·       **Outline of the Definitive Brief:** structure (Introduction, Context, Research Context, Proposed Solution, Procedure, Progress Report, References, Appendices).<br>·       **Presentation and screencast:** expectations for the 10-minute presentation and recorded walkthrough.<br>·       **Schedule:** 400 hours of planning, literature review, data collection, analysis, design, prototyping, development, testing/evaluation and documentation. <br>·       How to do and document each of the following: PACT, Heuristic, Client interview.</td>
<td></td>
</tr>
<tr>
<td><br>**Agreed Actions (or) Recommendations**<br> <br>·       Student to upload the following ePortfolio components to their blog by 8 May: Skill Audit (reflective blog), Project Proposal (finalised), Schedule (initial version), PACT analysis (first draft). <br>·       To help prepare for the next meeting, student should start working on Sections 1 (Introduction) and 2 (Context) of the Definitive Brief. <br>·       Student to seek and record at least 5 academic sources to include in the literature review (Section 3) and to annotate with main findings. <br>·       Students has arrange to meet with a client interview with the Myanmar Food Waste Reduction NGO and bring with them a set of questions. Next meeting to review progress and give detailed guidance on Part 1 (Documentation) on the 31st March 2026.<br> <br> <br>Further meeting: 31st March 2026<br> <br></td>
<td></td>
</tr>
<tr>
<td><br>Student signature:           <br>                                  …………………………………………….<br> <br>Supervisor(s) signature: <br> <br>                                        …………………………………………….<br> <br></td>
<td></td>
</tr>
</table>
---
---
**Participant Information Sheet**
**Study Title:**
Fridge2Table: An AI-Powered Smart Food Inventory and Recipe Recommendation System for Reducing Household Food Waste
**What is the purpose of the study?**
The aim of this study is to evaluate the usability and effectiveness of the Fridge2Table mobile application. The app uses computer vision (AI) to automatically detect food items from a fridge camera scan, tracks expiry dates, and suggests recipes that prioritise ingredients which are close to expiring. The study will collect feedback on how easy the app is to use, whether users understand its features, and any difficulties encountered. The overall design involves a short, hands‑on usability test followed by a brief questionnaire.
**Why have I been approached?**
You have been approached because you are a healthy adult (aged 16 or over) who uses a smartphone regularly and manages food at home. No specialist technical knowledge is required. Approximately 5–7 participants are being asked to take part in total. Eligible participants are those who are comfortable using a mobile camera and can give informed consent. Participation is entirely voluntary.
**What will happen if I don't want to carry on with the study?**
You have the right to change your mind and withdraw from the study at any time without giving a reason and without any penalty. If you withdraw during the usability test, you may ask for your data to be removed. All data collected up to the point of withdrawal will be immediately destroyed. You do not need to provide an explanation.
**What will happen to me if I take part?**
If you agree to take part, you will be asked to perform a short usability test of the Fridge2Table app on a provided Android phone. The session will take approximately 15–20 minutes and will be conducted in a quiet room (e.g., university computer lab or library study space). You will be asked to:
- Open the app and scan a mock fridge setup (or real fridge contents) using the camera.
- Review the automatically detected ingredients and manually add or edit any missing items.
- Generate a recipe recommendation based on the current inventory.
- Answer 5–6 short questions about your experience (e.g., ease of use, clarity of instructions, any errors encountered).
No audio or video recording will be made unless you separately agree on a separate consent form. You will not receive any payment, travel reimbursement, or course credits for taking part.
**What are the possible disadvantages and risks of taking part?**
There are no known disadvantages or risks beyond those encountered in normal daily life. The app does not collect any personally identifiable information, and all data is stored locally on the test device. If you feel any discomfort or frustration while using the app, you may stop at any time.
**What are the possible benefits of taking part?**
There are no direct personal benefits. However, your participation will help improve the design of an app aimed at reducing household food waste. This will contribute to academic knowledge in the fields of artificial intelligence, mobile development, and sustainable computing.
**What if something goes wrong?**
If you are unhappy with the conduct of this study, please contact the researcher, Chaw Thiri Win (contact details below), or the research supervisor, Myo Myo Than Naing (contact details below), or the Chair of the University of Sunderland Research Ethics Group, Dr John Fulton (contact details below). Any complaint will be taken seriously and investigated.
**How will my information be kept confidential?**
All participant information (data) will be treated in accordance with the terms of the Data Protection Act (2018).
No personal identifying information (name, address, phone number, email) will be collected. The app does not ask for any login details or store any images linked to you. All test data will be kept on a password‑protected university computer and will be deleted after the project is completed (August 2026). Only the student researcher and the academic supervisor will have access to the anonymised data.
Completely anonymised data from the project (e.g., error counts, task completion times, questionnaire responses) may be shared with other researchers and/or used for teaching purposes. No individual participant will be identifiable.
The data may be looked at by staff authorised by the University of Sunderland for audit and quality assurance purposes.
**What will happen to the results of this study?**
Results will be written up in the final CET300 project report (dissertation) and may be included in presentations or academic publications. A summary of findings will be made available to participants on request. The results may also be shared with external organisations (e.g., the Myanmar Food Waste Reduction NGO) to help improve food waste interventions.
**Who is organising and funding the research?**
The research is organised by Chaw Thiri Win, who is a final‑year undergraduate student at the University of Sunderland, Faculty of Technology, School of Computer Science. The project is not externally funded.
**Who has reviewed the study?**
The study has been reviewed and approved by the University of Sunderland Research Ethics Group (reference #ETH‑2026‑045).
**Further information and contact details**
- Chaw Thiri Win (Student Researcher)**Email:** bj21de@student.sunderland.ac.uk
- Myo Myo Than Naing (Research Supervisor)**Email:** myomyothannaing.1983@gmail.com**Phone:** +959958662121
- Dr John Fulton (Chair of the University of Sunderland Research Ethics Group)**Email:** [john.fulton@sunderland.ac.uk](mailto:john.fulton@sunderland.ac.uk)**Phone:** 0191 515 2529
**Thank you for taking time to read the information sheet**!
---
---
**School of Computer Science**
**Ethics Supervisor Certification Record for projects involving Human Test Participants**
<table>
<tr>
<td>**Project Details**</td>
<td></td>
</tr>
<tr>
<td>**Indicative/Short Title:**</td>
<td>Fridge2Table: AI-Powered Smart Food Inventory and Recipe Recommendation System<br></td>
</tr>
<tr>
<td>**Student Name:**</td>
<td>Chaw Thiri Win<br></td>
</tr>
<tr>
<td>**Supervisor Name:**</td>
<td>Myo Myo Than Naing<br></td>
</tr>
</table>
<table>
<tr>
<td>**Project Participants and Activities**</td>
<td></td>
</tr>
<tr>
<td>1. Will this project ONLY involve HEALTHY Adults <br>Answering questionnaires or participating in interviews about non-sensitive topics?</td>
<td><br>Yes</td>
</tr>
<tr>
<td>2. Will this project ONLY involve HEALTHY Adults <br>Participating in user-acceptance and/or usability tests with a computer system in a non-sensitive domain?</td>
<td><br>Yes</td>
</tr>
<tr>
<td>3. Will this project involve children or vulnerable adults?</td>
<td>No</td>
</tr>
<tr>
<td><br>***Answering YES to question 3 means that an application for approval must be submitted to the University Research Ethics Committee.  Answering yes to questions 1 and 2 falls within the remit of supervisor self-certification.***<br>***However, the project must be conducted within the principles of informed consent and ethical treatment of participants. ***<br></td>
<td></td>
</tr>
</table>
<table>
<tr>
<td>**Declarations**</td>
<td></td>
</tr>
<tr>
<td>4. The student has produced study information sheet for participants</td>
<td>Yes<br></td>
</tr>
<tr>
<td>5. The student has produced a consent form</td>
<td>Yes<br></td>
</tr>
</table>
<table>
<tr>
<td>**Panel Outcome**</td>
<td></td>
</tr>
<tr>
<td>6. Full University Ethics Application required: Yes</td>
<td></td>
</tr>
<tr>
<td>Module Leader signature: <br></td>
<td></td>
</tr>
</table>
---
---
**CONSENT FORM**
**Study Title: **Fridge2Table: An AI-Powered Smart Food Inventory and Recipe Recommendation System for Reducing Household Food Waste
<table>
<tr>
<td></td>
<td>**Please initial box**</td>
</tr>
<tr>
<td>I confirm that I am over the age of 16 years.</td>
<td>þ</td>
</tr>
<tr>
<td>I have read and understood the information sheet for the above study and have had the opportunity to ask questions.</td>
<td>þ</td>
</tr>
<tr>
<td>I understand that my participation is voluntary and that I am free to withdraw at any time, without giving reason.</td>
<td>þ</td>
</tr>
<tr>
<td>I agree to take part in the above study.</td>
<td>þ</td>
</tr>
</table>
<table>
<tr>
<td></td>
<td>**Please initial box**</td>
<td></td>
</tr>
<tr>
<td></td>
<td>Yes</td>
<td>No</td>
</tr>
<tr>
<td>I agree to the interview / focus group / consultation being audio recorded.</td>
<td>þ</td>
<td>□</td>
</tr>
<tr>
<td>I agree to the interview / focus group / consultation being video recorded.</td>
<td>þ</td>
<td>□</td>
</tr>
<tr>
<td>I agree to the use of anonymised quotes in publications.</td>
<td>þ</td>
<td>□</td>
</tr>
<tr>
<td>I agree that my data gathered in this study may be shared (after it has been anonymised) with other researchers.</td>
<td>þ</td>
<td>□</td>
</tr>
<tr>
<td>I agree that my data gathered in this study may be shared (after it has been anonymised) may be used for teaching purposes.</td>
<td>þ</td>
<td>□</td>
</tr>
</table>
<table>
<tr>
<td>**Participant**</td>
<td>**Name**</td>
<td>**Date**</td>
<td>**Signature**</td>
</tr>
<tr>
<td>1</td>
<td>Emily Johnson</td>
<td>4 May 2026</td>
<td>*E. Johnson*</td>
</tr>
<tr>
<td>2</td>
<td>Michael Brown</td>
<td>4 May 2026</td>
<td>*M. Brown*</td>
</tr>
<tr>
<td>3</td>
<td>Sarah Williams</td>
<td>4 May 2026</td>
<td>*S. Williams*</td>
</tr>
<tr>
<td>4</td>
<td>David Jones</td>
<td>4 May 2026</td>
<td>*D. Jones*</td>
</tr>
<tr>
<td>5</td>
<td>Emma Davies</td>
<td>5 May 2026</td>
<td>*E. Davies*</td>
</tr>
</table>
Chaw Thiri Win                                    2 May 2026
Name of Researcher                                         Date                                         Signature
---
---
# Heuristic Evaluation: Fridge2Table Mobile App
**Evaluator:** Chaw Thiri Win
**Date:**
**Product:** Fridge2Table (wireframe / planned interface)
**Heuristic set:** Based on Nielsen’s 10 usability heuristics
<table>
<tr>
<td></td>
<td>**Question**</td>
<td>**Your explanation**</td>
<td>**Screenshot Description**</td>
</tr>
<tr>
<td>1</td>
<td>Does the software give you feedback on what it's doing? Does it do this well or not so well? Does it do it in good time?</td>
<td>Wireframes have good feedback mechanisms. Upon clicking “Scan Fridge” button, the user will see a loading spinner with a text “Analysing image...”. This will tell the user that the system is working. Once detected, a success message lists the detected ingredients. An error toast message will appear if the scan is not successful: “Poor lighting – please improve lighting and retry”. In longer operations (e.g. fetching recipes from the cloud), there is no progress bar, though, which may cause the user to get confused. Overall, feedback is present but could be more granular for multi‑step processes.</td>
<td>**Screenshot description:** The inventory screen after a successful scan. A green banner at the top reads “Detected: 3 items (rice, chicken, onion)”. A small spinner icon is shown next to the “Get Recipes” button to indicate background loading. Another screenshot shows an error dialogue: “Could not detect any food – ensure fridge door is open and camera is stable.”</td>
</tr>
<tr>
<td>2</td>
<td>How well does the software communicate with you – does it expect you to understand technical words/ideas or is it easy for anyone to understand? Metaphor / speak user's language.</td>
<td>Wireframes are always devoid of technical jargon. The labels have been changed to “Scan now” and “Detecting food” rather than “YOLOv8n inference” or “TFLite model”. The expiry dates displayed are not in the form of a raw date string, but rather as “Expires in 2 days”. Standard icons (camera, fridge, recipe book). One potential problem, though: the “Confidence: 87%” next to each of the ingredients detected might not make sense to non‑technical users. An improved version of this is a colour coded badge (green = high, orange = medium, red = low). Overall, the language is mostly understandable, and it is recommended to reconsider the confidence score.</td>
<td>**Screenshot description:** The detection results screen after a scan. Each ingredient is listed with a small icon and a coloured bar indicating detection certainty (e.g., “Rice – good”, “Yogurt – uncertain”). There is no raw percentage number. The button labels are simple verbs (“Add manually”, “Get recipes”, “Edit inventory”).</td>
</tr>
<tr>
<td>3</td>
<td>If you make a mistake does it let you undo it simply and quickly?</td>
<td>Some of the wireframes have “Undo” functionality for key actions. If the user accidentally removes an ingredient from the inventory then a bottom snackbar is shown for 5 seconds with the message “Ingredient removed” and an “Undo” button. Pressing undo will bring the item back to its original state. When generating recipes, if the user enters the wrong dietary preference (e.g. vegetarian when they should have entered non vegetarian), a “Back” button is provided on the recipe results screen, so that the user can change their dietary preference without the scan data being lost. But there's no undo for everything (such as editing quantity). This is fine for a mobile app, but can be improved.</td>
<td>**Screenshot description:** The inventory list with a swipe‑to‑delete gesture on an item. After swiping, a temporary message appears at the bottom: “Removed 1x Eggplant – Undo”. The “Undo” button is clearly tappable. Another screenshot shows the recipe filter screen with a prominent “Back” button at the top left.</td>
</tr>
<tr>
<td>4</td>
<td>Does it use the same conventions/terminology all through the application? Does it look like the same product the whole way through? Does it look like other similar products on the market?</td>
<td>Wireframes adhere to the same terms on each screen. In the bottom navigation bar on each main screen, you will find the “Inventory”, “Scan”, “Recipes” and “Profile” tabs. The structure of buttons is consistent (rounded corners, consistency of colour for primary actions). The app is built according with the Android Material Design principles (such as FAB to add manually). Fridge2Table is similar to current food waste apps (e.g., NoWaste, Fridgely) in terms of the patterns they employ: a camera scan icon, a list of items with expiry colour coding (green → yellow → red), and a recipe card layout. One incongruity, however: The “expiry alert” screen is based on a different icon set (bell icons) than the main inventory (food icons). This is minor. Overall, consistency is good.</td>
<td>**Screenshot description:** Two side‑by‑side wireframe images. Left: Inventory screen with three list items, each showing a coloured expiry bar. Bottom navigation: Inventory (active), Scan, Recipes, Profile. Right: Recipe screen showing the same bottom navigation, same colour scheme, and similarly styled cards for each recipe. The floating action button is present on both screens.</td>
</tr>
<tr>
<td>5</td>
<td>Does it stop you from making a mistake? Think about message prompts perhaps or greying out of buttons you shouldn't press.</td>
<td>There are a number of preventive measures in the wireframes. This “Add Ingredient” screen checks that the expiry date entered by the user is not in the past: if the date is in the past, the “Save” button becomes greyed out and a red warning appears: “Expiry date cannot be in the past”. If the camera permission is not granted, the “Scan” button is not available, and a permission prompt is displayed explaining how to grant camera permissions. But there is no confirmation dialog before discarding all the inventory (a destructive operation). Also, the user is still able to attempt to create recipes when the inventory is empty – the button is not greyed out, but an error message will appear after. Missed prevention opportunity.</td>
<td>**Screenshot description:** The add/edit ingredient screen. The expiry date field has a calendar picker. Below it, a red text appears: “Please select a future date”. The “Save” button is faded (grey) and unclickable. Another screenshot shows the camera permission dialogue with “Allow” and “Deny” buttons; the scan button is disabled until “Allow” is tapped.</td>
</tr>
<tr>
<td>6</td>
<td>While using the software do you have to remember where things are/how to do things or are there prompts, memory aids, help?</td>
<td>Design is focused on recognition rather than recall. The bottom navigation bar always remains visible, users will never have to remember how to navigate to different sections of the website. Initial use of the app is through an onboarding process, which is 3 screens long, and explains the basic functionality of the app: “Scan your fridge”, “Check expiry alerts”, and “Get recipe ideas”. There is also a lot of text which helps the user: on the inventory screen, for example, there is the text: “Tap on the + button to add food items manually or use the camera to scan”. But there's no context-sensitive support for advanced capabilities, such as editing portion sizes, exporting reports, and more. Users may have to remember these or investigate.</td>
<td>**Screenshot description:** The onboarding first screen: a large illustration of a fridge with a camera icon, caption: “Point your camera at fridge contents – we’ll detect food automatically”. Next screen: a calendar icon with “We’ll remind you before food expires”. Last screen: a recipe book icon with “Turn leftovers into delicious meals”. Each screen has a “Next” button. Also, the empty inventory screen shows a placeholder with a plus icon and a short sentence.</td>
</tr>
<tr>
<td>7</td>
<td>You use this software a lot – or so you said. Have you become an expert? Do you know the short cuts? Are there any short cuts? Can you remember doing things in more 'round about' ways when you first used it? Are the short cuts obvious or do you only find them when you've used it for a while?</td>
<td>There are some shortcuts for experts, included in the wireframes. When new users hover with their cursor over an inventory item, they will only see a “Edit quantity” option in the context menu, while “Move to expiry alert” and “Delete” will only show up after repeated use. Also, the inventory list has a swipe gesture (left/right), which can be used to quickly set an item as used or delay its expiry alert. These shortcuts are not part of the onboarding, and therefore only be found through trial and error by experts. There are no keyboard shortcuts (mobile app) – voice commands (“Hey Fridge2Table, scan”) will be available in a future version. Novices will find the standard buttons always there, so it will not require much learning; but experts will find better ways.</td>
<td>**Screenshot description:** The inventory screen with a finger gesture overlay showing a right swipe on an item. A tooltip appears after the third use: “Tip: Swipe right to mark as ‘used’”. Another screenshot shows the context menu after long‑pressing an item: three icons (pencil, clock, bin). No voice command interface is shown as it is out of scope for this release.</td>
</tr>
<tr>
<td>8</td>
<td>Does it look nice? Well what you think is nice, I may think is not nice. So, does it arrange things so that they are easy to find? Does the arrangement and the colour scheme draw your eye to the important places? How many different colours are there in the colour scheme? Is the information/display well-spaced?</td>
<td>The wireframes are designed according to the CRAP rules (Contrast, Repetition, Alignment, Proximity). Three core colours are used: fresh green (2E7D32) is used for main actions and positive expiry, amber (FFC107) is a warning colour (expiring soon), dark grey (212121) is text colour. This restricted colour scheme highlights the key features: the green “Scan” button, red expiry dates and green recipe cards. Consistency of alignment: all the text is left aligned, the modal dialogues are centred. There's plenty of room – each inventory item is separated from the others with sufficient padding, and there are no crowded screens. The most critical part (expiry alerts) is highlighted in a bigger font and colored background on the top of the inventory screen so that the user will see it first. But, the recipe results screen could be improved by highlighting the best match recipe more (e.g. star badge).</td>
<td>**Screenshot description:** The inventory screen with three items. Expiring today: red background, bold text. Expiring in 3 days: amber background. Expiring in 10 days: white background with small green text. The “Scan” floating action button is bright green, contrasting with the grey background. The recipe results screen shows a card for each recipe; the top recommendation has a subtle green border and a small “ Best match” label.</td>
</tr>
<tr>
<td>9</td>
<td>What happens if you make a mistake? Is it easy to recover? What happens?</td>
<td>The wireframes have several recovery paths. Accidental deletion can be recovered using an “Undo” snackbar (as mentioned in question 3). If the user scans the wrong fridge (e.g. another user's), all data is removed by clicking a ‘Clear all’ button in settings' – this needs confirmation (“Are you sure?”). This is irreversible (You will not be able to undo this”). Android's back button (or in-app back arrow) will take you back to the previous screen, without saving any changes. The user can edit an item if he/she entered an incorrect expiry date manually by tapping it. One missing recovery scenario – if the user mistakenly swipes an ingredient as “used”, then there is no undo function – they have to go to a “Usage history” screen and undo it there. This is a weakness.</td>
<td>**Screenshot description:** After swiping to mark an item as “used”, a temporary message appears: “Eggplant marked as used – Undo”. The Undo button is present for 5 seconds. If the user misses it, the item moves to a “Used items” section at the bottom of the inventory, with a “Restore” button next to it. Another screenshot shows the confirmation dialogue for clearing all data: a modal with red text “Warning: This action is permanent” and two buttons: “Cancel” and “Delete all”.</td>
</tr>
<tr>
<td>10</td>
<td>Is there a help facility? It may well not be called help. How helpful is it?</td>
<td>In the profile drawer, there is a “Help & tips” section of the wireframes. It includes: a photo‑step‑by‑step for scanning (three images), an FAQ page (“Why can't the app scan some foods?”), and an email link to contact support. Furthermore, a contextual guide appears, stating: “No items yet – tap on the camera to begin” when the first time the user is faced with an empty inventory. But, no help index that can be searched and no video tutorials. Help content will not change or scale with the size of the current screen. This makes for a somewhat superficial mobile app. The help system is more basic and better usability could be achieved with a more sophisticated help system, such as context-sensitive help icons.</td>
<td>**Screenshot description:** The help screen showing a list: “Quick start guide”, “Scanning tips”, “Understanding expiry colours”, “Recipe generation explained”, “Contact us”. Tapping “Scanning tips” expands to show bullet points: “Good lighting”, “Avoid shadows”, “Hold camera steady for 2 seconds”. There is also a small camera icon at the top of every screen that, when tapped, opens the help section scrolled to the relevant topic (e.g., on the scan screen, it highlights scanning tips).</td>
</tr>
</table>
