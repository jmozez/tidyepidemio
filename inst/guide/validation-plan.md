# Validation plan and evidence template

**Status: NOT PERFORMED.** This is a plan for independent evaluation, not
validation evidence. Local software checks and synthetic tests do not establish
clinical usefulness, operational performance or suitability for a particular
population. A qualified domain expert, statistician and data owner must approve
and conduct the appropriate study before operational use.

## 1. Define the intended use before analysis

Record the decision to be supported, target population and setting, inputs and
timing, prediction or estimand, intended users, outcomes, units, interventions,
and foreseeable harms. Specify the package version, exact configuration and
external reference implementation; identify who is accountable for approval.
Decide what constitutes an acceptable result and a stopping rule *before*
viewing the evaluation results. No generic acceptance threshold is appropriate
for all uses.

## 2. Data governance and reference standards

Confirm lawful access, ethics and institutional approval where needed; minimize
identifiable data and document data provenance, extraction date and quality.
Specify outcome definitions, missingness, censoring, reporting delays and
reference-standard accuracy. Keep an untouched external evaluation set; when
relevant use sites, time periods or populations separate from development. For
outbreak backtests retain the actual data vintage available at each origin,
including later revisions; do not substitute final data for historical inputs.

## 3. Statistical and software verification

- Independently reproduce selected calculations on prespecified benchmark data
  using a trusted, independently maintained implementation or hand calculations.
  Compare point estimates, intervals, boundary cases, units, tie handling,
  censoring and missing-data behavior, and report discrepancies with tolerances.
- Run the package tests and check logs on supported R versions and operating
  systems. Record versions, seeds, package dependencies, inputs and commands.
  The repository provides a proposed CI matrix, but its presence is not a CI
  run or evidence that every platform passes.
- For stochastic simulations and bootstrap methods, repeat with recorded seeds
  and enough simulations to quantify Monte Carlo variability. Test conservation
  laws and plausible limiting behavior separately from predictive validity.

## 4. External and operational evaluation

For risk predictions assess calibration and discrimination in independent data,
with uncertainty, relevant subgroup analyses, missingness and clinical workflow
considerations. For surveillance and forecasting use rolling evaluation with
historical data vintages; measure delay, false-alarm burden, interval coverage
and forecast accuracy under the actual update and alerting procedure. Calibrate
repeated monitoring and multiple series rather than interpreting a single-look
threshold as an overall false-alarm guarantee. For causal analyses justify the
estimand, temporal ordering, confounding adjustment, positivity and censoring
assumptions; evaluate overlap and sensitivity to plausible violations.

## 5. Review, release and monitoring record

Fill in: intended use; named reviewers; protocol/version/date; data sources and
population; prespecified acceptance criteria; independent reference methods;
software environment; sample sizes and missingness; results with uncertainty;
subgroup findings; deviations and failures; residual risks; and approval or
rejection. Decide how to monitor drift, reporting changes and failures, when to
revalidate, and how to suspend use. Retain the full signed report securely.

Do not fill these fields with illustrative data or represent the plan as a
completed independent validation.
