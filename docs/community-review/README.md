# Shakti: four weekly community-project reviews

Team: **Lekhan, Manas, Vikat, Hemanth** · DBIT · VTU **1BCP308**, Scheme 2025, Semester III, 1 credit.

Source: `D:/1BBCP308.pdf`, pages 1–9. The supplied syllabus lists Shakti's relevant category as **Topic 22: Use of application / application program** (page 4), with a useful community app and measured usability, adoption or efficiency improvement. Earlier project documents use Topic 25; that number is not present in this supplied syllabus. Confirm the departmental registration label with the guide. Topic 22 maps PO1, PO3, PO4, PO5, PO9, PO10 and SDG9, SDG11, SDG17.

The syllabus suggests 15 teaching-learning phases across a semester. These are grouped below into four **review milestones**, not a claim that VTU mandates a four-week semester. The 30-hour allocation is a proposed academic activity budget per student, not a statement of hours already completed or a software-development estimate. Obtain guide agreement on the compressed review schedule. All software can be implemented now; field work, actual reviews, approval and results must retain their real dates.

## Schedule and evidence

| Review | Syllabus phases and proposed hours | Review deliverables and demonstration | Gate |
|---|---|---|---|
| Week 1: understand the community | 1 Introduction/ethics (1h); 2 problem/topic (1h); 3 stakeholder survey (3h); 4 problem/objectives (1h); 5 baseline/case study (2h). **8h** | Team and consent process; anonymised interviews; baseline of current guardian-contact methods; problem, objectives and scope. Show onboarding, permissions, contact setup and lock flows as available implementation. | Guide reviews problem and scope; genuine survey records and baseline denominators are available. |
| Week 2: design the response | 6 planning/roles (1h); 7 feasibility/alternatives (2h); 8 final design (2h); 9 calculations/mapping (2h). **7h** | Architecture, data boundaries, SMS versus internet trade-offs, cost assumptions, consent and tracker privacy. Demonstrate local SOS persistence, cancellation, contact dispatch and queue design. | Design connects each requirement to a test; distinguish cached/missing location and delivery versus send-call results. |
| Week 3: implement and validate | 10 prototype/app (4h); 11 testing/refinement (4h). **8h** | Demonstrate SOS, duress, PIN, escort, guardian tracker, maps/routes, AI/offline assistance, FIR draft, fake call, siren and evidence vault. Attach automated logs and physical-device test results separately. | Every core feature has pass/fail/not-run evidence; critical defects assigned; no simulated SMS results labelled carrier delivery. |
| Week 4: demonstrate and reflect | 12 community demonstration (3h); 13 outcomes/feedback (2h); 14 presentation practice (1h); 15 final presentation/reflection (1h). **7h** | Consented controlled demonstration, attendance, feedback and before/after comparison; final report, deck and individual viva notes; alpha release evidence if actually published. | Guide assesses outcomes, individual contributions, maintenance and limitations; unfinished device checks and Play review remain explicit. |

**Total: 8 + 7 + 8 + 7 = 30 hours.** Record actual time separately in `activity-log.csv`. CO1 maps primarily to Week 1; CO2 spans all weeks; CO3 to Weeks 1–2; CO4 to consent/privacy and responsible demonstrations throughout; CO5 to baseline comparisons and refinement in Weeks 2–4; CO6 to contributions, community feedback and viva in all reviews.

## Individual ownership

| Member | Engineering responsibility | Academic evidence responsibility |
|---|---|---|
| Lekhan | Flutter architecture, emergency orchestration, integration and release coordination | Requirements traceability; Week 2 design explanation; final limitations and handover |
| Manas | Native Android triggers, permissions, SMS, location and physical-device validation | Feasibility and resource sheet; Week 3 measured hardware results |
| Vikat | Backend, sync, guardian tracking and access-control verification | Data/privacy design; baseline analysis and test interpretation |
| Hemanth | Supporting UI, accessibility, evidence/assistant workflows and usability testing | Consented survey/demo coordination; feedback analysis, report and presentation |

Assignments are the proposed review split; record actual contributors and reviewer for each change. Every member must explain the full safety workflow and their own work. Do not assign marks from Git commit counts.

## Assessment from the supplied syllabus

| Criterion (pages 7–8) | CIE /50 | SEE /100 | Evidence |
|---|---:|---:|---|
| Problem identification and relevance | 8 | 16 | Community context, field observations, scope |
| Problem statement, engineering approach, innovation and feasibility | 10 | 20 | Alternatives, design, limitations, budget |
| Stakeholder interaction, data collection, analysis and interpretation | 8 | 16 | Consented survey, anonymised data, baseline comparison |
| Documentation, clarity, organisation/technical rigour and problem solving | 10 | 20 | Traceability, reproducible tests, defect/refinement log |
| Communication, presentation and viva | 6 | 12 | Slides, individual explanations, responses |
| Societal benefit, impact and sustainability | 8 | 16 | Measured usability, realistic benefit, maintenance ownership |

Committee assigns marks; templates do not award scores. CIE minimum 20/50; SEE minimum 35/100, scaled to 50; combined CIE + scaled SEE must be at least 40. SEE duration is two hours. Groups have 3–4 students. Maintain individual contributions, peer/guide assessment and evidence annexures (pages 6–9).

## Measurement and truthful reporting

- Survey willing adult participants and guardians about current contact methods, connectivity constraints and ease of setting up an emergency contact. Use participant codes, not names/phone numbers in the repository. Participation is voluntary; avoid collecting trauma narratives.
- Before and after the controlled demonstration, ask participants to identify the SOS action, cancel a test countdown, locate a guardian status and explain internet-versus-cellular requirements. Record successful attempts / total attempts, elapsed seconds and comments. Set a target before collecting data; report sample size and limitations, not unmeasured safety impact.
- Test messages go only to informed test contacts. Do not call emergency numbers, fabricate distress, or publish live location/evidence. Obtain explicit consent before any photos; keep raw consent forms and identifiable field records outside source control and review archives.
- Label entries `planned`, `not run`, `passed`, `failed` or `blocked`. Never fill survey attendance, impact percentages, faculty sign-off, actual hours or Play publication with invented values.

## Revisit a weekly review safely

Use `scripts/review-checkpoint.ps1` from the repository root. Each snapshot includes the **current** eligible tracked and untracked source files, including uncommitted changes. It does not rewrite Git, switch branches or undo work. It excludes ignored files, generated/build folders and sensitive filenames, and rejects several common embedded secret formats. This is a source snapshot, not a complete backup or a guarantee against arbitrary secrets. Review the file manifest before sharing.

```powershell
./scripts/review-checkpoint.ps1 -Action Create -Week 1
./scripts/review-checkpoint.ps1 -Action List
# Use an actual ZIP path returned by Create/List. Destination must not exist.
./scripts/review-checkpoint.ps1 -Action Extract -Archive 'D:/Community Project/Shakti/output/review-checkpoints/<actual-file>.zip' -Destination 'D:/Community Project/reviews/week-1-copy'
```

Create each checkpoint when its review is held, after recording actual results in `review-template.md` copies. If four snapshots are created today from the same completed app, they are **four review views of the same implementation**, not historical weekly progress. The timestamp, Git HEAD and SHA-256 manifest preserve this distinction. For older committed versions, use an isolated Git worktree only after identifying a genuine historical commit; do not backdate commits or reset the working project. Extracted copies require fresh dependency installation and separately supplied local configuration/signing secrets. Archive integrity hashes do not provide authenticity against malicious archive replacement.

The final implementation PDF remains the technical blueprint; this kit adds syllabus traceability. An alpha build or Play Console upload is not evidence of community adoption, nor does a passing unit test prove real SMS delivery.
