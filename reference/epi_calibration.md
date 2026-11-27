# Grouped binary risk calibration

Divides predictions into equal-width probability bins and compares the
mean predicted risk with the observed outcome proportion. All bins are
returned; empty bins have zero observations and missing means and
limits. Probabilities exactly one enter the final bin. Wilson limits are
approximate binomial intervals for the observed proportion within a bin;
they do not account for model estimation, dependence, clustered
sampling, variation in risks within bins, or the choice of bins. No
weights or missing-data handling are included.

## Usage

``` r
epi_calibration(.data, truth, estimate, bins = 10L, conf_level = 0.95)
```

## Arguments

- .data:

  An ungrouped data frame with one row per individual.

- truth:

  Binary 0/1 observed outcome, with 1 denoting the event.

- estimate:

  Predicted event probability, numeric and between zero and one.

- bins:

  Number of equal-width bins, an integer between 1 and 1000.

- conf_level:

  Confidence level strictly between zero and one.

## Value

A tibble with bin boundaries, sample size, predicted and observed risks
and Wilson limits for the observed risk.

## Details

Assess calibration on data independent of model development, ideally
with temporal or external validation. Apparent calibration on training
data can be optimistic. Binning can conceal miscalibration and results
depend on bin width.

## Examples

``` r
d <- data.frame(y = c(0, 0, 1, 1), p = c(.1, .3, .7, .9))
epi_calibration(d, y, p, bins = 2)
#> # A tibble: 2 × 8
#>     bin lower upper     n mean_predicted observed_risk conf_low conf_high
#>   <int> <dbl> <dbl> <int>          <dbl>         <dbl>    <dbl>     <dbl>
#> 1     1   0     0.5     2            0.2             0    0         0.658
#> 2     2   0.5   1       2            0.8             1    0.342     1    
```
