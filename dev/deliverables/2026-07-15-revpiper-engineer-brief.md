# revpiper — technical brief for engineering collaborators

*July 2026 · companion to the shared project one-pager; full design in dev/superpowers/specs/2026-07-07-revpiper-design.md*

## The domain, in one paragraph

A systematic review answers a health question by finding and synthesising every relevant study, under a predefined protocol: exhaustive search → screening → structured extraction of each study's data → synthesis (typically meta-analysis) → publication. A *living* review repeats the cycle as new evidence arrives. The data stage — extracted data through cleaned, analysable dataset to tables and figures — is, in engineering terms, an ETL pipeline currently frequently executed manually: spreadsheets as the database, linear scripts without version control or tests, manual table and figure creation and/or formatting, no idempotent rerun. Critically, judgment (what the data should be) and mechanics (making it so) are interleaved in the same artifacts, so nothing can be rerun without redoing the judgment.

## The design move

Separate them. Mechanics become a deterministic pipeline; judgment is relocated into declarative, versioned artifacts — YAML specifications plus an auditable corrections table. The pipeline validates everything against the spec; what cannot be decided algorithmically routes to the corrections file, which is re-applied on every run, with stale entries failing loudly by name. Each pipeline step exposes an `audit` action (check, report, certify — never aborts, never mutates state) and a `run` action (execute, abort on problems, pointing at the audit).

## Old workflow → new workflow

| Current practice | Failure mode | Step | Functions / artifacts |
|---|---|---|---|
| Extraction sheets in Excel | no schema; silent drift | **spec** | `rev_spec_audit()`, `rev_spec_run()`; dictionaries + joins in YAML; certified spec report |
| Ad-hoc file wrangling | irreproducible imports | **load** (next phase) | readers + structural checks; load report |
| Manual Stata cleaning; recodes in spreadsheets | untracked judgment; one-way scripts | **process** (next phase) | standardise → correct → validate → join; a corrections table as the audited override channel; certified clean dataset |
| Hand-derived variables | copy-paste drift | **transform** (v2) | declared derivations checked against a derived dictionary |
| Hand-built tables and figures | rework on every change | **present** (v3) | declarative output spec behind a hard data contract; prepared content objects feed N renderers — static publication outputs and interactive dashboards regenerate from the same specs |
| Update = redo by hand | unaffordable reruns | **update** | `rev_run(through =)` — steps are prefixes of one deterministic run from the raw files, so nothing stale passes between them |

## Key decisions and rationale

Full decisions log: design spec §9.

- **R, not Python.** The users' ecosystem: meta-analysis tooling and — decisive — the users' ability to read, run, and extend the code live in R.
- **A package, not scripts.** Logic versioned, tested, and centrally fixable. Each review scaffolds (`rev_project()`) as its own git repository with an renv lockfile: every review version-frozen and reproducible.
- **Declarative YAML specs, not user code.** Single source of truth; auditable; AI-assist-friendly plain text; matches the users' capability floor (baseline R, no software background).
- **Own schema grammar, not an external data-dictionary standard.** The schema itself is data, held in single-source registries (`inst/schema/fields.yaml`, `checks.yaml`); avoids depending on an immature external standard while staying vocabulary-aligned for later convergence.
- **Per-step audit/run pairs** (`rev_<step>_<action>` grammar). Each step is a standalone unit of work with its own verification, report and certificate, and fix surface; check commands never touch pipeline state.
- **User extension surfaces, same pattern.** Users are not restricted to the shipped behaviour: custom readers, derivations, checks, and output layouts are added as declared, versioned artifacts the pipeline executes — extensions live in judgment artifacts, not forks. Simple and functional at the core, flexible in its customisability.
- **Deterministic core, AI at the edges.** The pipeline contains no AI. It is the verification harness that makes future AI contributions checkable — the structure that current evidence-synthesis governance (the Cochrane/Campbell/JBI/CEE position statement and the RAISE recommendations [1,2]) effectively requires, and that end-to-end LLM review prototypes [3] will need to land in before institutional adoption is defensible. The dependency also runs outward: the deterministic, verified functions are building blocks that can be integrated into or inform new AI-led review workflows, including collaborator-led ones.

## Engineering practice and status

TDD throughout (~380 tests); lint gate; clean R CMD check; protected main, feature branches, PR review; releases mapped to pipeline steps (v1 = spec + load + process, v2 = transform, v3 = present). Phase 1 (spec certification) is complete and heading to PR; load and process are next. The headline risk is spec-language expressiveness against real reviews, burned down early by a dress rehearsal reproducing a completed review end to end against its published outputs.

## Where you could contribute

There is no predefined role and no expectation — engagement if and as it suits you. What could help most, if interested but with limited time, is advisory input: someone to help think through and pressure-test the big calls as the pipeline grows — architecture, package development and development process, product and code design. The door is open to hands-on work if it appeals. And there is a substantive draw: this project is a working instance of the central problem in applied agentic engineering — restructuring an expert human workflow into machine-checkable versus human-judgment steps, with deterministic verification and gated checkpoints — applied to a high-stakes scientific domain. For anyone interested in AI-enabled review workflows, it is hands-on insight into the methods and workflow restructuring they require.

---

*AI-use disclosure: this document and the revpiper software are developed with AI assistance (Claude Code, Anthropic) under the project lead's direction and review; the repository's git history records the full development trail, consistent with TRIPOD-LLM disclosure practice.*

**References**

1. Position statement on artificial intelligence (AI) use in evidence synthesis across Cochrane, the Campbell Collaboration, JBI, and the Collaboration for Environmental Evidence. *Campbell Systematic Reviews* (2025). doi:10.1002/cl2.70074
2. Thomas J, Hair K, Noel-Storr A, et al. Responsible use of AI in evidence Synthesis (RAISE): recommendations for practice (version 3, updated 13 March 2026). OSF (2026). doi:10.17605/OSF.IO/FWAUD
3. Cao C, et al. Automation of systematic reviews with large language models (otto-SR). medRxiv preprint (2025). doi:10.1101/2025.06.13.25329541
