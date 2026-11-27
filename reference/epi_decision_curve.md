# Decision-curve analysis over thresholds

For each risk threshold, computes weighted net benefit for the
prediction model, treating all, and treating none. For a threshold `p`,
net benefit is `(TP - FP * p/(1-p)) / total_weight`. A prediction at or
above the threshold is treated. The treat-all net benefit uses the
weighted outcome prevalence; treat-none net benefit is zero.

## Usage

``` r
epi_decision_curve(
  .data,
  truth,
  estimate,
  thresholds = seq(0.05, 0.95, 0.05),
  case_weights = NULL
)
```

## Arguments

- .data:

  An ungrouped data frame of individual records.

- truth:

  Binary 0/1 outcome, where 1 is the event.

- estimate:

  Numeric predicted event probabilities in `[0,1]`.

- thresholds:

  Distinct numeric thresholds strictly between zero and one.

- case_weights:

  Optional non-negative numeric case-weight column; must have a positive
  total. Defaults to equal weights.

## Value

A long tibble with threshold, strategy (`model`, `treat_all`,
`treat_none`) and net benefit.

## Details

Net benefit assumes the threshold reflects the relative harms of false
positives and false negatives and that the sample represents the
intended target population or uses appropriate weights. It is not a
substitute for clinical validation, randomized evaluation, or modeling
treatment effects. Predictive probabilities should ideally come from
independent validation data. No uncertainty intervals, prevalence
adjustment, or subgroup inference are calculated. This function does not
choose a clinical threshold.

## Examples

``` r
d <- data.frame(y = c(1, 1, 0, 0), p = c(.9, .6, .4, .1))
epi_decision_curve(d, y, p, thresholds = c(.25, .5, .75))
#> # A tibble: 9 × 3
#>   threshold strategy   net_benefit
#>       <dbl> <chr>            <dbl>
#> 1      0.25 model            0.417
#> 2      0.25 treat_all        0.333
#> 3      0.25 treat_none       0    
#> 4      0.5  model            0.5  
#> 5      0.5  treat_all        0    
#> 6      0.5  treat_none       0    
#> 7      0.75 model            0.25 
#> 8      0.75 treat_all       -1    
#> 9      0.75 treat_none       0    
```
