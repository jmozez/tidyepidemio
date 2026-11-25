#' Cumulative incidence with competing risks
#'
#' Uses the Aalen-Johansen product-limit estimator for one event cause.
#' At each event time, increments the target cumulative incidence by survival
#' just before the time multiplied by target events divided by the risk set;
#' survival is then updated for all event causes. Censored individuals at a
#' given time remain in the risk set for events at that time.
#'
#' Confidence limits come from the Aalen-Johansen variance computed by
#' `survival::survfit()` for a multi-state outcome, on the log scale; they can be
#' unreliable with few events. With `entry`, individuals join the risk set only
#' after their delayed-entry time (left truncation), which must be independent
#' of the event processes. Assumes independent censoring within strata; there
#' is no covariate adjustment. Treating competing
#' events as ordinary censoring in Kaplan-Meier would not estimate this quantity.
#' @param .data An ungrouped data frame of independent individuals.
#' @param time Non-negative follow-up or exit time.
#' @param status Non-negative integer event code: 0 means censored, and every
#'   positive value denotes a distinct event cause.
#' @param cause Positive integer code identifying the event of interest.
#' @param strata Optional complete grouping column; defaults to one curve.
#' @param conf_level Confidence level strictly between zero and one.
#' @param entry Optional delayed-entry (left-truncation) time, strictly less
#'   than `time` for every row; defaults to entry at time zero.
#' @return A tibble of stratum, observed times, risk set, target and competing
#'   event counts, censor counts, event-free survival, and target cumulative
#'   incidence with confidence limits. The pre-event time-zero row is not inserted automatically.
#' @examples
#' d<-data.frame(time=1:4,status=c(1,2,0,1))
#' epi_cumulative_incidence(d,time,status,cause=1)
#' @export
epi_cumulative_incidence <- function(.data, time, status, cause=1L, strata=NULL, conf_level=0.95, entry=NULL) {
  check_probability(conf_level,"conf_level")
  check_data(.data); t<-column(.data,rlang::enquo(time),"time"); s<-column(.data,rlang::enquo(status),"status"); check_nonnegative(t,"time"); check_nonnegative(s,"status"); check_window(cause,"cause")
  if (!length(t) || any(s!=floor(s))) cli::cli_abort("At least one record and non-negative integer status codes are required.")
  sq<-rlang::enquo(strata); g<-if (rlang::quo_is_null(sq)) rep("All",length(t)) else column(.data,sq,"strata")
  if (anyNA(g) || !(is.character(g) || is.factor(g) || is.numeric(g) || is.logical(g))) cli::cli_abort("{.arg strata} must be a non-missing atomic grouping variable.")
  g<-as.character(g); ids<-unique(g); en<-survival_entry(.data, rlang::enquo(entry), t)
  pieces<-lapply(ids,function(id) {
    idx<-which(g==id); tt<-t[idx]; ss<-s[idx]; times<-sort(unique(tt)); bin<-match(tt,times)
    ee<-if (is.null(en)) rep(0,length(tt)) else en[idx]
    nr<-vapply(times,function(u) sum(tt>=u & (is.null(en) | ee<u)),numeric(1))
    counts<-rowsum(cbind(target=as.numeric(ss==cause),comp=as.numeric(ss>0 & ss!=cause),censor=as.numeric(ss==0)), group=bin, reorder=TRUE)
    target<-unname(counts[,"target"]); comp<-unname(counts[,"comp"]); censor<-unname(counts[,"censor"])
    nr_safe<-ifelse(nr>0,nr,1)
    surv<-cumprod(1-(target+comp)/nr_safe); inc<-cumsum(c(1,utils::head(surv,-1))*target/nr_safe)
    ci<-cif_limits(tt,ss,if (is.null(en)) NULL else ee,cause,times,conf_level)
    tibble::tibble(strata=id,time=times,n_risk=nr,n_target=target,n_competing=comp,n_censor=censor,event_free_survival=surv,cumulative_incidence=inc,conf_low=ci$lower,conf_high=ci$upper)
  })
  dplyr::bind_rows(pieces)
}
cif_limits <- function(tt, ss, ee, cause, times, conf_level) {
  none <- list(lower = rep(NA_real_, length(times)), upper = rep(NA_real_, length(times)))
  if (!any(ss == cause)) return(none)
  st <- factor(ss, levels = c(0, sort(unique(ss[ss > 0]))))
  fr <- data.frame(tt = tt, st = st, ee = if (is.null(ee)) 0 else ee, id = seq_along(tt))
  fit <- if (is.null(ee)) survival::survfit(survival::Surv(tt, st) ~ 1, data = fr, conf.int = conf_level) else survival::survfit(survival::Surv(ee, tt, st) ~ 1, data = fr, id = id, conf.int = conf_level)
  col <- match(as.character(cause), fit$states)
  if (is.na(col)) return(none)
  m <- match(times, fit$time)
  list(lower = fit$lower[m, col], upper = fit$upper[m, col])
}
