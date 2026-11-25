#' Decision-curve analysis over thresholds
#'
#' For each risk threshold, computes weighted net benefit for the prediction
#' model, treating all, and treating none. For a threshold `p`, net benefit is
#' `(TP - FP * p/(1-p)) / total_weight`. A prediction at or above the threshold
#' is treated. The treat-all net benefit uses the weighted outcome prevalence;
#' treat-none net benefit is zero.
#'
#' Net benefit assumes the threshold reflects the relative harms of false
#' positives and false negatives and that the sample represents the intended
#' target population or uses appropriate weights. It is not a substitute for
#' clinical validation, randomized evaluation, or modeling treatment effects.
#' Predictive probabilities should ideally come from independent validation data.
#' No uncertainty intervals, prevalence adjustment, or subgroup inference are
#' calculated. This function does not choose a clinical threshold.
#' @param .data An ungrouped data frame of individual records.
#' @param truth Binary 0/1 outcome, where 1 is the event.
#' @param estimate Numeric predicted event probabilities in `[0,1]`.
#' @param thresholds Distinct numeric thresholds strictly between zero and one.
#' @param case_weights Optional non-negative numeric case-weight column; must
#'   have a positive total. Defaults to equal weights.
#' @return A long tibble with threshold, strategy (`model`, `treat_all`,
#'   `treat_none`) and net benefit.
#' @examples
#' d <- data.frame(y = c(1, 1, 0, 0), p = c(.9, .6, .4, .1))
#' epi_decision_curve(d, y, p, thresholds = c(.25, .5, .75))
#' @export
epi_decision_curve <- function(.data, truth, estimate, thresholds = seq(.05, .95, .05), case_weights = NULL) {
  check_data(.data)
  y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  p <- column(.data, rlang::enquo(estimate), "estimate")
  wq <- rlang::enquo(case_weights)
  if (!length(y) || !is.numeric(p) || anyNA(p) || any(!is.finite(p)) || any(p < 0 | p > 1)) {
    cli::cli_abort("Predictions must be finite probabilities in [0,1], with at least one record.")
  }
  if (!is.numeric(thresholds) ||
    !length(thresholds) ||
    length(thresholds) > 1000 ||
    anyNA(thresholds) ||
    any(!is.finite(thresholds)) ||
    any(thresholds <= 0 | thresholds >= 1) ||
    anyDuplicated(thresholds)) {
    cli::cli_abort(
      "{.arg thresholds} must contain at most 1000 distinct probabilities strictly between zero and one."
    )
  }
  w <- if (rlang::quo_is_null(wq)) rep(1, length(y)) else column(.data, wq, "case_weights")
  check_nonnegative(w, "case_weights")
  if (max(w) <= 0) cli::cli_abort("Case weights must have a positive total.")
  w <- w / max(w)
  total <- sum(w)
  prevalence <- sum(w * y) / total
  values <- vapply(thresholds, function(t) {
    positive <- p >= t
    model <- (sum(w[positive & y == 1]) - sum(w[positive & y == 0]) * t / (1 - t)) / total
    c(model, prevalence - (1 - prevalence) * t / (1 - t), 0)
  }, numeric(3))
  tibble::tibble(
    threshold = rep(thresholds, each = 3),
    strategy = rep(c("model", "treat_all", "treat_none"), times = length(thresholds)),
    net_benefit = as.vector(values)
  )
}
