#' Confidence interval for a binary proportion
#'
#' Calculates a Wilson score or Clopper-Pearson exact binomial confidence
#' interval. The interval assumes independent, identically distributed Bernoulli
#' outcomes; it does not account for clustering, survey design, or weights.
#' @param .data A data frame containing independent individual records.
#' @param event Binary 0/1 or logical event indicator, with no missing values.
#' @param conf_level Confidence level strictly between zero and one.
#' @param method Either `"wilson"` or `"exact"`.
#' @return A one-row tibble with events, total, estimate and confidence limits.
#' @examples
#' epi_proportion_ci(data.frame(event=c(1,1,0,0,0)), event)
#' epi_proportion_ci(data.frame(event=c(1,1,0,0,0)), event, method="exact")
#' @export
epi_proportion_ci <- function(.data, event, conf_level=0.95, method=c("wilson","exact")) {
  check_data(.data); x<-check_binary(column(.data,rlang::enquo(event),"event"),"event"); n<-length(x)
  if (!n) cli::cli_abort("{.arg .data} must contain at least one observation.")
  check_probability(conf_level,"conf_level"); method<-match.arg(method); count<-sum(x); p<-count/n
  if (method=="exact") { ci<-stats::binom.test(count,n,conf.level=conf_level)$conf.int; lo<-ci[1]; hi<-ci[2] }
  else {
    z<-stats::qnorm((1+conf_level)/2); den<-1+z^2/n; center<-(p+z^2/(2*n))/den
    half<-z*sqrt(p*(1-p)/n+z^2/(4*n^2))/den; lo<-max(0,center-half); hi<-min(1,center+half)
  }
  tibble::tibble(events=count,total=n,estimate=p,conf_low=unname(lo),conf_high=unname(hi),conf_level=conf_level,method=method)
}
#' Exact Poisson confidence interval for an incidence rate
#'
#' Uses the exact chi-squared interval for the count assuming a Poisson model
#' with fixed total person-time. This does not handle overdispersion, recurrent
#' event dependence, or complex sampling. A count of zero has a lower bound of
#' zero and a positive upper bound.
#' @param .data A data frame containing individual records or count totals.
#' @param events Non-negative integer event counts per row.
#' @param time Non-negative person-time per row; total must be positive.
#' @param conf_level Confidence level strictly between zero and one.
#' @param multiplier Positive scaling factor for the rate and limits.
#' @return A one-row tibble with counts, person-time, estimate and limits.
#' @examples
#' epi_rate_ci(data.frame(events=c(1,2,0), time=c(2,3,1)), events, time, multiplier=100)
#' @export
epi_rate_ci <- function(.data, events, time, conf_level=0.95, multiplier=1) {
  check_data(.data); y<-column(.data,rlang::enquo(events),"events"); t<-column(.data,rlang::enquo(time),"time")
  check_nonnegative(y,"events"); check_nonnegative(t,"time"); check_scalar(multiplier,"multiplier"); check_probability(conf_level,"conf_level")
  if (!length(y) || any(y!=floor(y))) cli::cli_abort("{.arg events} must contain integer counts and at least one record.")
  total<-sum(t); if (total<=0) cli::cli_abort("Total person-time must be positive.")
  count<-sum(y); alpha<-1-conf_level; lo<-if (count==0) 0 else stats::qchisq(alpha/2,2*count)/2; hi<-stats::qchisq(1-alpha/2,2*(count+1))/2
  tibble::tibble(events=count,person_time=total,estimate=count/total*multiplier,conf_low=lo/total*multiplier,conf_high=hi/total*multiplier,conf_level=conf_level)
}
check_probability <- function(x,name) {check_scalar(x,name); if (x>=1) cli::cli_abort("{.arg {name}} must be strictly less than one.")}
