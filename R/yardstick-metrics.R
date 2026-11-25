#' Weighted interval score
#'
#' Computes the mean WIS for a median and one or more central prediction
#' intervals. For K intervals it is `(0.5 * |y - median| + sum(alpha/2 * IS)) /
#' (K + 0.5)`, where IS is interval width plus `2/alpha` times miss distance.
#' Lower scores are better. Pairs of lower and upper columns must be supplied
#' in corresponding order matching the miscoverage probabilities in `alpha`.
#' WIS requires interval columns in addition to the median; use [wis_metric()]
#' to capture those columns for a yardstick `metric_set()`.
#' @param .data A data frame; grouped data are summarized by group.
#' @param truth Numeric observed outcome.
#' @param estimate Numeric predicted median.
#' @param lower,upper Tidy selections of numeric interval columns. For the vector
#'   method, numeric vectors for one interval, or numeric matrices with one row
#'   per observation and one column per interval.
#' @param alpha Numeric vector of interval miscoverage probabilities in (0,1).
#' @param na_rm Remove rows with missing inputs?
#' @param case_weights Optional non-negative case weights, or a weight column.
#' @param ... Not used.
#' @return A yardstick-style tibble with `.metric`, `.estimator`, `.estimate`;
#'   the vector method returns a numeric scalar.
#' @examples
#' d <- data.frame(y = c(1, 2), med = c(1, 3), lo = c(0, 1), hi = c(2, 4))
#' wis(d, y, med, lo, hi, alpha = 0.1)
#' wis_vec(d$y, d$med, d$lo, d$hi, alpha = 0.1)
#' @export
wis <- function(.data, ...) UseMethod("wis")
wis <- yardstick::new_numeric_metric(wis, direction = "minimize")
#' @export
wis.data.frame <- function(.data, truth, estimate, lower, upper, alpha = 0.1, na_rm = TRUE, case_weights = NULL, ...) {
  tq <- rlang::enquo(truth)
  eq <- rlang::enquo(estimate)
  lq <- rlang::enquo(lower)
  uq <- rlang::enquo(upper)
  wq <- rlang::enquo(case_weights)
  low_names <- names(tidyselect::eval_select(lq, .data))
  up_names <- names(tidyselect::eval_select(uq, .data))
  if (!length(low_names) || length(low_names) != length(up_names)) cli::cli_abort("Select equal numbers of lower and upper columns.")
  if (any(!vapply(.data[c(low_names, up_names)], is.numeric, logical(1)))) cli::cli_abort("Interval columns must be numeric.")
  groups <- dplyr::group_rows(.data)
  keys <- dplyr::group_keys(.data)
  plain <- dplyr::ungroup(.data)
  ans <- vapply(groups, function(idx) {
    g <- plain[idx, , drop = FALSE]
    t <- column(g, tq, "truth")
    e <- column(g, eq, "estimate")
    w <- if (rlang::quo_is_null(wq)) NULL else column(g, wq, "case_weights")
    wis_vec(t, e, as.matrix(g[low_names]), as.matrix(g[up_names]), alpha = alpha, na_rm = na_rm, case_weights = w)
  }, numeric(1))
  dplyr::bind_cols(keys, tibble::tibble(.metric = "wis", .estimator = "standard", .estimate = ans))
}
#' @rdname wis
#' @export
wis_vec <- function(truth, estimate, lower, upper, alpha = 0.1, na_rm = TRUE, case_weights = NULL, ...) {
  if (!is.logical(na_rm) || length(na_rm) != 1 || is.na(na_rm)) cli::cli_abort("{.arg na_rm} must be TRUE or FALSE.")
  if (!is.numeric(truth) || !is.numeric(estimate) || !is.numeric(lower) || !is.numeric(upper) || length(truth) != length(estimate)) cli::cli_abort("Truth, estimate, lower, and upper must be numeric with matching rows.")
  if (is.null(dim(lower))) lower <- matrix(lower, ncol = 1)
  if (is.null(dim(upper))) upper <- matrix(upper, ncol = 1)
  if (length(dim(lower)) != 2 || length(dim(upper)) != 2 || nrow(lower) != length(truth) || !identical(dim(lower), dim(upper)) || ncol(lower) < 1) cli::cli_abort("Interval bounds must have matching dimensions and one row per observation.")
  k <- ncol(lower)
  if (!is.numeric(alpha) || length(alpha) != k || anyNA(alpha) || any(!is.finite(alpha)) || any(alpha <= 0 | alpha >= 1) || anyDuplicated(alpha)) cli::cli_abort("Supply one distinct alpha in (0,1) per interval.")
  if (is.null(case_weights)) case_weights <- rep(1, length(truth)) else case_weights <- as.numeric(case_weights)
  if (length(case_weights) != length(truth)) cli::cli_abort("Case weights must have the same length as truth.")
  ok <- stats::complete.cases(truth, estimate, lower, upper, case_weights)
  if (!na_rm && any(!ok)) {
    return(NA_real_)
  }
  truth <- truth[ok]
  estimate <- estimate[ok]
  lower <- lower[ok, , drop = FALSE]
  upper <- upper[ok, , drop = FALSE]
  case_weights <- case_weights[ok]
  if (!length(truth)) {
    return(NA_real_)
  }
  if (any(!is.finite(c(truth, estimate, lower, upper))) || any(lower > upper) || any(estimate < lower | estimate > upper)) cli::cli_abort("Values must be finite and satisfy lower <= estimate <= upper.")
  check_nonnegative(case_weights, "case_weights")
  if (sum(case_weights) == 0) cli::cli_abort("Case weights must have a positive total.")
  score <- 0.5 * abs(truth - estimate)
  for (j in seq_len(k)) score <- score + alpha[j] / 2 * (upper[, j] - lower[, j]) + pmax(lower[, j] - truth, 0) + pmax(truth - upper[, j], 0)
  sum(score * case_weights) / sum(case_weights) / (k + .5)
}
#' Decision-curve net benefit
#'
#' Calculates `TP/n - FP/n * threshold/(1-threshold)` for a predicted risk
#' at or above threshold. Truth must be a two-level factor; the first level is
#' the event by default. This evaluates one threshold without uncertainty.
#' @param .data A data frame.
#' @param truth A two-level factor containing the true class.
#' @param estimate Predicted probability of the event.
#' @param threshold Decision threshold strictly between 0 and 1.
#' @param event_level Which factor level is the event: `"first"` or `"second"`.
#' @param na_rm Remove rows with missing truth or estimate?
#' @param case_weights Optional non-negative case weights, or a weight column.
#' @param data Alternative name for `.data` for yardstick metric-set compatibility.
#' @param ... Not used.
#' @return A yardstick-style metric tibble; the `_vec` form returns a number.
#' @examples
#' d <- data.frame(y = factor(c("case", "control"), levels = c("case", "control")), p = c(0.8, 0.6))
#' net_benefit(d, y, p, threshold = 0.5)
#' net_benefit_vec(d$y, d$p, threshold = 0.5)
#' @export
net_benefit <- function(.data = NULL, ..., data = NULL) {
  if (!is.null(data)) UseMethod("net_benefit", data) else UseMethod("net_benefit", .data)
}
net_benefit <- yardstick::new_prob_metric(net_benefit, direction = "maximize")
#' @export
net_benefit.data.frame <- function(.data = NULL, truth, estimate, threshold = 0.5, event_level = "first", na_rm = TRUE, case_weights = NULL, ..., data = NULL) {
  if (!is.null(data)) {
    eq <- if (missing(estimate)) rlang::enquo(.data) else rlang::enquo(estimate)
    .data <- data
  } else {
    eq <- rlang::enquo(estimate)
  }
  tq <- rlang::enquo(truth)
  wq <- rlang::enquo(case_weights)
  groups <- dplyr::group_rows(.data)
  keys <- dplyr::group_keys(.data)
  plain <- dplyr::ungroup(.data)
  ans <- vapply(groups, function(idx) {
    g <- plain[idx, , drop = FALSE]
    t <- column(g, tq, "truth")
    e <- column(g, eq, "estimate")
    w <- if (rlang::quo_is_null(wq)) NULL else column(g, wq, "case_weights")
    net_benefit_vec(t, e, threshold = threshold, event_level = event_level, na_rm = na_rm, case_weights = w)
  }, numeric(1))
  dplyr::bind_cols(keys, tibble::tibble(.metric = "net_benefit", .estimator = "binary", .estimate = ans))
}
#' @rdname net_benefit
#' @export
net_benefit_vec <- function(truth, estimate, threshold = 0.5, event_level = "first", na_rm = TRUE, case_weights = NULL, ...) {
  check_scalar(threshold, "threshold")
  if (threshold >= 1) cli::cli_abort("{.arg threshold} must be less than one.")
  event_level <- match.arg(event_level, c("first", "second"))
  if (!is.logical(na_rm) || length(na_rm) != 1 || is.na(na_rm)) cli::cli_abort("{.arg na_rm} must be TRUE or FALSE.")
  if (!is.factor(truth) || nlevels(truth) != 2 || !is.numeric(estimate) || length(truth) != length(estimate)) cli::cli_abort("Truth must be a two-level factor and estimate a numeric vector of equal length.")
  if (is.null(case_weights)) case_weights <- rep(1, length(truth)) else case_weights <- as.numeric(case_weights)
  if (length(case_weights) != length(truth)) cli::cli_abort("Case weights must have the same length as truth.")
  ok <- stats::complete.cases(truth, estimate, case_weights)
  if (!na_rm && any(!ok)) {
    return(NA_real_)
  }
  truth <- truth[ok]
  estimate <- estimate[ok]
  case_weights <- case_weights[ok]
  if (!length(truth)) {
    return(NA_real_)
  }
  if (any(!is.finite(estimate) | estimate < 0 | estimate > 1)) cli::cli_abort("Probabilities must be finite and between zero and one.")
  check_nonnegative(case_weights, "case_weights")
  if (sum(case_weights) == 0) cli::cli_abort("Case weights must have a positive total.")
  event <- truth == levels(truth)[if (event_level == "first") 1 else 2]
  positive <- estimate >= threshold
  (sum(case_weights[positive & event]) - sum(case_weights[positive & !event]) * threshold / (1 - threshold)) / sum(case_weights)
}
