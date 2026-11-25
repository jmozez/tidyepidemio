#' Kaplan-Meier survival estimates
#'
#' Estimates survival by product-limit with log-log confidence intervals using
#' `survival::survfit()`. Each row is an individual with a non-negative observed
#' follow-up time and binary event indicator. Censoring must be non-informative
#' conditional on group. Events at the same time use the standard Kaplan-Meier
#' risk set. With `entry`, individuals enter the risk set only after their
#' delayed-entry time (left truncation); entry must be independent of survival.
#' Competing risks, weights, clustering, covariate adjustment and
#' continuous-time predictions are not supported.
#' Follow-up times and censoring times share the same units.
#' @param .data An ungrouped data frame with one row per individual.
#' @param time Non-negative observed follow-up time.
#' @param event Binary event indicator, where 1 denotes the event.
#' @param strata Optional group column; defaults to one combined curve.
#' @param entry Optional delayed-entry (left-truncation) time, strictly less
#'   than `time` for every row; defaults to entry at time zero.
#' @param conf_level Confidence level strictly between zero and one.
#' @return Tibble of stratum, event/censor times, risk set, event and censor
#'   counts, estimated survival and log-log confidence limits. The estimate at
#'   time zero before the first event is not added automatically. Confidence
#'   limits may be missing at boundary estimates.
#' @examples
#' d <- data.frame(t = c(1, 2, 3, 4), event = c(1, 0, 1, 0), group = c("a", "a", "b", "b"))
#' epi_kaplan_meier(d, t, event)
#' epi_kaplan_meier(d, t, event, strata = group)
#' @export
epi_kaplan_meier <- function(.data, time, event, strata = NULL, conf_level = 0.95, entry = NULL) {
  check_data(.data)
  t <- column(.data, rlang::enquo(time), "time")
  e <- check_binary(column(.data, rlang::enquo(event), "event"), "event")
  check_nonnegative(t, "time")
  check_probability(conf_level, "conf_level")
  if (!length(t)) cli::cli_abort("{.arg .data} must contain at least one record.")
  sq <- rlang::enquo(strata)
  s <- if (rlang::quo_is_null(sq)) rep("All", length(t)) else column(.data, sq, "strata")
  if (anyNA(s) || !(is.character(s) || is.factor(s) || is.numeric(s) || is.logical(s))) cli::cli_abort("{.arg strata} must be a non-missing atomic grouping variable.")
  s <- as.character(s)
  ids <- unique(s)
  en <- survival_entry(.data, rlang::enquo(entry), t)
  pieces <- lapply(ids, function(id) {
    idx <- which(s == id)
    frame <- data.frame(t = t[idx], event = e[idx])
    if (!is.null(en)) frame$en <- en[idx]
    fit <- survival::survfit(if (is.null(en)) survival::Surv(t, event) ~ 1 else survival::Surv(en, t, event) ~ 1, data = frame, conf.type = "log-log", conf.int = conf_level)
    tibble::tibble(strata = id, time = fit$time, n_risk = fit$n.risk, n_event = fit$n.event, n_censor = fit$n.censor, estimate = fit$surv, conf_low = fit$lower, conf_high = fit$upper)
  })
  dplyr::bind_rows(pieces)
}
survival_entry <- function(.data, q, time) {
  if (rlang::quo_is_null(q)) {
    return(NULL)
  }
  en <- column(.data, q, "entry")
  check_nonnegative(en, "entry")
  if (any(en >= time)) cli::cli_abort("{.arg entry} must be strictly less than the exit time for every row.")
  en
}
