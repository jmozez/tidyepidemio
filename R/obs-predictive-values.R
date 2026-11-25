#' Predictive values at specified disease prevalences
#'
#' Estimates sensitivity and specificity from the supplied test/reference data,
#' then uses Bayes' rule to calculate positive and negative predictive values at
#' each specified target prevalence. Both diseased and non-diseased subjects are
#' required in the reference data. The method assumes that sensitivity and
#' specificity transport unchanged to the target setting and that the supplied
#' prevalence is appropriate. Spectrum effects, imperfect reference standards,
#' verification bias and uncertainty in prevalence or test accuracy are not
#' addressed. Intervals are not calculated.
#' @param .data An ungrouped data frame of individual test observations.
#' @param test Binary test indicator, where 1 denotes a positive result.
#' @param truth Binary reference disease indicator, where 1 denotes disease.
#' @param prevalence Numeric vector of distinct target prevalences in `[0,1]`.
#' @return A tibble with each target prevalence, sample sensitivity and
#'   specificity, and implied positive and negative predictive values. A zero
#'   probability of a positive or negative test yields the corresponding `NA`.
#' @examples
#' d<-data.frame(test=c(1,1,0,0),truth=c(1,0,1,0))
#' epi_predictive_values(d,test,truth,prevalence=c(.01,.1,.5))
#' @export
epi_predictive_values <- function(.data, test, truth, prevalence) {
  check_data(.data); t<-check_binary(column(.data,rlang::enquo(test),"test"),"test"); y<-check_binary(column(.data,rlang::enquo(truth),"truth"),"truth")
  if (!length(y) || length(unique(y))<2) cli::cli_abort("Both diseased and non-diseased reference subjects are required.")
  if (!is.numeric(prevalence) || !length(prevalence) || anyNA(prevalence) || any(!is.finite(prevalence)) || any(prevalence<0 | prevalence>1) || anyDuplicated(prevalence)) cli::cli_abort("{.arg prevalence} must contain distinct finite values between zero and one.")
  sens<-mean(t[y==1]); spec<-mean(1-t[y==0]); positive<-sens*prevalence+(1-spec)*(1-prevalence); negative<-(1-sens)*prevalence+spec*(1-prevalence)
  ppv<-rep(NA_real_,length(prevalence)); npv<-ppv; okp<-positive>0; okn<-negative>0; ppv[okp]<-sens*prevalence[okp]/positive[okp]; npv[okn]<-spec*(1-prevalence[okn])/negative[okn]
  if (any(!okp) || any(!okn)) cli::cli_warn("A test-result probability is zero at some prevalence; the corresponding predictive value is undefined.")
  tibble::tibble(prevalence=prevalence,sensitivity=sens,specificity=spec,ppv=ppv,npv=npv)
}
