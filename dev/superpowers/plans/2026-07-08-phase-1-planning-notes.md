# Phase 1 planning — session notes (running)

- **Started:** 2026-07-08, Liz + Claude (sandbox sbx-20260708-1950-revpiper)
- **Status:** IN PROGRESS — interim notes; nothing here is signed off unless marked DECIDED.
- **Purpose:** working record for the Phase 1 planning session (spec §8.4); feeds spec §8.2
  amendments + the Phase 1 implementation plan. Liz's time-box: session may pause and resume.

## Scope of Phase 1 (from spec §8.4)

Spec machinery + stages 1–3: dictionary parsing/validation, assemble, clean, validate,
findings. Owned items to resolve in this planning: extraction-tool export formats;
data-dict format-vs-CLI; check-type→routing table (stage 3); documentation templates
(during implementation, with real functions); pkgdown rendered-.md set (queued from
Phase 0: default renders ALL top-level .md incl. CLAUDE.md → unlinked CLAUDE.html on
the public site; choose the set deliberately).

## Investigation 1 — extraction-tool export formats

Evidence: real files provided by Liz in `<host-repo>/working/refs/` (read-only mount):
Covidence all-data CSV export (real review, 3 studies), Excel extraction workbook
(family-comparison / negative-control design), DistillerSR white-paper research notes
(no real export available — header-level details flagged there as reconstructed, not
verified).

### Findings: Covidence (`review_154081_extracted_all_data_csv_*.csv`, 15×79)

- **Row unit = study × extraction form × reviewer.** Verified: within-study rows vary
  only in Form/Reviewer/Status for 2 of 3 studies; the third (9 rows) also varies in
  content (Methods/Population/Intervention) — i.e. **pre-consensus dual extraction**
  visible in the export.
- **Outcomes and timepoints fan across COLUMNS, not rows**: named blocks
  `Outcome details: <outcome> - <field>`, `Outcome details: <outcome> (<timepoint>)
  <field>`, `Result data: <outcome> (<timepoint>) <stat>`. Reaching one-row-per-estimate
  requires a **pivot driven by column-name pattern parsing** (section prefix, outcome
  name, optional timepoint parenthetical, field suffix).
- Study-level fields repeat down rows (54/79 columns constant within multi-row studies)
  — consistent with spec §3.2's repetition-as-transcription-check.

### Findings: Excel workbook (`Family_comparison_Extraction_rerun1.xlsx`)

- **Multi-row banded headers** (row 1: Study/Exposure/Outcome/Results bands; row 2:
  Unadjusted/Adjusted/Adjusted 2/Adjusted 3 sub-bands under Results; row 3: real column
  names). Assembly needs a header-declaration (header rows span, band fill) to ingest
  this shape.
- Adjustment levels appear as **column bands within one row** — matches spec §3.2's
  preserved exception (multiple adjustment levels in one row; selection is derivation
  logic).
- **Auxiliary sheets**: `Acronym list` (lookup/reference table), `Drop down list`
  (controlled vocabularies — an embryonic data dictionary living as Excel validation
  lists; natural future seed for codebook→YAML, v1.x), `RoB` (native-shape aux input,
  as spec §3.2 anticipated).
- Liz: designs like this include negative-control rows (e.g. maternal vs paternal
  exposure extracted separately, then compared) and per-design extraction sheets within
  one review.

### Findings: DistillerSR (documentation-level only; no specimen)

- Three export shapes: (1) one row per reference (× reviewer unless "Merge Data by
  Reference"); (2) **vertical/hierarchical: one row per leaf instance, parent values
  repeated** — natively revpiper's canonical shape; (3) horizontal flat: repeating
  instances fan across columns, **column count varies by study** (their own docs call
  it difficult; needs manual reconfiguration).
- Gaps (flagged honestly in the notes doc): exact header naming conventions unverified
  without a real export. Treat DistillerSR specifics as **assumption, not fact**, in
  the vignette until a specimen exists.

### Emerging implications for stage-1 design (NOT yet decided)

1. Canonical shape (one row per estimate, study-level repeated) is confirmed as the
   right *target*: DistillerSR-vertical emits it natively; Excel practice approximates
   it; Covidence requires an outcome-block pivot.
2. The assembly grammar needs, concretely: (a) column-block pivot with name-pattern
   parsing (Covidence); (b) multi-row banded header declaration (Excel); (c) native-
   shape aux inputs with declared reshape+join (already in spec).
3. **Boundary question raised (→ Liz):** raw exports can be pre-consensus (multiple
   reviewers/forms per study). Is v1's input the extraction-final dataset (consensus
   resolved upstream), or does the pipeline ingest pre-consensus exports (reviewer as a
   declared level; agreement as a generated consistency check; adjudication itself
   stays human/corrections)?

## Investigation 2 — data-dict: format vs CLI

Evidence: shallow clone of github.com/tidyverse/data-dict (schema.yaml, site/spec.md,
site/validation.md), inspected 2026-07-08. State: spec v0.1.0, pre-1.0 with breaking
changes expected; last commit 2026-07-07 (actively developed).

Findings:

- **Closed schema everywhere** (deliberate while pre-1.0): unknown keys are rejected,
  so revpiper's semantics (roles, levels+keys, missing codes, assembly declarations —
  none expressible in data-dict) cannot live inside a conformant file.
- **Data validation reads Parquet sources only**; revpiper's world is CSV/Excel, so the
  Rust CLI could not validate our users' data even if shipped. CLI is moot user-side
  AND dev-side today.
- **Excellent design material regardless**: type vocabulary (`number(id|ordinal|
  quantity)`, `enum`+`values`, `range` vs `examples`), the three-level validation
  architecture (spec → metadata → data, each subsuming the last), stable check codes
  (24 today: S01–S18, M01–M05, D01), error-vs-warning as urgency, and the "when
  dictionary and data disagree we can't tell which side is wrong" framing that matches
  our routing doctrine.

## Decisions

1. **DECIDED (Liz, 2026-07-08) — consensus boundary:** v1's documented input contract
   is the extraction-final dataset (formal tools typically resolve discrepancies
   upstream). Reviewer is not a built-in concept; a reviewer column can be declared as
   a level like any other, so declared-level consistency checks surface disagreements
   as findings for free when a user feeds pre-consensus data. Adjudication itself stays
   human. Design intent to carry forward: the check/correct process should accommodate
   discrepancy-flagging gracefully (mechanism worked out in design, not pre-committed).

2. **DECIDED (Liz, 2026-07-08) — data-dict relationship:** revpiper defines its own
   dictionary schema (closed, with did-you-mean spec errors, like theirs), reusing
   data-dict's type vocabulary verbatim where concepts overlap and adopting its
   level/code/severity check architecture, extended with everything revpiper needs
   (roles, levels+keys, missing codes, assembly declarations). No CLI dependency,
   user- or dev-side. **Logged: convergence review when data-dict reaches 1.0** —
   vocabulary alignment keeps that cheap. Spec §8.2 rows resolved by this decision
   and by Decision 1's investigation: "data-dict format-only vs CLI" and
   "extraction-tool export formats".
   - Liz's strategic note (2026-07-08): data-dict is worth watching beyond this
     project — potential for prespecification, data workflows, and reproducibility
     (registered analyses could declare expected variables/types/ranges before data
     arrival). Their roadmap (SQL/R/Python/pins sources) may eventually make their
     tooling directly useful here; revisit at the 1.0 review.

## Session 1 pause point (2026-07-08)

Both spec-mandated investigations DONE; two decisions recorded above. Environment:
sandbox has full verified dev stack (R 4.6.1, Air, renv library restored, pre-push
suite green on main @ 6a05c52).

**Resume agenda (design block, next session):**
1. Dictionary schema contents: roles (finite set for stages 1–3), levels + keys,
   missing codes, per-column cleaning opt-outs — and which of data-dict's keys we
   adopt verbatim.
2. Assembly grammar: the declared reshape set must cover (a) Covidence outcome-block
   pivot via column-name patterns, (b) multi-row banded Excel headers, (c) native-shape
   aux inputs + declared joins (granularity, relationship) — from Investigation 1.
3. Stage 2 cleaning operation set (deterministic, dictionary-generated).
4. Stage 3 check set + check-code→routing table (adopt S/M/D-style codes).
5. Findings object (rev_findings) + xlsx export + snapshot-tested message copy.
6. File layout mapping for stages 1–3 (spec §5) + mirror-rule test files; TDD order.
7. pkgdown rendered-.md set (queued from Phase 0).
8. Documentation templates — during implementation, with real functions.
