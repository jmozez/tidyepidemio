#' Covariate-adjusted odds ratio
#'
#' Fits a binomial logistic regression with a binary exposure and selected
#' covariates using maximum likelihood, reporting the exponentiated exposure
#' coefficient with a normal-Wald confidence interval. Categorical covariates
#' must be factors or logicals; continuous covariates enter linearly. This is a
#' conditional odds ratio, not a risk ratio, and can differ from a marginal odds
#' ratio even without confounding. It is not automatically a causal effect.
#' Complete data, independent observations, a correctly specified model,
#' adequate overlap and no serious separation are required; sparse data can
#' render estimates and Wald intervals unreliable. No weights, robust standard
#' errors, missing-data handling, interactions or nonlinear terms are provided.
#' @param .data A data frame with one row per individual.
#' @param exposure Binary exposure column, coded 0/1.
#' @param outcome Binary outcome column, coded 0/1.
#' @param adjust Tidy selection of covariate columns, such as `c(age, sex)`;
#'   defaults to none. Each must be numeric, factor, or logical and complete.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble with the exposure odds ratio, confidence
#'   limits, sample size and adjusted covariate names.
#' @examples
#' d <- data.frame(e=rep(0:1,each=20), y=rep(c(0,1,0,0,1),8),
#'                 age=rep(20:29,4))
#' epi_adjusted_odds_ratio(d, e, y, adjust=age)
#' @export
epi_adjusted_odds_ratio <- function(.data, exposure, outcome, adjust=c(), conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level"); eq<-rlang::enquo(exposure); oq<-rlang::enquo(outcome); aq<-rlang::enquo(adjust)
  ename<-names(tidyselect::eval_select(eq,.data,allow_rename=FALSE)); oname<-names(tidyselect::eval_select(oq,.data,allow_rename=FALSE))
  if (length(ename)!=1 || length(oname)!=1 || identical(ename,oname)) cli::cli_abort("Select distinct single exposure and outcome columns.")
  e<-check_binary(.data[[ename]],"exposure"); y<-check_binary(.data[[oname]],"outcome")
  if (length(e)<4 || length(unique(e))<2 || length(unique(y))<2) cli::cli_abort("Both exposure and outcome levels and at least four records are required.")
  selected<-names(tidyselect::eval_select(aq,.data,allow_rename=FALSE)); if (any(selected %in% c(ename,oname))) cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  for (nm in selected) {
    z<-.data[[nm]]
    if (anyNA(z) || !(is.numeric(z) || is.factor(z) || is.logical(z)) || (is.numeric(z) && any(!is.finite(z))) || length(unique(z))<2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor, or logical, and have at least two observed values.")
  }
  frame<-data.frame(.outcome=y,.exposure=e); for (i in seq_along(selected)) frame[[paste0(".cov",i)]]<-.data[[selected[i]]]
  cov_names<-if (length(selected)) paste0(".cov",seq_along(selected)) else character()
  form<-stats::reformulate(c(".exposure",cov_names),response=".outcome")
  fit<-withCallingHandlers(stats::glm(form,data=frame,family=stats::binomial()),warning=function(w) {cli::cli_warn("Logistic fitting warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")})
  if (!fit$converged || fit$rank<length(stats::coef(fit)) || anyNA(stats::coef(fit))) cli::cli_abort("The logistic model did not converge or is rank-deficient; revise covariates and inspect overlap.")
  co<-summary(fit)$coefficients; if (!".exposure" %in% rownames(co) || !is.finite(co[".exposure","Std. Error"])) cli::cli_abort("The exposure coefficient or standard error is not estimable.")
  beta<-co[".exposure","Estimate"]; se<-co[".exposure","Std. Error"]; z<-stats::qnorm((1+conf_level)/2)
  if (se>10 || any(stats::fitted(fit)<1e-8 | stats::fitted(fit)>1-1e-8)) cli::cli_warn("Possible separation or sparse data; Wald estimates and intervals may be unreliable.")
  new_epi_result(tibble::tibble(measure="adjusted_odds_ratio",estimate=unname(exp(beta)),conf_low=unname(exp(beta-z*se)),conf_high=unname(exp(beta+z*se)),n=length(y),adjusted_for=paste(selected,collapse=", ")))
}
