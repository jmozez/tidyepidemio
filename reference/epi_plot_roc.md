# Plot an empirical ROC curve

Draws a ROC curve from an
[`epi_roc_curve()`](https://tidyepidemio.in4metrix.dev/reference/epi_roc_curve.md)
result with a diagonal reference line. Rows must be ordered by
non-decreasing false-positive rate. This plot does not recompute the
curve, AUC, or confidence intervals.

## Usage

``` r
epi_plot_roc(.data)
```

## Arguments

- .data:

  A data frame containing `false_positive_rate` and `sensitivity`
  columns with finite proportions in non-decreasing false-positive-rate
  order.

## Value

A ggplot object.

## Examples

``` r
d <- data.frame(y = c(0, 1, 0, 1), score = c(.1, .6, .6, .9))
epi_plot_roc(epi_roc_curve(d, y, score))
```
