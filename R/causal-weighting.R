#' Estimate inverse-probability exposure weights
#'
#' Fits a logistic propensity score model for binary exposure and returns
#' individual inverse-probability weights for the average treatment effect
#' (ATE). Unstabilized weights are `1/p` for exposed and `1/(1-p)` for
#' unexposed individuals. Stabilized weights replace the numerator with the
#' corresponding observed marginal exposure probability. No trimming or
#' clipping is performed. A warning flags extreme fitted propensities; it does
#' not prove adequate overlap when absent. Assess balance, overlap and influential
#' weights before interpreting results.
#'
#' A causal interpretation requires consistency, no unmeasured confounding,
#' positivity, correct treatment-model specification, pre-exposure covariates,
#' and suitable missingness and censoring assumptions. The function supports
#' only complete data, main effects and linear numeric covariates, and does not
#' account for cluster sampling or time-varying treatment. The returned weights
#' alone do not estimate an effect or uncertainty.
#' @param .data An ungrouped data frame of independent individuals.
#' @param exposure Binary 0/1 exposure column.
#' @param adjust Tidy selection of complete numeric, factor, or logical baseline
#'   covariate columns. Defaults to an intercept-only model.
#' @param stabilized Whether to calculate stabilized ATE weights.
#' @return Input tibble with `propensity` and `ipw` columns. Fitted propensities
#'   must lie strictly between zero and one.
#' @examples
#' d<-expand.grid(e=0:1,age=20:24,rep=1:6)
#' d$y<-as.integer(d$rep<=1+d$e+(d$age %% 2))
#' weighted<-epi_propensity_weights(d,e,adjust=age)
#' epi_weighted_effect(weighted,e,y,ipw)
#' @export
epi_propensity_weights <- function(.data, exposure, adjust=c(), stabilized=TRUE) {
  check_data(.data); if (!is.logical(stabilized) || length(stabilized)!=1 || is.na(stabilized)) cli::cli_abort("{.arg stabilized} must be TRUE or FALSE.")
  eq<-rlang::enquo(exposure); aq<-rlang::enquo(adjust); en<-names(tidyselect::eval_select(eq,.data,allow_rename=FALSE))
  if (length(en)!=1) cli::cli_abort("Select exactly one exposure column.")
  e<-check_binary(.data[[en]],"exposure"); if (length(e)<4 || length(unique(e))<2) cli::cli_abort("At least four observations and both exposure levels are required.")
  if (any(c("propensity","ipw") %in% names(.data))) cli::cli_abort("Output columns already exist; rename them before estimating weights.")
  cols<-names(tidyselect::eval_select(aq,.data,allow_rename=FALSE)); if (en %in% cols) cli::cli_abort("Adjustment columns must exclude exposure.")
  for (nm in cols) {v<-.data[[nm]]; if (anyNA(v) || !(is.numeric(v)||is.factor(v)||is.logical(v)) || (is.numeric(v) && any(!is.finite(v))) || length(unique(v))<2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor or logical, and have at least two observed values.")}
  dat<-data.frame(.exposure=e); for (j in seq_along(cols)) dat[[paste0(".cov",j)]]<-.data[[cols[j]]]
  covs<-if (length(cols)) paste0(".cov",seq_along(cols)) else "1"; form<-stats::reformulate(covs,response=".exposure")
  fit<-withCallingHandlers(stats::glm(form,data=dat,family=stats::binomial()),warning=function(w) {cli::cli_warn("Propensity model warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")})
  if (!fit$converged || fit$rank<length(stats::coef(fit)) || anyNA(stats::coef(fit))) cli::cli_abort("The propensity model did not converge or is rank-deficient; inspect covariates and overlap.")
  p<-unname(stats::fitted(fit)); if (any(!is.finite(p) | p<=0 | p>=1)) cli::cli_abort("Propensities at zero or one give undefined weights; inspect separation and overlap.")
  if (any(p<.01 | p>.99)) cli::cli_warn("Some fitted propensities are below 0.01 or above 0.99; investigate overlap and weight stability.")
  marginal<-mean(e); weight<-ifelse(e==1,if (stabilized) marginal/p else 1/p,if (stabilized) (1-marginal)/(1-p) else 1/(1-p))
  if (any(!is.finite(weight))) cli::cli_abort("Estimated weights are not finite; inspect overlap.")
  out<-tibble::as_tibble(.data); out$propensity<-p; out$ipw<-weight; out
}
#' Weighted marginal risks and contrasts
#'
#' Computes separately normalized (Hájek) weighted risks for the exposed and
#' unexposed groups, their difference, and their ratio. Effective sample sizes
#' are `(sum w)^2 / sum(w^2)` within each group. No uncertainty interval is
#' returned: naïve intervals treating estimated weights as fixed ignore
#' propensity-score estimation and can be misleading. This function does not
#' test covariate balance or establish a causal interpretation.
#' @param .data A data frame of individual records.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param weights Non-negative numeric weights, with a positive total in each
#'   exposure group. Zero weights are allowed.
#' @return A one-row tibble with group risks, risk difference, risk ratio,
#'   effective sample sizes and original sample size. An undefined ratio is `NA`.
#' @examples
#' d<-data.frame(e=c(0,0,1,1),y=c(0,1,1,1),w=c(1,1,2,1))
#' epi_weighted_effect(d,e,y,w)
#' @export
epi_weighted_effect <- function(.data, exposure, outcome, weights) {
  check_data(.data); e<-check_binary(column(.data,rlang::enquo(exposure),"exposure"),"exposure"); y<-check_binary(column(.data,rlang::enquo(outcome),"outcome"),"outcome"); w<-column(.data,rlang::enquo(weights),"weights"); check_nonnegative(w,"weights")
  if (!length(e) || length(unique(e))<2) cli::cli_abort("Both exposure groups must contain observations.")
  summarize_group<-function(id) {g<-e==id; ww<-w[g]; if (max(ww)<=0) cli::cli_abort("Both exposure groups must have positive total weight."); ww<-ww/max(ww); c(risk=sum(ww*y[g])/sum(ww),ess=sum(ww)^2/sum(ww^2))}
  zero<-summarize_group(0); one<-summarize_group(1); ratio<-if (zero["risk"]==0) NA_real_ else unname(one["risk"]/zero["risk"])
  if (is.na(ratio)) cli::cli_warn("The unexposed weighted risk is zero; the risk ratio is undefined.")
  tibble::tibble(risk_unexposed=unname(zero["risk"]),risk_exposed=unname(one["risk"]),risk_difference=unname(one["risk"]-zero["risk"]),risk_ratio=ratio,ess_unexposed=unname(zero["ess"]),ess_exposed=unname(one["ess"]),n=length(y))
}
