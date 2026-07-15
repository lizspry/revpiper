# revpiper for review teams — what changes, and what you get

*July 2026*

## Where you are now

You know this workflow: extraction in an Excel sheet, cleaning in a long Stata do-file, recodes patched in another spreadsheet, tables assembled by hand. It works — but every upstream change means redoing everything downstream; coming back after months (or handing over) means reconstructing what was decided, where, and why; and an update costs nearly as much as the original review. None of this is a failing of any team. There has simply been no infrastructure for this part of the work.

## What's changing around reviews

Two pressures are rising at once. Living reviews — updated as new evidence arrives — are becoming the expectation, while evidence synthesis remains time-intensive and heavily manual, typically taking months or years [1]. And the wave of AI tools now arriving will not rescue this part of the work: they concentrate primarily on searching, screening, and extraction, with almost none serving the stage from extracted data onward, or updates [2]. Even where AI can help, its use is properly bounded — the joint position of Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence, with the RAISE recommendations it endorses, requires human oversight, with the synthesist accountable, including for the decision to use AI at all [3,4] — and our organisation does not yet have the infrastructure or training base for agentic AI use in any case.

So what this stage of reviewing needs now is not AI. It is working infrastructure: the process written down, checked automatically, and rerunnable. No existing free, open-source tool provides that; it pays for itself immediately; and — as the second-last section explains — it is also exactly the foundation that safe AI use will later need.

## What you'll actually get

One integrated pipeline, in one place. Your data flows from raw extracted input all the way to tables, figures, and dashboards inside a single project — no more carrying results by hand between an extraction sheet, a cleaning script, a recoding spreadsheet, and a document, and no more wondering which version of which file is current. The division of labour is the point, so here it is explicitly.

**What you write** — your judgment, in a small set of plain-text files, and nothing else:

- **Data dictionaries** — what each table and variable should be: names, types, valid values, units. If you engage before data collection, the dictionary doubles as the source of truth for your extraction instrument.
- **A joins and mapping specification** — how your tables connect, and how the raw collected data maps to the derived variables you analyse and report.
- **A corrections file** — the case-by-case cleaning calls no automated check can make, each recorded once, with its reason.
- **A short run script** — a few lines calling the package to run the steps: import, clean, derive, and present your data, to your specifications.

**What you never write** — the package's job, all of it built and tested once, centrally:

- validation of your specs themselves (so errors are caught before any data is touched);
- automated cleaning and normalisation of the machine-fixable issues;
- checking and reporting at every step, with each failure naming the file, column, row, and fix location;
- certification of the specs and the cleaned dataset;
- and all the machinery that generates your tables, figures, and dashboards to your specification — which outputs, in what order, with what variables and headers (exact scope to be confirmed against review needs and feasibility) — for written documents and interactively, regenerating automatically when your review updates.

**What you can add** — if your review needs something the package doesn't cover: your own checks, or your own table or figure code, slotted in and recorded and versioned like everything else. Simple and functional at its core, flexible in its customisability.

Nothing is locked in: prespecifying your dictionary does not freeze it. You can update and edit the dictionary and specs at any time, as piloting, extraction changes, or new thinking demand; every change is version-controlled, so the record shows what changed and when, and the pipeline re-checks everything against the new version. The specification evolves with your review. Each step checks your files and data against it and produces a report; the spec step's certificate is a timestamped prespecification you can point to before data collection begins.

## Where your time goes, and where it doesn't go

Time in: authoring the dictionaries up front; recording cleaning decisions as they arise; reading a short report at each checkpoint. Time out: no manual re-cleaning, no re-assembly, no hunting for where a number came from. Checks run in seconds, and every failure names the file, the column, the row, and where to fix it.

## The payoff when things change, rerunning your review

New search results arrive. You drop the updated extraction file in and run. Every decision you recorded re-applies automatically — and any that no longer match the data flag themselves by name rather than failing silently. The report and the file history show exactly what changed. You review and decide; you do not redo.

## Where AI can slot in, when it's ready

You have now seen the whole shape: instructions written down (your dictionary and specs), work checked automatically against them (the pipeline), and your review at defined points (the step reports). Those three things are exactly what safe AI use requires. Think of an AI assistant as a very fast new team member: you would give a new colleague written instructions for the task, check their work against them, and review it before accepting it. Today's typical workflow has none of that written down — what correct looks like lives in people's heads — so using AI means trusting it. In this workflow, an AI's work gets checked exactly like anyone else's.

The RAISE guidance already draws the lines concretely [5]: rules-based tools — packages like this one — are classified acceptable for use in data and analysis tasks; AI-drafted code or specifications may be used where a human reviews and verifies them; and generative AI must not be used to synthesise results across studies. That synthesis judgment stays yours, full stop.

One illustration of the middle category: an assistant drafts your data dictionary from your protocol. You read a short, plain-text draft, accept or edit it, and the pipeline audits and certifies it — nothing enters the dataset unverified, and your judgment stays the gate. The same pattern extends wherever capability and governance mature: drafting corrections for flagged findings, triaging an update. Because the checkpoints already exist, adopting AI assistance becomes a governed swap at a gate you already operate — not a rebuild of how you work.

## What we're asking of you

Use it on your review as it develops, and tell us where it fights you. The design assumes piloting will change it — that is the point of engaging now, and your review shapes the tool as much as the tool serves your review.

---

*AI-use disclosure: this document and the revpiper software are developed with AI assistance (Claude Code, Anthropic) under the project lead's direction and review; cited claims were verified against sources at drafting time, consistent with TRIPOD-LLM disclosure practice.*

**References**

1. Sousa MSA, et al. The landscape of artificial intelligence tools and platforms for evidence synthesis: a scoping review. *Systematic Reviews* (2026). doi:10.1186/s13643-025-02842-y
2. Song X, et al. The phases of living evidence synthesis using AI. *Journal of Medical Internet Research* (2026). doi:10.2196/76130
3. Position statement on artificial intelligence (AI) use in evidence synthesis across Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence. *Campbell Systematic Reviews* (2025). doi:10.1002/cl2.70074
4. Thomas J, Hair K, Noel-Storr A, et al. Responsible use of AI in evidence Synthesis (RAISE): recommendations for practice (version 3, updated 13 March 2026). OSF (2026). doi:10.17605/OSF.IO/FWAUD
5. Thomas J, Hair K, Noel-Storr A, et al. Responsible use of AI in evidence Synthesis (RAISE): selecting and using AI evidence synthesis tools (version 3.1, updated 13 March 2026). OSF (2026). doi:10.17605/OSF.IO/FWAUD
