# Empirical ROC curve for a diagnostic score

Computes an empirical receiver-operating-characteristic curve over each
distinct score threshold, including the origin representing no positive
tests. Scores equal to a threshold are classified together. The
empirical AUC is trapezoidal and corresponds to the probability that a
randomly chosen case has a more positive score than a randomly chosen
control, with tied pairs counted as one half. For
`direction = "higher"`, scores greater than or equal to the threshold
are positive; for `"lower"`, scores less than or equal to the threshold
are positive.

## Usage

``` r
epi_roc_curve(.data, truth, score, direction = c("higher", "lower"))
```

## Arguments

- .data:

  An ungrouped data frame of independent subjects.

- truth:

  Binary 0/1 reference outcome, where 1 is the event.

- score:

  Finite numeric diagnostic score; probabilities are not required.

- direction:

  Either `"higher"` or `"lower"`, indicating which scores are more
  positive.

## Value

A tibble ordered from no positive tests to all positive tests, with
thresholds, cell counts, sensitivity, specificity, false-positive rate,
predictive values and AUC. Undefined predictive values are `NA`.

## Details

Both reference outcome levels must be present. AUC is repeated for
convenience and summarizes the full input, even if the resulting table
is later filtered. The method does not select a clinical threshold,
adjust for clustering or sampling, provide confidence intervals, or
correct for model overfitting. Use independent validation data where
appropriate. PPV and NPV use the input sample prevalence and may not
transport to other settings.

## Examples

``` r
d <- data.frame(y = c(0, 1, 0, 1), score = c(.1, .6, .6, .9))
curve <- epi_roc_curve(d, y, score)
epi_plot_roc(curve)
```
