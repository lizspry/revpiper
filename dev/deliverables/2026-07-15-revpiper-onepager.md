# revpiper — a spec-driven data pipeline for systematic reviews

*Project one-pager · July 2026*

## What are we doing?

We are building revpiper, an open-source tool that runs the data stage of a systematic review — everything between "we have extracted the data" and "here are the manuscript tables, figures, and dashboards" — from a written, checkable specification rather than by hand. The review team writes down what their data should look like and how it should be handled; the tool executes and verifies everything mechanical, identically every time, and certifies each step. Human decisions stay human, but each one is made once, recorded in a small set of versioned files, and re-applied automatically on every rerun. The tool is simple and functional at its core and flexible in its customisability: teams that need a check or an output we haven't built can add their own, recorded and versioned through the same mechanism.

## Why does it matter?

The data stage of our reviews is currently craftwork. Extraction lives in Excel, cleaning in one-way Stata scripts, recoding in further spreadsheets. Judgment and mechanics are fused and scattered: a cleaning decision sits at line 340 of a do-file, a recode is an untracked cell edit, a mapping decision lives in someone's memory. Nobody can say afterwards exactly what was decided where, results are effectively irreproducible, and an update costs nearly as much as the original review. This is about to bind much harder: systematic reviews go out of date quickly — an estimated 23% are substantively outdated within two years of publication [1] — and living reviews, which update as evidence arrives, are the field's response, yet evidence synthesis remains time-intensive and heavily manual, typically taking months or years [2].

The emerging AI tools do not solve this. A 2026 scoping review mapped 388 AI tools for evidence synthesis [2]; they target the judgment steps — screening, extraction, risk-of-bias assessment — exactly where the joint position of Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence, and the RAISE recommendations it endorses, require human oversight and keep the synthesist accountable, including for the decision to use AI at all [3,4], and where the current assessment of large language models is "promising, but not yet ready for use" [5]. In living evidence synthesis specifically, AI tools concentrate on extraction and risk of bias, with almost none serving the update phase [6]. None of them addresses the layer where our problems actually live — the post-extraction data pipeline: searching the literature and the open-source landscape, we found no existing free, open-source tool that makes this stage of a review specified, deterministic, auditable, and rerunnable. And RAISE's tool-selection guidance draws its lines exactly where this design stands [7]: rule-based tools — dedicated software packages — are classified acceptable for use in data and quantitative-analysis tasks; LLM-drafted code may be used where a human reviews and verifies it; and generative AI must not be used to synthesise results across studies. revpiper is the first category by construction, its future AI-assisted steps take the shape of the second, and nothing in it touches the third.

revpiper's design move is to separate judgment from mechanics. Everything checkable becomes deterministic software. Everything requiring judgment stays human but moves into named, versioned homes: the data dictionaries (what the data should be), the mapping specifications (how raw collected data becomes the derived form we analyse), and a corrections file for the case-by-case cleaning calls no automated check can make. The judgment surface of a review becomes small, legible, and auditable — you can point at every human decision, where it lives, when it was made, and what it says. That single property is what peer scrutiny needs, and what safe delegation to AI will need.

This is where best-practice science and modern software engineering converge, and the design deliberately merges them. Reviews already demand prespecified methods and transparent reporting [8]; software engineering enforces exactly that structure — specification up front, automated verification, version control, human review at checkpoints. In revpiper the scientific artifacts become machine-operative: the data dictionary does not describe the data, it validates the data; the certified specification is simultaneously a timestamped prespecification (a research credential) and the acceptance criteria for execution (an engineering artifact). And with end-to-end AI review systems already in validation [9], the strategic question is no longer whether AI will assist reviews but whether our workflows can receive AI output safely — with correctness stated in advance, deterministic checks, human gates, and a full audit trail. This workflow can, in two senses. Inward: each future AI capability becomes an incremental, governable swap at an existing checkpoint. Outward: the pipeline's deterministic, verified functions are building blocks — they can be integrated into, adapted for, or inform new AI-led review workflows, including those built with collaborators. Meanwhile the same structure pays for itself today, with no AI dependency, through reproducibility, systematic error-surfacing, and cheap updates.

There is also an organisational reality to be honest about: like most research institutions, we do not yet have enterprise agentic AI infrastructure, nor an established training base for heavier AI use — so greater AI enablement is not something we could responsibly switch on today even if the tools were ready. This approach requires neither. It is fully usable now with no AI at all, and it builds — review by review, in ordinary work — the workflow structure and staff capability that will make later AI enablement sensible and safe when the technology, the governance, and our infrastructure align.

## What does success look like?

Point A: one-off, manual, irreproducible reviews that cannot affordably be updated. Point B: reviews run from certified specifications — methods certified before data collection, a certified clean dataset as the analysis handoff, updates in hours rather than weeks, and every human decision on the record.

## Measurement

- Internal implementation in three or more review teams, including flagship living reviews (deployment record; update time, baseline versus pilot, as the concrete supporting measure).
- Delivery of a publicly available package (GitHub-installable v1 release).
- Internal upskilling in the machinery of AI-ready workflows: staff across pilot teams working hands-on with specification, versioning, and checkpoint review, and the pattern — separate judgment from mechanics; record judgments in explicit, versioned artifacts; make mechanics deterministic and verified — documented for reuse in other institute workflows.

## Deliverables

v1: the spec, load, and process steps (through the certified clean dataset), a ready-to-run project scaffold with a complete worked example, and task-oriented guides. v2: derived variables and transformations. v3: the present step — standard review tables and figures for publication, plus interactive, user-facing dashboards, all generated and updated from the same specs; users will be able to specify which outputs they want, in what order, and with what variables and headers (exact scope to be confirmed against review needs and feasibility). Alongside all of it: pilots with the collaborating review teams, feeding codesign iterations.

## Status (July 2026)

Design specification complete and signed off. Phase 1 — spec certification — is built and tested (test-driven throughout, ~380 automated tests, clean quality gates) and heading to review. The load and process steps are next. Three review teams are engaged at the spec design stage.

## In and out of scope

**In:** the data pipeline from extracted data to outputs, including interactive dashboards at the present step; umbrella reviews (one pilot review is an umbrella review); user-added custom checks and outputs; the project scaffold; pilots and codesign. **Out:** searching, screening, and extraction judgment (existing tools and human judgment stay); any AI automation of review judgments.

## Risks and flags

- The specification language may not express every real review — the central design risk, burned down early by a full dress rehearsal reproducing a completed review end to end.
- The workflow and mental-model shift is real: teams restructure how they think about the work, from redoing steps to specifying them once. Mitigated by working templates, a runnable example project, pilots, and codesign.
- The language and tools shift is separate and also real: R and GitHub are minimally familiar to some staff and new to others. Mitigated by the modify-a-working-template design, worked examples, and pilot-team support.
- Single-developer scope and maintenance load — mitigated by a deliberately small user-facing surface and heavy automated testing; by the phased releases, each independently useful; by usability and testing support from pilot teams and collaborators; and, worst case, by the tool delivering value even if not all phases complete. Flagged as a live feasibility question.
- The AI landscape will keep moving — mitigated by design: the tool is useful with no AI dependency at all.

## Requirements and dependencies

Pilot teams' time for codesign; R and GitHub access on staff machines; leadership support for the workflow change. Software-engineering collaboration is welcome and valuable but not a requirement. Development touches no participant data.

## People and engagement

Three collaborating review teams (two engaging before data collection, one retrofitting a completed collection); systematic review and data science hub leadership; software-engineering collaborator(s).

---

*AI-use disclosure: this document and the revpiper software are developed with AI assistance (Claude Code, Anthropic) under the project lead's direction and review; cited claims were verified against sources at drafting time, and the project repository's git history records the full development trail, consistent with TRIPOD-LLM disclosure practice.*

**References**

1. Elliott JH, et al. Living systematic reviews: an emerging opportunity to narrow the evidence-practice gap. *PLoS Medicine* (2014). doi:10.1371/journal.pmed.1001603
2. Sousa MSA, et al. The landscape of artificial intelligence tools and platforms for evidence synthesis: a scoping review. *Systematic Reviews* (2026). doi:10.1186/s13643-025-02842-y
3. Position statement on artificial intelligence (AI) use in evidence synthesis across Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence. *Campbell Systematic Reviews* (2025). doi:10.1002/cl2.70074
4. Thomas J, Hair K, Noel-Storr A, et al. Responsible use of AI in evidence Synthesis (RAISE): recommendations for practice (version 3, updated 13 March 2026). OSF (2026). doi:10.17605/OSF.IO/FWAUD
5. Lieberum J-L, et al. Large language models for conducting systematic reviews: on the rise, but not yet ready for use — a scoping review. medRxiv preprint (2024). doi:10.1101/2024.12.19.24319326
6. Song X, et al. The phases of living evidence synthesis using AI. *Journal of Medical Internet Research* (2026). doi:10.2196/76130
7. Thomas J, Hair K, Noel-Storr A, et al. Responsible use of AI in evidence Synthesis (RAISE): selecting and using AI evidence synthesis tools (version 3.1, updated 13 March 2026). OSF (2026). doi:10.17605/OSF.IO/FWAUD
8. Page MJ, et al. The PRISMA 2020 statement: an updated guideline for reporting systematic reviews. *BMJ* (2021). doi:10.1136/bmj.n71
9. Cao C, et al. Automation of systematic reviews with large language models (otto-SR). medRxiv preprint (2025). doi:10.1101/2025.06.13.25329541
