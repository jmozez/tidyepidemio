#' Covariate balance before and after weighting
#'
#' Computes standardized mean differences (SMDs) between binary exposure groups
#' for numeric covariates and indicators for each observed factor or logical
#' level. Both unweighted and weighted SMDs use the same denominator: the square
#' root of the mean of the two **unweighted sample variances** within exposure
#' groups. The numerator is the exposed mean minus the unexposed mean, before or
#' after separate group normalization of weights. Using a fixed denominator helps
#' avoid apparent balance improvements caused only by changing weighted variance.
#'
#' SMDs are descriptive diagnostics, not tests of exchangeability, positivity,
#' correct model specification or causal validity. They do not diagnose balance
#' of interactions or nonlinear transformations unless supplied as columns, and
#' there is no universally sufficient threshold. Undefined SMDs caused by a zero
#' pooled standard deviation are `NA`; this may indicate severe non-overlap.
#' @param .data An ungrouped data frame of individual observations.
#' @param exposure Binary 0/1 exposure column.
#' @param covariates Tidy selection of complete numeric, factor or logical
#'   covariate columns. Factor and logical variables expand to level indicators.
#' @param weights Optional non-negative numeric weight column. Defaults to equal
#'   weights; each exposure group must have positive total weight.
#' @return A tibble with covariate, level (`NA` for numeric variables),
#'   unweighted and weighted group means, fixed reference standard deviation and
#'   unweighted and weighted SMDs. Exposure 1 minus exposure 0 defines the sign.
#' @examples
#' d<-data.frame(e=c(0,0,1,1),age=c(20,30,30,40),w=c(1,2,2,1))
#' epi_balance(d,e,age,weights=w)
#' @export
epi_balance <- function(.data, exposure, covariates, weights=NULL) {
  check_data(.data); eq<-rlang::enquo(exposure); cq<-rlang::enquo(covariates); wq<-rlang::enquo(weights)
  en<-names(tidyselect::eval_select(eq,.data,allow_rename=FALSE)); if (length(en)!=1L) cli::cli_abort("Select exactly one exposure column.")
  e<-check_binary(.data[[en]],"exposure"); if (sum(e==0)<2 || sum(e==1)<2) cli::cli_abort("Each exposure group must have at least two observations.")
  cols<-names(tidyselect::eval_select(cq,.data,allow_rename=FALSE)); if (!length(cols) || en %in% cols) cli::cli_abort("Select at least one covariate, excluding exposure.")
  w<-if (rlang::quo_is_null(wq)) rep(1,length(e)) else column(.data,wq,"weights"); check_nonnegative(w,"weights")
  if (max(w[e==0])<=0 || max(w[e==1])<=0) cli::cli_abort("Both exposure groups must have positive total weight.")
  w0<-w[e==0]/max(w[e==0]); w1<-w[e==1]/max(w[e==1]); pieces<-list(); missing_sd<-FALSE
  make_row<-function(v,nm,level) {
    a<-v[e==0]; b<-v[e==1]; m0<-mean(a); m1<-mean(b); wm0<-sum(a*w0)/sum(w0); wm1<-sum(b*w1)/sum(w1); ref<-sqrt((stats::var(a)+stats::var(b))/2)
    if (!is.finite(ref) || ref<=0) {missing_sd<<-TRUE; s0<-s1<-NA_real_} else {s0<-(m1-m0)/ref; s1<-(wm1-wm0)/ref}
    tibble::tibble(covariate=nm,level=level,mean_unexposed=m0,mean_exposed=m1,weighted_mean_unexposed=wm0,weighted_mean_exposed=wm1,reference_sd=ref,smd_unweighted=s0,smd_weighted=s1)
  }
  for (nm in cols) {
    v<-.data[[nm]]; if (anyNA(v) || !(is.numeric(v)||is.factor(v)||is.logical(v)) || (is.numeric(v) && any(!is.finite(v)))) cli::cli_abort("Covariate {.field {nm}} must be complete, numeric, factor or logical.")
    if (is.factor(v)||is.logical(v)) {levels_seen<-if (is.factor(v)) levels(droplevels(v)) else as.character(sort(unique(v))); for (lv in levels_seen) pieces[[length(pieces)+1L]]<-make_row(as.numeric(as.character(v)==lv),nm,lv)}
    else pieces[[length(pieces)+1L]]<-make_row(as.numeric(v),nm,NA_character_)
  }
  if (missing_sd) cli::cli_warn("Some reference standard deviations are zero or non-finite; corresponding SMDs are undefined.")
  dplyr::bind_rows(pieces)
}
