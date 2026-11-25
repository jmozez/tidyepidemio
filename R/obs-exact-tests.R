#' Fisher's exact test for binary exposure and outcome
#'
#' Applies Fisher's conditional exact test to an individual-level 2 by 2 table.
#' The reported odds ratio is the conditional maximum-likelihood estimate from
#' `stats::fisher.test()`, not necessarily the sample cross-product odds ratio.
#' The confidence interval is an exact conditional interval; one-sided limits
#' may be zero or infinite. Both exposure and outcome levels must be present.
#' The test conditions on observed margins and does not adjust for confounding,
#' clustering or multiple testing. Significance does not establish causality.
#' @param .data An ungrouped data frame of individual records.
#' @param exposure Binary 0/1 exposure indicator.
#' @param outcome Binary 0/1 outcome indicator.
#' @param alternative `"two.sided"`, `"less"` or `"greater"`, referring to the
#'   exposed versus unexposed odds ratio.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble with conditional odds ratio, limits, p-value,
#'   and cell counts. Infinite limits and estimates are possible.
#' @examples
#' d<-data.frame(e=rep(0:1,each=4),y=c(0,0,0,1,0,1,1,1))
#' epi_fisher_test(d,e,y)
#' @export
epi_fisher_test <- function(.data, exposure, outcome, alternative=c("two.sided","less","greater"), conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level"); alternative<-match.arg(alternative)
  e<-check_binary(column(.data,rlang::enquo(exposure),"exposure"),"exposure"); y<-check_binary(column(.data,rlang::enquo(outcome),"outcome"),"outcome")
  if (!length(e) || length(unique(e))<2 || length(unique(y))<2) cli::cli_abort("Both exposure and outcome levels must be present.")
  a<-sum(e==1 & y==1); b<-sum(e==1 & y==0); c<-sum(e==0 & y==1); d<-sum(e==0 & y==0); mat<-matrix(c(a,b,c,d),nrow=2,byrow=TRUE)
  result<-tryCatch(stats::fisher.test(mat,alternative=alternative,conf.level=conf_level),error=function(err) cli::cli_abort("Fisher test failed: {conditionMessage(err)}"))
  new_epi_result(tibble::tibble(measure="fisher_odds_ratio",estimate=unname(result$estimate),conf_low=unname(result$conf.int[1]),conf_high=unname(result$conf.int[2]),p_value=result$p.value,alternative=alternative,exposed_events=a,exposed_non_events=b,unexposed_events=c,unexposed_non_events=d))
}
#' Mantel-Haenszel test and confidence interval
#'
#' Calculates the asymptotic Cochran-Mantel-Haenszel test for conditional
#' association between binary exposure and outcome given strata, together with
#' the Mantel-Haenszel common odds ratio and its approximate confidence interval.
#' `correction=TRUE` applies the continuity correction to the test statistic.
#' Assumes independent records and a sufficiently informative set of strata;
#' the common odds ratio is most interpretable when stratum odds ratios are
#' reasonably homogeneous. The test itself does not test homogeneity, adjust for
#' other confounders, or establish causality.
#' @param .data An ungrouped data frame of individual records.
#' @param exposure Binary 0/1 exposure indicator.
#' @param outcome Binary 0/1 outcome indicator.
#' @param strata Non-missing categorical or numeric stratum column.
#' @param correction Whether to use a continuity correction.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble with common odds ratio, confidence limits,
#'   chi-squared statistic, p-value and number of strata.
#' @examples
#' d<-data.frame(e=rep(c(0,0,1,1),2),y=rep(c(0,1,0,1),2),s=rep(1:2,each=4))
#' epi_mantel_haenszel_test(d,e,y,s)
#' @export
epi_mantel_haenszel_test <- function(.data, exposure, outcome, strata, correction=FALSE, conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level"); if (!is.logical(correction) || length(correction)!=1 || is.na(correction)) cli::cli_abort("{.arg correction} must be TRUE or FALSE.")
  e<-check_binary(column(.data,rlang::enquo(exposure),"exposure"),"exposure"); y<-check_binary(column(.data,rlang::enquo(outcome),"outcome"),"outcome"); s<-column(.data,rlang::enquo(strata),"strata")
  if (!length(e) || length(unique(e))<2 || length(unique(y))<2 || anyNA(s) || !(is.character(s)||is.factor(s)||is.logical(s)||is.numeric(s)) || (is.numeric(s) && any(!is.finite(s)))) cli::cli_abort("Both exposure and outcome levels and complete finite strata are required.")
  result<-tryCatch(withCallingHandlers(stats::mantelhaen.test(factor(e,levels=c(1,0)),factor(y,levels=c(1,0)),factor(s),correct=correction,conf.level=conf_level),warning=function(w) {cli::cli_warn("Mantel-Haenszel test warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")}),error=function(err) cli::cli_abort("Mantel-Haenszel test failed: {conditionMessage(err)}"))
  if (anyNA(c(result$statistic,result$p.value,result$estimate,result$conf.int))) cli::cli_abort("The common odds ratio or test is not estimable; inspect within-stratum exposure and outcome variation.")
  new_epi_result(tibble::tibble(measure="mantel_haenszel_odds_ratio",estimate=unname(result$estimate),conf_low=unname(result$conf.int[1]),conf_high=unname(result$conf.int[2]),statistic=unname(result$statistic),p_value=result$p.value,strata=length(unique(s)),correction=correction))
}
