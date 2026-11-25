#' Covariate-adjusted Poisson incidence rate ratio
#'
#' Fits a log-link Poisson regression with log person-time as an offset and
#' reports the exponentiated binary exposure coefficient with a normal-Wald
#' confidence interval. Requires independent counts, a correctly specified
#' multiplicative rate model and Poisson variance. The model does not handle
#' overdispersion, recurrent-event dependence, clustered data, weights, missing
#' data, nonlinear terms or interactions. Assess fit and confounding assumptions
#' separately; this is not automatically a causal effect.
#' @param .data Ungrouped data frame with one row per record or aggregated cell.
#' @param events Non-negative integer event counts.
#' @param time Positive person-time or other exposure per row.
#' @param exposure Binary 0/1 exposure column.
#' @param adjust Tidy selection of complete numeric, factor or logical covariates.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble containing the adjusted rate ratio, Wald
#'   confidence limits, event and record counts, and covariate names.
#' @examples
#' d<-data.frame(e=rep(0:1,each=6), events=c(1,2,1,2,3,1,3,4,2,4,5,3),
#'               time=rep(10,12), age=rep(1:3,4))
#' epi_adjusted_rate_ratio(d, events, time, e, adjust=age)
#' @export
epi_adjusted_rate_ratio <- function(.data, events, time, exposure, adjust=c(), conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level"); yq<-rlang::enquo(events); tq<-rlang::enquo(time); eq<-rlang::enquo(exposure); aq<-rlang::enquo(adjust)
  one_name<-function(q,what) {n<-names(tidyselect::eval_select(q,.data,allow_rename=FALSE)); if (length(n)!=1L) cli::cli_abort("Select exactly one column for {.arg {what}}."); n}
  yn<-one_name(yq,"events"); tn<-one_name(tq,"time"); en<-one_name(eq,"exposure"); used<-c(yn,tn,en)
  if (anyDuplicated(used)) cli::cli_abort("Events, time and exposure must be distinct columns.")
  y<-.data[[yn]]; t<-.data[[tn]]; e<-check_binary(.data[[en]],"exposure"); check_nonnegative(y,"events"); check_nonnegative(t,"time",positive=TRUE)
  if (length(y)<4 || any(y!=floor(y)) || sum(y)==0 || length(unique(e))<2) cli::cli_abort("At least four records, integer counts with at least one event, and both exposure levels are required.")
  selected<-names(tidyselect::eval_select(aq,.data,allow_rename=FALSE)); if (any(selected %in% used)) cli::cli_abort("Adjustment columns must exclude events, time and exposure.")
  for (nm in selected) {z<-.data[[nm]]; if (anyNA(z) || !(is.numeric(z) || is.factor(z) || is.logical(z)) || (is.numeric(z) && any(!is.finite(z))) || length(unique(z))<2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor, or logical, and have at least two observed values.")}
  frame<-data.frame(.outcome=y,.exposure=e,.offset=log(t)); for (i in seq_along(selected)) frame[[paste0(".cov",i)]]<-.data[[selected[i]]]
  covs<-if (length(selected)) paste0(".cov",seq_along(selected)) else character()
  form<-stats::reformulate(c(".exposure",covs,"offset(.offset)"),response=".outcome")
  fit<-withCallingHandlers(stats::glm(form,data=frame,family=stats::poisson()),warning=function(w) {cli::cli_warn("Poisson fitting warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")})
  if (!fit$converged || fit$rank<length(stats::coef(fit)) || anyNA(stats::coef(fit))) cli::cli_abort("The Poisson model did not converge or is rank-deficient; revise covariates and inspect overlap.")
  co<-summary(fit)$coefficients; if (!".exposure" %in% rownames(co) || !is.finite(co[".exposure","Std. Error"])) cli::cli_abort("The exposure coefficient or standard error is not estimable.")
  beta<-co[".exposure","Estimate"]; se<-co[".exposure","Std. Error"]; z<-stats::qnorm((1+conf_level)/2)
  if (se>10 || abs(beta)>15) cli::cli_warn("Possible sparse data or separation; Wald inference may be unreliable.")
  new_epi_result(tibble::tibble(measure="adjusted_rate_ratio",estimate=unname(exp(beta)),conf_low=unname(exp(beta-z*se)),conf_high=unname(exp(beta+z*se)),n=length(y),events=sum(y),adjusted_for=paste(selected,collapse=", ")))
}
