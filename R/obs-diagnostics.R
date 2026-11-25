#' Diagnostic test performance
#'
#' Calculates sensitivity, specificity, predictive values, likelihood ratios,
#' and Youden's index from binary test and reference standard observations.
#' Predictive values depend on the prevalence in the supplied sample.
#' @param .data A data frame with one row per subject.
#' @param test Binary index-test result; 1 is positive.
#' @param truth Binary reference status; 1 is diseased.
#' @return A one-row tibble of counts and diagnostic estimates. Undefined
#'   quantities are `NA`.
#' @examples
#' d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
#' epi_diagnostic(d, test, truth)
#' @export
epi_diagnostic <- function(.data, test, truth) {
  check_data(.data); t <- check_binary(column(.data, rlang::enquo(test), "test"), "test"); y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  if (!length(t)) cli::cli_abort("{.arg .data} must have at least one row.")
  tp <- sum(t==1 & y==1); fp <- sum(t==1 & y==0); fn <- sum(t==0 & y==1); tn <- sum(t==0 & y==0)
  sens <- ratio_safe(tp,tp+fn); spec <- ratio_safe(tn,tn+fp)
  tibble::tibble(tp=tp, fp=fp, fn=fn, tn=tn, sensitivity=sens, specificity=spec, ppv=ratio_safe(tp,tp+fp), npv=ratio_safe(tn,tn+fn), lr_positive=ratio_safe(sens,1-spec), lr_negative=ratio_safe(1-sens,spec), youden=sens+spec-1)
}
