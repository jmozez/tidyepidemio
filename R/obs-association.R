#' Measures of association for individual-level binary data
#'
#' Exposure and outcome must be coded 0/1. No continuity correction is applied;
#' Undefined or infinite estimates are represented by `NA`; zero estimates are
#' retained but have `NA` log-scale intervals. Wald intervals are approximate
#' and require positive event counts (all cells for odds ratios).
#' Attributable risk is exposed risk minus unexposed risk.
#' @param .data A data frame of individual records.
#' @param exposure Binary exposure indicator.
#' @param outcome Binary outcome indicator.
#' @param time Non-negative person-time; required for a rate ratio.
#' @param conf_level Confidence level between zero and one.
#' @return A one-row tibble with estimate, confidence limits and group counts.
#' @examples
#' d <- data.frame(exposure = rep(0:1, each = 4), outcome = c(0,0,0,1,0,1,1,1))
#' epi_risk_ratio(d, exposure, outcome)
#' epi_odds_ratio(d, exposure, outcome)
#' epi_attributable_risk(d, exposure, outcome)
#' d$time <- 1
#' epi_rate_ratio(d, exposure, outcome, time)
#' @export
epi_risk_ratio <- function(.data, exposure, outcome, conf_level = 0.95) assoc(.data, rlang::enquo(exposure), rlang::enquo(outcome), type = "risk_ratio", conf_level = conf_level)
#' @rdname epi_risk_ratio
#' @export
epi_odds_ratio <- function(.data, exposure, outcome, conf_level = 0.95) assoc(.data, rlang::enquo(exposure), rlang::enquo(outcome), type = "odds_ratio", conf_level = conf_level)
#' @rdname epi_risk_ratio
#' @export
epi_attributable_risk <- function(.data, exposure, outcome, conf_level = 0.95) assoc(.data, rlang::enquo(exposure), rlang::enquo(outcome), type = "risk_difference", conf_level = conf_level)
#' @rdname epi_risk_ratio
#' @export
epi_rate_ratio <- function(.data, exposure, outcome, time, conf_level = 0.95) assoc(.data, rlang::enquo(exposure), rlang::enquo(outcome), rlang::enquo(time), "rate_ratio", conf_level)
assoc <- function(data, eq, oq, tq = NULL, type, conf_level) {
  check_data(data); check_scalar(conf_level, "conf_level"); if (conf_level >= 1) cli::cli_abort("{.arg conf_level} must be less than 1.")
  e <- check_binary(column(data, eq, "exposure"), "exposure"); y <- check_binary(column(data, oq, "outcome"), "outcome")
  a <- as.double(sum(e == 1 & y == 1)); b <- as.double(sum(e == 1 & y == 0)); c <- as.double(sum(e == 0 & y == 1)); d <- as.double(sum(e == 0 & y == 0))
  n1 <- a + b; n0 <- c + d
  if (!n1 || !n0) cli::cli_abort("Both exposure groups must contain observations.")
  z <- stats::qnorm((1 + conf_level)/2); estimate <- lo <- hi <- NA_real_
  if (type == "risk_difference") {
    estimate <- a/n1 - c/n0; se <- sqrt((a/n1)*(b/n1)/n1 + (c/n0)*(d/n0)/n0); lo <- estimate-z*se; hi <- estimate+z*se
  } else if (type == "risk_ratio") {
    if (c > 0) {estimate <- (a/n1)/(c/n0); if (a > 0) se <- sqrt(1/a - 1/n1 + 1/c - 1/n0)}
  } else if (type == "odds_ratio") {
    if (b > 0 && c > 0) { estimate <- (a*d)/(b*c); if (all(c(a,b,c,d) > 0)) se <- sqrt(sum(1/c(a,b,c,d))) }
  } else {
    t <- column(data, tq, "time"); check_nonnegative(t, "time"); t1 <- sum(t[e == 1]); t0 <- sum(t[e == 0]);
    if (t1 <= 0 || t0 <= 0) cli::cli_abort("Each exposure group must have positive person-time.")
    if (c > 0) { estimate <- (a/t1)/(c/t0); if (a > 0) se <- sqrt(1/a + 1/c) }
  }
  if (type != "risk_difference" && !is.na(estimate) && estimate > 0) { lo <- exp(log(estimate)-z*se); hi <- exp(log(estimate)+z*se) }
  if (is.na(estimate) || is.na(lo)) cli::cli_warn("Estimate or interval is undefined with these zero counts; returning {.val NA} where needed.")
  new_epi_result(tibble::tibble(measure = type, estimate = estimate, conf_low = lo, conf_high = hi, exposed_events = a, exposed_total = n1, unexposed_events = c, unexposed_total = n0))
}
