#' Cumulative incidence with competing risks
#'
#' Uses the Aalen-Johansen product-limit estimator for one event cause.
#' At each event time, increments the target cumulative incidence by survival
#' just before the time multiplied by target events divided by the risk set;
#' survival is then updated for all event causes. Censored individuals at a
#' given time remain in the risk set for events at that time.
#'
#' Assumes independent censoring within strata. No left truncation, adjustment,
#' standard errors or confidence intervals are provided. Treating competing
#' events as ordinary censoring in Kaplan-Meier would not estimate this quantity.
#' @param .data An ungrouped data frame of independent individuals.
#' @param time Non-negative follow-up or exit time.
#' @param status Non-negative integer event code: 0 means censored, and every
#'   positive value denotes a distinct event cause.
#' @param cause Positive integer code identifying the event of interest.
#' @param strata Optional complete grouping column; defaults to one curve.
#' @return A tibble of stratum, observed times, risk set, target and competing
#'   event counts, censor counts, event-free survival, and target cumulative
#'   incidence. The pre-event time-zero row is not inserted automatically.
#' @examples
#' d<-data.frame(time=1:4,status=c(1,2,0,1))
#' epi_cumulative_incidence(d,time,status,cause=1)
#' @export
epi_cumulative_incidence <- function(.data, time, status, cause=1L, strata=NULL) {
  check_data(.data); t<-column(.data,rlang::enquo(time),"time"); s<-column(.data,rlang::enquo(status),"status"); check_nonnegative(t,"time"); check_nonnegative(s,"status"); check_window(cause,"cause")
  if (!length(t) || any(s!=floor(s))) cli::cli_abort("At least one record and non-negative integer status codes are required.")
  sq<-rlang::enquo(strata); g<-if (rlang::quo_is_null(sq)) rep("All",length(t)) else column(.data,sq,"strata")
  if (anyNA(g) || !(is.character(g) || is.factor(g) || is.numeric(g) || is.logical(g))) cli::cli_abort("{.arg strata} must be a non-missing atomic grouping variable.")
  g<-as.character(g); ids<-unique(g)
  pieces<-lapply(ids,function(id) {
    idx<-which(g==id); tt<-t[idx]; ss<-s[idx]; times<-sort(unique(tt)); bin<-match(tt,times)
    totals<-tabulate(bin,nbins=length(times)); nr<-length(tt)-c(0,utils::head(cumsum(totals),-1))
    counts<-rowsum(cbind(target=as.numeric(ss==cause),comp=as.numeric(ss>0 & ss!=cause),censor=as.numeric(ss==0)), group=bin, reorder=TRUE)
    target<-unname(counts[,"target"]); comp<-unname(counts[,"comp"]); censor<-unname(counts[,"censor"])
    surv<-cumprod(1-(target+comp)/nr); inc<-cumsum(c(1,utils::head(surv,-1))*target/nr)
    tibble::tibble(strata=id,time=times,n_risk=nr,n_target=target,n_competing=comp,n_censor=censor,event_free_survival=surv,cumulative_incidence=inc)
  })
  dplyr::bind_rows(pieces)
}
