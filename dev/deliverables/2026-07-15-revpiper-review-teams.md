# revpiper for review teams — what changes, and what you get

*July 2026*

## Where you are now

You know this workflow: extraction in an Excel sheet, cleaning in a long Stata do-file, recodes patched in another spreadsheet, tables assembled by hand. It works — but every upstream change means redoing everything downstream; coming back after months (or handing over) means reconstructing what was decided, where, and why; and an update costs nearly as much as the original review. None of this is a failing of any team. There has simply been no infrastructure for this part of the work.

## The turning point

Living reviews — updated as new evidence arrives — are becoming the expectation, yet evidence synthesis remains time-intensive and heavily manual, typically taking months or years [1]. AI tools are arriving fast, but they concentrate on screening, extraction, and risk of bias, with almost none serving the stage this tool covers — from extracted data onward — and almost none serving updates [2]. The joint position of Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence, with the RAISE recommendations it endorses, requires human oversight, with the synthesist accountable — including for the decision to use AI at all [3,4]. RAISE's tool-selection guidance is already concrete about where the lines sit [5]: rules-based tools — packages like this one — are classified acceptable for use in data and analysis tasks; AI-drafted code or specifications may be used where a human reviews and verifies them; and generative AI must not be used to synthesise results across studies. That synthesis judgment stays yours, full stop.

Why does this workflow prepare you for AI? Think of an AI assistant as a very fast new team member. To use one safely you need the same three things you would give a new colleague: written instructions saying exactly what the task is and what a correct result looks like; a way of checking their work against those instructions, ideally automatic; and agreed points where you personally review before anything is accepted. Today's typical review workflow has none of these written down — what correct looks like lives in people's heads, so using AI means trusting it. This tool's workflow is those three things: the dictionary and specs are the written instructions, the pipeline's checks are the automatic checking, and the step reports are your review points. Build them and they pay for themselves immediately on human work; and if, later, an AI drafts something, its work gets checked exactly like anyone else's. Our organisation does not yet have the infrastructure or training base for heavier AI use anyway — a further reason to build this way now: it needs no AI to be useful, and it grows the skills and structure for when the technology, the rules, and our infrastructure are all ready.

## What you'll actually get

One integrated pipeline, in one place. Your data flows from raw extracted input all the way to tables, figures, and dashboards inside a single project — no more carrying results by hand between an extraction sheet, a cleaning script, a recoding spreadsheet, and a document, and no more wondering which version of which file is current. Concretely: a ready-to-run review project, created for you by the tool, built around a small set of plain-text files you edit:

- **Data dictionaries** — what each table and variable should be: names, types, valid values, units. If you engage before data collection, the dictionary doubles as the source of truth for your extraction instrument.
- **A joins and mapping specification** — how your tables connect, and how the raw collected data maps to the derived variables you analyse and report.
- **A corrections file** — the case-by-case cleaning calls no automated check can make, each recorded once, with its reason.
- **A short run script** — the whole pipeline, a few lines.

Nothing is locked in — this matters, so plainly: prespecifying your dictionary does not freeze it. You can update and edit the dictionary and specs at any time, as piloting, extraction changes, or new thinking demand; every change is version-controlled, so the record shows what changed and when, and the pipeline re-checks everything against the new version. The specification evolves with your review. Each step checks your files and data against it and produces a report; the spec step's certificate is a timestamped prespecification you can point to before data collection begins. (The certificate and a draft generator that writes a starter dictionary from your data are coming in the next releases.)

And it is not a straitjacket in the other direction either: the tool is simple and functional at its core, flexible in its customisability. If your review needs a check we haven't built, or a table or figure laid out differently, you can add your own — recorded and versioned the same way as everything else. At the presentation end you will be able to specify which tables, figures, and dashboards you want, in what order, and with what variables and headers (exact scope to be confirmed against review needs and feasibility) — including interactive dashboards that regenerate automatically when your review updates, alongside the static outputs for publication.

## Where your time goes — and where it stops going

Time in: authoring the dictionary up front; recording cleaning and mapping decisions as they arise; reading a short report at each checkpoint. Time out: no manual re-cleaning, no re-assembly, no hunting for where a number came from. Checks run in seconds, and every failure names the file, the column, the row, and where to fix it.

## The payoff when things change

New search results arrive. You drop the updated extraction file in and run. Every decision you recorded re-applies automatically — and any that no longer match the data flag themselves by name rather than failing silently. The report and the file history show exactly what changed. You review and decide; you do not redo.

## Where AI can slot in, when it's ready

One illustration: an assistant drafts your data dictionary from your protocol. You read a short, plain-text draft, accept or edit it, and the pipeline audits and certifies it — nothing enters the dataset unverified, and your judgment stays the gate. This is exactly the pattern RAISE classifies as legitimate — AI-drafted material with human verification required [5] — and it extends wherever capability and governance mature: drafting corrections for flagged findings, triaging an update. Because the checkpoints already exist, adopting AI assistance becomes a governed swap at a gate you already operate — not a rebuild of how you work.

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
