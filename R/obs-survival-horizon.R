#' Kaplan-Meier event risk at fixed horizons
#'
#' Estimates event risk at specified follow-up times as one minus Kaplan-Meier
#' survival. The step function is right-continuous, so events exactly at a
#' horizon are included. Confidence bounds reverse the log-log survival limits.
#' The returned risk set is the number of subjects whose observed follow-up is
#' at least the horizon, including those with an event or censoring at that time.
#' Horizons must not exceed the maximum observed follow-up: this function does
#' not extrapolate a survival curve beyond its observed support.
#'
#' Estimates assume independent censoring and independent subjects. This is
#' not a competing-risk cumulative incidence estimator and does not support
#' left truncation, covariates, weights, time-varying exposures or clustering.
#' For competing events use [epi_cumulative_incidence()] rather than censoring
#' them as if they were independent.
#' @param .data An ungrouped data frame, one row per individual.
#' @param time Non-negative follow-up or exit time.
#' @param event Binary event indicator: 1 for event and 0 for censoring.
#' @param horizons Numeric non-negative evaluation times, in the same units as
#'   `time`; no value may exceed the largest observed follow-up time.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A tibble with horizon, risk set, event risk and confidence limits.
#'   Before the first observed event or censoring time, the risk and limits are
#'   zero. Limits may be missing when survival limits are undefined.
#' @examples
#' d <- data.frame(time = c(1, 2, 3, 4), event = c(1, 0, 1, 0))
#' epi_survival_risk(d, time, event, horizons = c(0, 2, 3))
#' @export
epi_survival_risk <- function(.data, time, event, horizons, conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  t <- column(.data, rlang::enquo(time), "time")
  e <- check_binary(column(.data, rlang::enquo(event), "event"), "event")
  check_nonnegative(t, "time")
  check_nonnegative(horizons, "horizons")
  if (!length(t) || !length(horizons)) cli::cli_abort("At least one record and one horizon are required.")
  if (any(horizons > max(t))) cli::cli_abort("Horizons must not exceed the maximum observed follow-up time.")
  d <- data.frame(t = t, e = e)
  fit <- survival::survfit(survival::Surv(t, e) ~ 1, data = d, conf.type = "log-log", conf.int = conf_level)
  index <- findInterval(horizons, fit$time)
  risk <- lo <- hi <- rep(0, length(horizons))
  has <- index > 0
  risk[has] <- 1 - fit$surv[index[has]]
  lo[has] <- 1 - fit$upper[index[has]]
  hi[has] <- 1 - fit$lower[index[has]]
  tibble::tibble(horizon = horizons, n_risk = vapply(horizons, function(h) sum(t >= h), integer(1)), risk = risk, conf_low = lo, conf_high = hi, conf_level = conf_level)
}
