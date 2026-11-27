# Statistical advice and interpretation for epidemiology

`tep_advise()` advises on epidemiological data: which estimator answers
the question, what to check first, and the code to run.
`tep_interpret()` explains a result in plain sentences, says what to do
after the overall result (and what not to), and how to report it in a
paper.

## Usage

``` r
tep_advise(
  x,
  question = c("auto", "outbreak", "association", "survival", "diagnostic",
    "surveillance", "causal"),
  exposure = NULL,
  outcome = NULL,
  cases = NULL,
  time = NULL,
  event = NULL,
  test = NULL,
  truth = NULL,
  adjust = NULL,
  ...
)

tep_interpret(x, ...)
```

## Arguments

- x:

  A data frame (to be advised) or a tidyepidemio result (to be
  interpreted).

- question:

  What is asked (see above), or `"auto"` to guess it from the arguments
  given.

- exposure, outcome, cases, time, event, test, truth, adjust:

  Names (strings) of the columns in `x`.

- ...:

  Not used.

## Value

A `tep_advice` or a `tep_interpretation` object, printed as sentences,
with the advice in its `sections`.

## Details

With the tidyvisor package installed, `tidyvisor::tidyvisor()` hands
epidemiological data and results to these functions, so the same
statistical advisor covers epidemiology, community ecology
(tidydiversity) and spatial ecology (tidymapr). tidyepidemio does not
need tidyvisor.

Questions:

- `"outbreak"`: how fast are cases growing, and what is the reproduction
  number? (case counts over time)

- `"association"`: is an exposure associated with an outcome? (risk,
  odds and rate ratios, Mantel-Haenszel, adjusted ratios)

- `"survival"`: time to an event (Kaplan-Meier, Cox, restricted mean
  survival time)

- `"diagnostic"`: how well does a test find the condition?

- `"surveillance"`: are recent counts above what is expected?

- `"causal"`: the effect of an exposure, standardized for confounders
  (g-computation, inverse probability weighting)

## Examples

``` r
d <- data.frame(exposure = rep(0:1, each = 40), outcome = rep(c(0, 1, 0, 1), c(30, 10, 18, 22)))
tep_advise(d, question = "association", exposure = "exposure", outcome = "outcome")
#> 
#> ── tidyvisor: is the exposure associated with the outcome? ─────────────────────
#> Question: association
#> 
#> ── What the data show ──
#> 
#> • Records: 80
#> • Outcome events: 32 of 80 (40.0%) — common outcome (over 10%): odds ratios
#>   exaggerate risk ratios; report the risk ratio
#> • Exposure groups: 0: 40, 1: 40
#> 
#> ── Recommended ──
#> 
#> Estimate: Risk ratio (cohort) or odds ratio (case-control)
#> The design decides the measure: risks in cohorts and trials, odds in
#> case-control studies; rates when follow-up time differs.
#> epi_risk_ratio(data, exposure, outcome)   # or epi_odds_ratio(), epi_rate_ratio()
#> Confounding: Stratify or adjust
#> A crude ratio mixes the exposure with whatever travels with it; compare it with
#> the Mantel-Haenszel or adjusted ratio.
#> epi_mantel_haenszel(data, exposure, outcome, <stratum>)
#> Small numbers: Exact test when cells are small
#> With expected counts below 5, use an exact test and interval.
#> epi_fisher_test(data, exposure, outcome)
tep_interpret(epi_risk_ratio(d, exposure, outcome))
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Result ──
#> 
#> • The risk ratio is 2.2 (95% CI 1.2 to 4.03). The risk of the outcome is 120%
#>   higher in the exposed than in the unexposed.
#> • A crude estimate: confounding is not removed.
#> 
#> ── After the overall test ──
#> 
#> • Check that the association is not explained by confounding: stratify
#>   (epi_mantel_haenszel()) or adjust (epi_adjusted_risk_ratio(),
#>   epi_adjusted_odds_ratio()) for the confounders named in advance, and report
#>   crude and adjusted estimates side by side.
#> • With several exposure levels, report each against the same reference group,
#>   and test for a trend if the levels are ordered, rather than testing every
#>   pair.
#> 
#> ── For the paper ──
#> 
#> • Results: 'The risk ratio for exposure was 2.2 (95% CI 1.2 to 4.03).'
#> • Report the estimate with its 95% CI (and the counts behind it), not the
#>   p-value alone; give crude and adjusted estimates side by side.
#> • Figure: a forest plot of the estimates with their intervals on a log scale,
#>   with a line at 1:
#> • ggplot2::autoplot(result)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: one column (about 85 mm) or the page (about 180
#>   mm); axes labelled with units; a color-blind-safe palette; intervals shown,
#>   with what they are stated in the caption; text at least 8 pt; vector PDF.
#> • Table: exposed and unexposed with events and totals (or person-time), the
#>   crude and adjusted estimates with intervals, and what was adjusted for.
#> • Methods: the design (cohort, case-control, cross-sectional), the measure and
#>   why, the interval method, the confounders and how they were chosen; follow
#>   STROBE for observational studies, and the software (R 4.6.2, tidyepidemio
#>   1.2.0.9000; citation("tidyepidemio")).
```
