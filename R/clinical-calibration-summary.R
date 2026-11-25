#' Binary prediction calibration and discrimination summary
#'
#' Computes the Brier score, calibration-in-the-large, calibration intercept,
#' calibration slope, and area under the ROC curve. Calibration-in-the-large is
#' the intercept of `logit(P(Y=1)) = intercept + offset(logit(p))`. Calibration
#' intercept and slope are from the joint logistic model
#' `logit(P(Y=1)) = intercept + slope * logit(p)`. Ideal values are zero for
#' both intercepts and one for the slope. AUC uses average ranks for tied
#' predictions. Brier score is the mean squared prediction error.
#'
#' Predictions must be strictly inside (0,1) so logits are finite. Do not
#' silently clip zero or one: a caller choosing to clip must document that
#' modeling decision. Both outcome levels and at least two distinct predictions
#' are required. Complete or quasi-separation can make calibration coefficients
#' unreliable; the function warns but cannot rule it out. No confidence intervals,
#' weights, clustering, missing-data handling or recalibration are provided.
#' Evaluate performance on independent validation data, not the fitting sample.
#' @param .data An ungrouped data frame with one row per individual.
#' @param truth Binary 0/1 event indicator.
#' @param estimate Numeric predicted event probabilities strictly in (0,1).
#' @return One-row tibble with sample size, event prevalence, Brier score,
#'   calibration-in-the-large, calibration intercept and slope, and ROC AUC.
#' @examples
#' d<-data.frame(y=c(0,0,1,0,1,0,1,1),p=c(.1,.2,.3,.4,.5,.6,.7,.8))
#' epi_calibration_summary(d,y,p)
#' @export
epi_calibration_summary <- function(.data, truth, estimate) {
  check_data(.data); y<-check_binary(column(.data,rlang::enquo(truth),"truth"),"truth"); p<-column(.data,rlang::enquo(estimate),"estimate")
  if (length(y)<4 || length(unique(y))<2 || !is.numeric(p) || anyNA(p) || any(!is.finite(p)) || any(p<=0 | p>=1) || length(unique(p))<2) cli::cli_abort("At least four records, both outcome levels, and at least two distinct probabilities strictly in (0,1) are required.")
  frame<-data.frame(y=y,lp=stats::qlogis(p)); fit_safely<-function(form) withCallingHandlers(stats::glm(form,data=frame,family=stats::binomial()),warning=function(w) {cli::cli_warn("Calibration model warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")})
  large<-fit_safely(y~offset(lp)); joint<-fit_safely(y~lp); co<-stats::coef(joint); large_coef<-stats::coef(large)
  if (!large$converged || !joint$converged || length(co)!=2 || anyNA(co) || any(!is.finite(co)) || any(!is.finite(large_coef))) cli::cli_abort("The calibration model is not estimable; inspect outcomes and predictions.")
  if (any(abs(co)>15) || any(stats::fitted(joint)<1e-8 | stats::fitted(joint)>1-1e-8)) cli::cli_warn("Calibration coefficients may be unreliable due to separation or sparse data.")
  n1<-as.double(sum(y==1)); n0<-as.double(sum(y==0)); auc<-(sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0)
  tibble::tibble(n=length(y),event_prevalence=mean(y),brier=mean((y-p)^2),calibration_in_large=unname(large_coef[1]),calibration_intercept=unname(co[1]),calibration_slope=unname(co[2]),roc_auc=auc)
}
