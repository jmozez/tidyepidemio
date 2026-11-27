# Decision-curve net benefit

Calculates `TP/n - FP/n * threshold/(1-threshold)` for a predicted risk
at or above threshold. Truth must be a two-level factor; the first level
is the event by default. This evaluates one threshold without
uncertainty.

## Usage

``` r
net_benefit(.data = NULL, ..., data = NULL)

net_benefit_vec(
  truth,
  estimate,
  threshold = 0.5,
  event_level = "first",
  na_rm = TRUE,
  case_weights = NULL,
  ...
)
```

## Arguments

- .data:

  A data frame.

- ...:

  Not used.

- data:

  Alternative name for `.data` for yardstick metric-set compatibility.

- truth:

  A two-level factor containing the true class.

- estimate:

  Predicted probability of the event.

- threshold:

  Decision threshold strictly between 0 and 1.

- event_level:

  Which factor level is the event: `"first"` or `"second"`.

- na_rm:

  Remove rows with missing truth or estimate?

- case_weights:

  Optional non-negative case weights, or a weight column.

## Value

A yardstick-style metric tibble; the `_vec` form returns a number.

## Examples

``` r
d <- data.frame(y = factor(c("case", "control"), levels = c("case", "control")), p = c(0.8, 0.6))
net_benefit(d, y, p, threshold = 0.5)
#>       .metric .estimator .estimate
#> 1 net_benefit     binary         0
net_benefit_vec(d$y, d$p, threshold = 0.5)
#> [1] 0
```
