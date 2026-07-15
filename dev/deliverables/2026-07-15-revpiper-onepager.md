# revpiper — a spec-driven data pipeline for systematic reviews

*Project one-pager · July 2026*

## What are we doing?

We are building revpiper, an open-source tool that runs the data stage of a systematic review — everything between "we have extracted the data" and "here are the manuscript tables and figures" — from a written, checkable specification rather than by hand. The review team writes down what their data should look like and how it should be handled; the tool executes and verifies everything mechanical, identically every time, and certifies each step. Human decisions stay human, but each one is made once, recorded in a small set of versioned files, and re-applied automatically on every rerun.

## Why does it matter?

The data stage of our reviews is currently craftwork. Extraction lives in Excel, cleaning in one-way Stata scripts, recoding in further spreadsheets. Judgment and mechanics are fused and scattered: a cleaning decision sits at line 340 of a do-file, a recode is an untracked cell edit, a mapping decision lives in someone's memory. Nobody can say afterwards exactly what was decided where, results are effectively irreproducible, and an update costs nearly as much as the original review. This is about to bind much harder: systematic reviews go out of date quickly — an estimated 23% are substantively outdated within two years of publication [1] — and living reviews, which update as evidence arrives, are the field's response but are more costly than standard reviews under current workflows, with review teams themselves calling for technology to reduce the workload [2].

The emerging AI tools do not solve this. They target the judgment steps — screening, extraction, risk-of-bias assessment — exactly where the joint position of Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence requires human oversight and keeps the synthesist ultimately responsible [3], and where the current assessment of large language models is "promising, but not yet ready for use" [4]. None of them addresses the layer where our problems actually live. We found no existing tool that makes the review data pipeline specified, deterministic, auditable, and rerunnable.

revpiper's design move is to separate judgment from mechanics. Everything checkable becomes deterministic software. Everything requiring judgment stays human but moves into named, versioned homes: the data dictionaries (what the data should be), the mapping specifications (how raw collected data becomes the derived form we analyse), and a corrections file for the case-by-case cleaning calls no automated check can make. The judgment surface of a review becomes small, legible, and auditable — you can point at every human decision, where it lives, when it was made, and what it says. That single property is what peer scrutiny needs, and what safe delegation to AI will need.

This is where best-practice science and modern software engineering converge, and the design deliberately merges them. Reviews already demand prespecified methods and transparent reporting [5]; software engineering enforces exactly that structure — specification up front, automated verification, version control, human review at checkpoints. In revpiper the scientific artifacts become machine-operative: the data dictionary does not describe the data, it validates the data; the certified specification is simultaneously a timestamped prespecification (a research credential) and the acceptance criteria for execution (an engineering artifact). And with end-to-end AI review systems already in validation [6], the strategic question is no longer whether AI will assist reviews but whether our workflows can receive AI output safely — with correctness stated in advance, deterministic checks, human gates, and a full audit trail. This workflow can: each future AI capability becomes an incremental, governable swap at an existing checkpoint. Meanwhile the same structure pays for itself today, with no AI dependency, through reproducibility, systematic error-surfacing, and cheap updates.

## What does success look like?

Point A: one-off, manual, irreproducible reviews that cannot affordably be updated. Point B: reviews run from certified specifications — methods certified before data collection, a certified clean dataset as the analysis handoff, updates in hours rather than weeks, and every human decision on the record.

## Measurement

- Internal implementation in three or more review teams, including flagship living reviews (deployment record; update time, baseline versus pilot, as the concrete supporting measure).
- Delivery of a publicly available package (GitHub-installable v1 release).
- Internal upskilling in the machinery of AI-ready workflows: staff across pilot teams working hands-on with specification, versioning, and checkpoint review, and the pattern — separate judgment from mechanics; record judgments in explicit, versioned artifacts; make mechanics deterministic and verified — documented for reuse in other institute workflows.

## Deliverables

v1: the spec, load, and process steps (through the certified clean dataset), a ready-to-run project scaffold with a complete worked example, and task-oriented guides. v2: derived variables and transformations. v3: standard review tables and figures. Alongside all of it: pilots with the collaborating review teams, feeding codesign iterations.

## Status (July 2026)

Design specification complete and signed off. Phase 1 — spec certification — is built and tested (test-driven throughout, ~380 automated tests, clean quality gates) and heading to review. The load and process steps are next. Three review teams are engaged at the spec design stage.

## In and out of scope

**In:** the data pipeline from extracted data to outputs; the project scaffold; pilots and codesign. **Out:** searching, screening, and extraction judgment (existing tools and human judgment stay); any AI automation of review judgments; interactive dashboards (deferred); umbrella and scoping reviews (v1).

## Risks and flags

- The specification language may not express every real review — the central design risk, burned down early by a full dress rehearsal reproducing a completed review end to end.
- The workflow shift is real: a new mental model, and versioning is new to most users. Mitigated by working templates, a runnable example project, pilots, and codesign.
- Single-developer scope and maintenance load — mitigated by a deliberately small user-facing surface and heavy automated testing; flagged as a live feasibility question.
- The AI landscape will keep moving — mitigated by design: the tool is useful with no AI dependency at all.

## Requirements and dependencies

Pilot teams' time for codesign; software-engineering collaboration; R and GitHub access on staff machines; leadership support for the workflow change. Development touches no participant data.

## People and engagement

Three collaborating review teams (two engaging before data collection, one retrofitting a completed collection); systematic review and data science hub leadership; software-engineering collaborator(s).

---

*AI-use disclosure: this document and the revpiper software are developed with AI assistance (Claude Code, Anthropic) under the project lead's direction and review; cited claims were verified against sources at drafting time, and the project repository's git history records the full development trail, consistent with TRIPOD-LLM disclosure practice.*

**References**

1. Elliott JH, et al. Living systematic reviews: an emerging opportunity to narrow the evidence-practice gap. *PLoS Medicine* (2014). doi:10.1371/journal.pmed.1001603
2. Millard T, et al. Feasibility and acceptability of living systematic reviews: results from a mixed-methods evaluation. *Systematic Reviews* (2019). doi:10.1186/s13643-019-1248-5
3. Position statement on artificial intelligence (AI) use in evidence synthesis across Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence. *Campbell Systematic Reviews* (2025). doi:10.1002/cl2.70074
4. Lieberum J-L, et al. Large language models for conducting systematic reviews: on the rise, but not yet ready for use — a scoping review. medRxiv preprint (2024). doi:10.1101/2024.12.19.24319326
5. Page MJ, et al. The PRISMA 2020 statement: an updated guideline for reporting systematic reviews. *BMJ* (2021). doi:10.1136/bmj.n71
6. Cao C, et al. Automation of systematic reviews with large language models (otto-SR). medRxiv preprint (2025). doi:10.1101/2025.06.13.25329541
