#' Bake epidemiological recipe features with explicit history
#'
#' Prep a recipe on training data first. This helper prepends the supplied raw
#' history to the new data, bakes the combined series, and returns only the new
#' rows. This allows the package's lag, rolling and exposure steps to see prior
#' rows at the training/assessment boundary. The helper accepts only a trained
#' recipe whose steps are `step_epi_lags()`, `step_epi_rolling()`,
#' `step_epi_rates()`, or `step_epi_exposure_window()`, with `skip = FALSE`.
#' Other recipe steps are rejected because arbitrary steps may alter row order
#' or have different semantics when history is prepended. The two data frames
#' must have identical column names, represent a single time series, and be
#' strictly sorted; all history times must precede all new times. Time units
#' need not be equally spaced, but lag and window sizes count rows, not elapsed
#' time. The caller must provide enough raw history for all chained steps.
#'
#' This does not alter or store history in a recipe. The recipe must have been
#' prepped without access to future data. `step_epi_rolling()` and
#' `step_epi_exposure_window()` include the current row; they leak information
#' if applied to a target value unavailable at prediction time. Later new rows
#' can also use earlier new-row observations, so a multi-step forecast made all
#' at once must not supply outcomes that would not yet be observed. For grouped
#' series call separately for each group. Row identity is verified through
#' validation of supported steps and the baked row count.
#' @param .data An ungrouped, non-empty data frame of new rows for one series.
#' @param recipe A prepped `recipes` recipe containing only the supported steps.
#' @param history An ungrouped, non-empty data frame of earlier raw observations
#'   with the same columns as `.data`.
#' @param time A single numeric or whole-day Date time column, present in both
#'   datasets and strictly increasing within each.
#' @return A tibble containing only the baked new rows.
#' @examples
#' d<-data.frame(day=1:6,cases=1:6)
#' rec<-recipes::recipe(~.,data=d[1:4,]) |> step_epi_lags(cases,lag=1)
#' prepped<-recipes::prep(rec)
#' epi_bake_history(d[5:6,],prepped,history=d[1:4,],time=day)
#' @export
epi_bake_history <- function(.data, recipe, history, time) {
  check_data(.data); check_data(history)
  if (!nrow(.data) || !nrow(history)) cli::cli_abort("Both {.arg .data} and {.arg history} must contain at least one row.")
  if (!inherits(recipe,"recipe") || !recipes::fully_trained(recipe)) cli::cli_abort("{.arg recipe} must be a prepped recipes recipe.")
  if (any(!vapply(recipe$steps,function(s) inherits(s,"step_epi_features") && isTRUE(s$trained) && identical(s$skip,FALSE),logical(1)))) cli::cli_abort("Only trained epidemiological feature steps with {.code skip = FALSE} are supported.")
  if (anyDuplicated(names(.data)) || anyDuplicated(names(history)) || !setequal(names(.data),names(history))) cli::cli_abort("{.arg .data} and {.arg history} must have the same unique column names.")
  tn<-names(tidyselect::eval_select(rlang::enquo(time),.data,allow_rename=FALSE)); if (length(tn)!=1L) cli::cli_abort("Select exactly one {.arg time} column.")
  t1<-.data[[tn]]; t0<-history[[tn]]; d1<-inherits(t1,"Date"); d0<-inherits(t0,"Date")
  valid<-function(x,date) (date || is.numeric(x)) && !anyNA(x) && all(is.finite(as.numeric(x))) && (!date || all(as.numeric(x)==floor(as.numeric(x))))
  if (d0!=d1 || !valid(t0,d0) || !valid(t1,d1)) cli::cli_abort("Time columns must both be finite numeric or whole-day Date values without missingness.")
  h<-as.numeric(t0); n<-as.numeric(t1); if (any(diff(h)<=0) || any(diff(n)<=0) || utils::tail(h,1)>=n[1]) cli::cli_abort("History and new time must be strictly increasing, with all history preceding all new rows.")
  combined<-dplyr::bind_rows(history,.data); baked<-recipes::bake(recipe,new_data=combined)
  if (nrow(baked)!=nrow(combined)) cli::cli_abort("The recipe changed row count; cannot safely separate history from new rows.")
  baked[seq.int(nrow(history)+1L,nrow(combined)),,drop=FALSE]
}
