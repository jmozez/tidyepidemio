# Binary prediction calibration and discrimination summary

Computes the Brier score, calibration-in-the-large, calibration
intercept, calibration slope, and area under the ROC curve.
Calibration-in-the-large is the intercept of
`logit(P(Y=1)) = intercept + offset(logit(p))`. Calibration intercept
and slope are from the joint logistic model
`logit(P(Y=1)) = intercept + slope * logit(p)`. Ideal values are zero
for both intercepts and one for the slope. AUC uses average ranks for
tied predictions. Brier score is the mean squared prediction error.

## Usage

``` r
epi_calibration_summary(.data, truth, estimate)
```

## Arguments

- .data:

  An ungrouped data frame with one row per individual.

- truth:

  Binary 0/1 event indicator.

- estimate:

  Numeric predicted event probabilities strictly in (0,1).

## Value

One-row tibble with sample size, event prevalence, Brier score,
calibration-in-the-large, calibration intercept and slope, and ROC AUC.

## Details

Predictions must be strictly inside (0,1) so logits are finite. Do not
silently clip zero or one: a caller choosing to clip must document that
modeling decision. Both outcome levels and at least two distinct
predictions are required. Complete or quasi-separation can make
calibration coefficients unreliable; the function warns but cannot rule
it out. No confidence intervals, weights, clustering, missing-data
handling or recalibration are provided. Evaluate performance on
independent validation data, not the fitting sample.

## Examples

``` r
d <- data.frame(y = c(0, 0, 1, 0, 1, 0, 1, 1), p = c(.1, .2, .3, .4, .5, .6, .7, .8))
epi_calibration_summary(d, y, p)
#> # A tibble: 1 × 7
#>       n event_prevalence brier calibration_in_large calibration_intercept
#>   <int>            <dbl> <dbl>                <dbl>                 <dbl>
#> 1     8              0.5  0.18                0.256                 0.330
#> # ℹ 2 more variables: calibration_slope <dbl>, roc_auc <dbl>
```
