#' One-sided Poisson CUSUM surveillance
#'
#' Calculates the prospective upper-sided log-likelihood CUSUM for detecting an
#' increase from baseline mean `mu[t]` to `relative_risk * mu[t]`:
#' `S[t] = max(0, S[t-1] + cases[t]*log(relative_risk) -
#' (relative_risk-1)*mu[t])`. A flag occurs when `S[t] >= threshold`.
#' The statistic is not reset on an alert. Baseline values must be supplied from
#' external or previously available information; estimating them using future
#' observations leaks information. The threshold is not automatically
#' calibrated: choose it through simulation or an appropriate monitoring design.
#' Serial dependence, overdispersion, seasonality, reporting delays, repeated
#' testing and baseline uncertainty affect false-alarm rates. Flags are not
#' outbreak diagnoses.
#' @param .data Ungrouped data ordered chronologically at equal time intervals.
#' @param cases Non-negative integer counts.
#' @param baseline Positive expected counts for each corresponding time period.
#' @param relative_risk Alternative-to-baseline rate ratio, strictly above one.
#' @param threshold Positive log-likelihood CUSUM alert threshold.
#' @param initial Non-negative statistic at start of the series.
#' @return Input tibble with `cusum` and logical `alert` columns.
#' @examples
#' d <- data.frame(day = 1:5, cases = c(2, 1, 3, 7, 9), baseline = rep(2, 5))
#' epi_cusum(d, cases, baseline, relative_risk = 2, threshold = 3)
#' @export
epi_cusum <- function(.data, cases, baseline, relative_risk = 2, threshold = 5, initial = 0) {
  check_data(.data)
  count <- column(.data, rlang::enquo(cases), "cases")
  mu <- column(.data, rlang::enquo(baseline), "baseline")
  check_nonnegative(count, "cases")
  check_nonnegative(mu, "baseline", positive = TRUE)
  check_scalar(relative_risk, "relative_risk", min = 1)
  check_scalar(threshold, "threshold")
  check_scalar(initial, "initial", inclusive = TRUE)
  if (any(count != floor(count))) cli::cli_abort("{.arg cases} must contain integer counts.")
  if (any(c("cusum", "alert") %in% names(.data))) {
    cli::cli_abort("Output columns already exist; rename them before analysis.")
  }
  value <- numeric(length(count))
  last <- initial
  for (i in seq_along(count)) {
    last <- max(0, last + count[i] * log(relative_risk) - (relative_risk - 1) * mu[i])
    value[i] <- last
  }
  out <- tibble::as_tibble(.data)
  out$cusum <- value
  out$alert <- value >= threshold
  out
}
