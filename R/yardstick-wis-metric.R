#' Create a WIS metric for yardstick metric sets
#'
#' Constructs a numeric yardstick metric that uses preselected lower and upper
#' interval columns. The selections are resolved against `.data` at creation
#' time and the resulting metric uses those names on each evaluation. This
#' allows WIS to be combined with ordinary numeric metrics that accept only
#' `truth` and `estimate` selections. The same interval columns must be present
#' whenever the metric is evaluated. WIS interpretation and assumptions are
#' identical to [wis()]. Grouping and case weights are supported.
#' @param .data A data frame used to resolve interval column selections.
#' @param lower,upper Tidy selections of lower and upper interval columns, in
#'   corresponding order.
#' @param alpha Numeric vector of distinct miscoverage probabilities, one per
#'   interval, in the same order as the selected columns.
#' @return A `yardstick` numeric metric function. Its result has `.metric`
#'   equal to `"wis"`.
#' @examples
#' d<-data.frame(y=c(1,2),med=c(1,3),lo=c(0,1),hi=c(2,4))
#' interval_score<-wis_metric(d,lo,hi,alpha=.1)
#' metrics<-yardstick::metric_set(yardstick::rmse,interval_score)
#' metrics(d,truth=y,estimate=med)
#' @export
wis_metric <- function(.data, lower, upper, alpha=0.1) {
  if (!is.data.frame(.data)) cli::cli_abort("{.arg .data} must be a data frame.")
  l<-names(tidyselect::eval_select(rlang::enquo(lower),.data,allow_rename=FALSE)); u<-names(tidyselect::eval_select(rlang::enquo(upper),.data,allow_rename=FALSE))
  if (!length(l) || length(l)!=length(u)) cli::cli_abort("Select equal non-zero numbers of lower and upper columns.")
  if (any(!vapply(.data[c(l,u)],is.numeric,logical(1)))) cli::cli_abort("Interval columns must be numeric.")
  if (!is.numeric(alpha) || length(alpha)!=length(l) || anyNA(alpha) || any(!is.finite(alpha)) || any(alpha<=0 | alpha>=1) || anyDuplicated(alpha)) cli::cli_abort("Supply one distinct alpha in (0,1) per interval.")
  metric <- function(data, truth, estimate, na_rm=TRUE, case_weights=NULL, ...) {
    rlang::inject(wis(data, truth=!!rlang::enquo(truth), estimate=!!rlang::enquo(estimate), lower=tidyselect::all_of(l), upper=tidyselect::all_of(u), alpha=alpha, na_rm=na_rm, case_weights=!!rlang::enquo(case_weights)))
  }
  yardstick::new_numeric_metric(metric, direction="minimize")
}
