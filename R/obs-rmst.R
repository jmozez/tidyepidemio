#' Restricted mean survival time
#'
#' Integrates the Kaplan-Meier survival curve from zero to the prespecified
#' horizon `tau`. The standard error uses Greenwood's plug-in variance for the
#' restricted mean; the optional Wald limits are clipped to the mathematical
#' range zero to `tau`. These limits can perform poorly in small or heavily
#' censored samples and are not a substitute for a study-specific analysis.
#' Events exactly at `tau` contribute no area after the event. Events at time
#' zero are incorporated immediately.
#'
#' Independent individuals and non-informative censoring are assumed. `tau`
#' cannot exceed the maximum observed follow-up, but merely meeting this rule
#' does not ensure adequate tail support: inspect the number at risk and choose
#' the horizon before comparing groups. If no event occurs before `tau`, the
#' Greenwood standard error is zero, which does not imply certainty under heavy
#' censoring. There is no left truncation, competing-risk adjustment, weighting,
#' covariate adjustment, clustering or comparison between groups.
#' @param .data An ungrouped data frame with one row per individual.
#' @param time Non-negative observed follow-up time.
#' @param event Binary event indicator, 1 for the event, 0 for censoring.
#' @param tau Positive restriction horizon, no greater than maximum follow-up.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A one-row tibble containing the horizon, RMST, Greenwood standard
#'   error, clipped Wald confidence limits, sample size, and the number at risk
#'   and events before the horizon.
#' @examples
#' d <- data.frame(t = c(1, 2, 3, 4, 5, 6), e = c(1, 0, 1, 0, 1, 0))
#' epi_rmst(d, t, e, tau = 5)
#' @export
epi_rmst <- function(.data, time, event, tau, conf_level = 0.95) {
  check_data(.data)
  check_scalar(tau, "tau")
  check_probability(conf_level, "conf_level")
  t <- column(.data, rlang::enquo(time), "time")
  e <- check_binary(column(.data, rlang::enquo(event), "event"), "event")
  check_nonnegative(t, "time")
  if (!length(t)) cli::cli_abort("At least one individual is required.")
  if (tau > max(t)) cli::cli_abort("{.arg tau} must not exceed maximum observed follow-up.")
  d <- data.frame(t = t, e = e)
  fit <- survival::survfit(survival::Surv(t, e) ~ 1, data = d)
  breaks <- c(0, fit$time[fit$time > 0 & fit$time < tau], tau)
  starts <- utils::head(breaks, -1)
  idx <- findInterval(starts, fit$time)
  s <- rep(1, length(starts))
  s[idx > 0] <- fit$surv[idx[idx > 0]]
  area <- diff(breaks) * s
  estimate <- sum(area)
  remainder <- rev(cumsum(rev(area)))
  ev <- which(fit$n.event > 0 & fit$time < tau & fit$n.risk > fit$n.event)
  variance <- if (length(ev)) sum((remainder[findInterval(fit$time[ev], starts)]^2) * fit$n.event[ev] / (fit$n.risk[ev] * (fit$n.risk[ev] - fit$n.event[ev]))) else 0
  se <- sqrt(variance)
  z <- stats::qnorm((1 - conf_level) / 2, lower.tail = FALSE)
  tibble::tibble(tau = tau, estimate = estimate, std_error = se, conf_low = max(0, estimate - z * se), conf_high = min(tau, estimate + z * se), n = length(t), n_risk = sum(t >= tau), events_before_tau = sum(e[t < tau]), conf_level = conf_level)
}
