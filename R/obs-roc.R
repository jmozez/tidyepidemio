#' Empirical ROC curve for a diagnostic score
#'
#' Computes an empirical receiver-operating-characteristic curve over each
#' distinct score threshold, including the origin representing no positive tests.
#' Scores equal to a threshold are classified together. The empirical AUC is
#' trapezoidal and corresponds to the probability that a randomly chosen case
#' has a more positive score than a randomly chosen control, with tied pairs
#' counted as one half. For `direction = "higher"`, scores greater than or
#' equal to the threshold are positive; for `"lower"`, scores less than or
#' equal to the threshold are positive.
#'
#' Both reference outcome levels must be present. AUC is repeated for convenience
#' and summarizes the full input, even if the resulting table is later filtered.
#' The method does not select a clinical threshold, adjust for clustering or
#' sampling, provide confidence intervals, or correct for model overfitting.
#' Use independent validation data where appropriate. PPV and NPV use the input
#' sample prevalence and may not transport to other settings.
#' @param .data An ungrouped data frame of independent subjects.
#' @param truth Binary 0/1 reference outcome, where 1 is the event.
#' @param score Finite numeric diagnostic score; probabilities are not required.
#' @param direction Either `"higher"` or `"lower"`, indicating which scores are
#'   more positive.
#' @return A tibble ordered from no positive tests to all positive tests, with
#'   thresholds, cell counts, sensitivity, specificity, false-positive rate,
#'   predictive values and AUC. Undefined predictive values are `NA`.
#' @examples
#' d <- data.frame(y = c(0, 1, 0, 1), score = c(.1, .6, .6, .9))
#' curve <- epi_roc_curve(d, y, score)
#' epi_plot_roc(curve)
#' @export
epi_roc_curve <- function(.data, truth, score, direction = c("higher", "lower")) {
  check_data(.data)
  direction <- match.arg(direction)
  y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  s <- column(.data, rlang::enquo(score), "score")
  if (!length(y) || length(unique(y)) < 2 || !is.numeric(s) || anyNA(s) || any(!is.finite(s))) cli::cli_abort("Both outcome levels and finite numeric scores without missing values are required.")
  effective <- if (direction == "higher") s else -s
  ord <- order(effective, decreasing = TRUE)
  sorted <- effective[ord]
  ends <- cumsum(rle(sorted)$lengths)
  tp <- c(0, cumsum(y[ord])[ends])
  fp <- c(0, as.double(ends) - tp[-1])
  n1 <- sum(y)
  n0 <- length(y) - n1
  sensitivity <- tp / n1
  fpr <- fp / n0
  specificity <- 1 - fpr
  ppv <- npv <- rep(NA_real_, length(tp))
  pos <- tp + fp
  neg <- (n0 - fp) + (n1 - tp)
  ppv[pos > 0] <- tp[pos > 0] / pos[pos > 0]
  npv[neg > 0] <- (n0 - fp[neg > 0]) / neg[neg > 0]
  auc <- sum(diff(fpr) * (utils::head(sensitivity, -1) + utils::tail(sensitivity, -1)) / 2)
  thresholds <- c(if (direction == "higher") Inf else -Inf, s[ord][ends])
  tibble::tibble(threshold = thresholds, tp = tp, fp = fp, fn = n1 - tp, tn = n0 - fp, sensitivity = sensitivity, specificity = specificity, false_positive_rate = fpr, ppv = ppv, npv = npv, auc = auc)
}
#' Plot an empirical ROC curve
#'
#' Draws a ROC curve from an [epi_roc_curve()] result with a diagonal reference
#' line. Rows must be ordered by non-decreasing false-positive rate. This plot
#' does not recompute the curve, AUC, or confidence intervals.
#' @param .data A data frame containing `false_positive_rate` and `sensitivity`
#'   columns with finite proportions in non-decreasing false-positive-rate order.
#' @return A ggplot object.
#' @examples
#' d <- data.frame(y = c(0, 1, 0, 1), score = c(.1, .6, .6, .9))
#' epi_plot_roc(epi_roc_curve(d, y, score))
#' @export
epi_plot_roc <- function(.data) {
  check_data(.data)
  if (!all(c("false_positive_rate", "sensitivity") %in% names(.data))) cli::cli_abort("ROC data must contain {.field false_positive_rate} and {.field sensitivity} columns.")
  x <- .data$false_positive_rate
  y <- .data$sensitivity
  if (!length(x) || !is.numeric(x) || !is.numeric(y) || anyNA(x) || anyNA(y) || any(!is.finite(x)) || any(!is.finite(y)) || any(x < 0 | x > 1 | y < 0 | y > 1) || any(diff(x) < 0)) cli::cli_abort("ROC rates must be finite proportions, ordered by non-decreasing false-positive rate.")
  ggplot2::ggplot(.data, ggplot2::aes(x = .data$false_positive_rate, y = .data$sensitivity)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2) +
    ggplot2::geom_path() +
    ggplot2::coord_equal(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
    ggplot2::labs(x = "False-positive rate", y = "Sensitivity")
}
