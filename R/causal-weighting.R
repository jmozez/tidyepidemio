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
#' are `(sum w)^2 / sum(w^2)` within each group. With `bootstrap > 0`, records
#' are resampled with their supplied weights held fixed and percentile intervals
#' are returned for the risk difference and ratio. Holding estimated propensity
#' weights fixed ignores their estimation; for inverse-probability weights this
#' usually makes intervals conservative. Use [epi_ipw()] to re-estimate the
#' propensity model in every resample. This function does not test covariate
#' balance or establish a causal interpretation.
#' @param .data A data frame of individual records.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param weights Non-negative numeric weights, with a positive total in each
#'   exposure group. Zero weights are allowed.
#' @param bootstrap Number of individual bootstrap resamples: 0 (no
#'   intervals) or an integer from 100 to 2000.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A one-row tibble with group risks, risk difference, risk ratio,
#'   effective sample sizes and original sample size, plus percentile limits
#'   for the difference and ratio when bootstrapping. An undefined ratio is `NA`.
#' @examples
#' d<-data.frame(e=c(0,0,1,1),y=c(0,1,1,1),w=c(1,1,2,1))
#' epi_weighted_effect(d,e,y,w)
#' @export
epi_weighted_effect <- function(.data, exposure, outcome, weights, bootstrap=0L, conf_level=0.95) {
  check_data(.data); e<-check_binary(column(.data,rlang::enquo(exposure),"exposure"),"exposure"); y<-check_binary(column(.data,rlang::enquo(outcome),"outcome"),"outcome"); w<-column(.data,rlang::enquo(weights),"weights"); check_nonnegative(w,"weights")
  if (!length(e) || length(unique(e))<2) cli::cli_abort("Both exposure groups must contain observations.")
  check_probability(conf_level,"conf_level")
  if (!is.numeric(bootstrap) || length(bootstrap)!=1 || is.na(bootstrap) || bootstrap!=floor(bootstrap) || !(bootstrap==0 || (bootstrap>=100 && bootstrap<=2000))) cli::cli_abort("{.arg bootstrap} must be 0 or an integer from 100 to 2000.")
  summarize_group<-function(id) {g<-e==id; ww<-w[g]; if (max(ww)<=0) cli::cli_abort("Both exposure groups must have positive total weight."); ww<-ww/max(ww); c(risk=sum(ww*y[g])/sum(ww),ess=sum(ww)^2/sum(ww^2))}
  zero<-summarize_group(0); one<-summarize_group(1); ratio<-if (zero["risk"]==0) NA_real_ else unname(one["risk"]/zero["risk"])
  if (is.na(ratio)) cli::cli_warn("The unexposed weighted risk is zero; the risk ratio is undefined.")
  out<-tibble::tibble(risk_unexposed=unname(zero["risk"]),risk_exposed=unname(one["risk"]),risk_difference=unname(one["risk"]-zero["risk"]),risk_ratio=ratio,ess_unexposed=unname(zero["ess"]),ess_exposed=unname(one["ess"]),n=length(y))
  if (bootstrap>0) out<-dplyr::bind_cols(out,weighted_effect_boot(e,y,w,bootstrap,conf_level,is.na(ratio)))
  out
}
weighted_effect_boot <- function(e, y, w, bootstrap, conf_level, ratio_undefined) {
  n <- length(y); boot <- matrix(NA_real_, bootstrap, 2)
  for (i in seq_len(bootstrap)) {
    k <- sample.int(n, n, replace = TRUE); ek <- e[k]; yk <- y[k]; wk <- w[k]
    w0 <- wk[ek == 0]; w1 <- wk[ek == 1]
    if (!length(w0) || !length(w1) || sum(w0) <= 0 || sum(w1) <= 0) next
    r0 <- sum(w0 * yk[ek == 0]) / sum(w0); r1 <- sum(w1 * yk[ek == 1]) / sum(w1)
    boot[i, ] <- c(r1 - r0, if (r0 > 0) r1 / r0 else NA_real_)
  }
  ok <- sum(is.finite(boot[, 1])); failed <- bootstrap - ok
  if (failed > 0.1 * bootstrap) cli::cli_abort("{failed} of {bootstrap} resamples lacked an exposure group with positive weight; intervals are not reported.")
  if (failed > 0) cli::cli_warn("{failed} of {bootstrap} resamples lacked an exposure group with positive weight and were omitted.")
  a <- 1 - conf_level; q <- function(x) stats::quantile(x, c(a / 2, 1 - a / 2), na.rm = TRUE, names = FALSE)
  rd <- q(boot[, 1]); rr <- if (ratio_undefined || any(!is.finite(boot[is.finite(boot[, 1]), 2]))) c(NA_real_, NA_real_) else q(boot[, 2])
  tibble::tibble(risk_difference_low = rd[1], risk_difference_high = rd[2], risk_ratio_low = rr[1], risk_ratio_high = rr[2],
                 bootstrap = as.integer(bootstrap), bootstrap_success = as.integer(ok))
}
