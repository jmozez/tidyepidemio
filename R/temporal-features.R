#' Past-only temporal features with explicit history
#'
#' Creates row-lag and past-window-mean features for numeric columns in `.data`.
#' Optional `history` supplies earlier observations for the same groups and is
#' used only as context; history rows are not returned. For each row, the lag is
#' the value `lag` rows earlier, and the rolling mean uses the `window` rows
#' immediately before the row, excluding the current value. Incomplete history
#' or any missing value in the rolling window yields `NA`. Features are based on
#' **rows**, not elapsed duration; no regular time spacing is inferred or filled.
#'
#' Within each group, time must be strictly increasing in both input datasets,
#' and all matched history times must precede all `.data` times. Groups may be
#' interleaved; output preserves `.data` order. History for groups absent from
#' `.data` is ignored. `time` is numeric or a whole-day Date, with the same kind
#' in both datasets. Missing feature values are permitted and propagated.
#'
#' This helper is outside `recipes`: it does not change the existing recipe
#' steps' history behavior. For sequential one-step-ahead scoring it may use
#' earlier observed values within `.data`. For a multi-step forecast made all at
#' once, those later outcomes are not yet known; supplying them would leak future
#' information. Supply only values actually available at each prediction time.
#' @param .data An ungrouped data frame of new observations in time order within
#'   each group.
#' @param ... Tidy selection of one or more numeric feature columns.
#' @param time A single numeric or Date time column, strictly increasing within
#'   each group in both `.data` and `history`.
#' @param group Optional complete character, factor, logical, or numeric group
#'   column. With no group all rows form a single series.
#' @param history Optional earlier data frame containing the selected features,
#'   time, and group columns with compatible types.
#' @param lag Positive integer number of preceding rows to lag.
#' @param window Positive integer number of preceding rows in the rolling mean.
#' @return Input tibble in original order with `lag{lag}_<column>` and
#'   `past_mean{window}_<column>` columns. Existing output names are rejected.
#' @examples
#' history <- data.frame(day = 1:3, cases = c(1, 2, 3))
#' new <- data.frame(day = 4:5, cases = c(4, 5))
#' epi_temporal_features(new, cases, time = day, history = history, lag = 1, window = 2)
#' @export
epi_temporal_features <- function(.data, ..., time, group = NULL, history = NULL, lag = 1L, window = 7L) {
  check_data(.data)
  check_window(lag, "lag")
  check_window(window, "window")
  terms <- rlang::enquos(...)
  tq <- rlang::enquo(time)
  gq <- rlang::enquo(group)
  if (!length(terms)) cli::cli_abort("Select at least one numeric feature column.")
  cols <- names(tidyselect::eval_select(rlang::expr(c(!!!terms)), .data, allow_rename = FALSE))
  tn <- names(tidyselect::eval_select(tq, .data, allow_rename = FALSE))
  gn <- if (rlang::quo_is_null(gq)) character() else names(tidyselect::eval_select(gq, .data, allow_rename = FALSE))
  if (!length(cols) || length(tn) != 1L || (!rlang::quo_is_null(gq) && length(gn) != 1L)) cli::cli_abort("Select feature columns and exactly one time and optional group column.")
  if (tn %in% c(cols, gn) || any(cols %in% gn)) cli::cli_abort("Feature, time, and group columns must be distinct.")
  out_names <- c(paste0("lag", lag, "_", cols), paste0("past_mean", window, "_", cols))
  if (anyDuplicated(out_names) || any(out_names %in% names(.data))) cli::cli_abort("One or more output feature names already exist or are duplicated.")
  if (!is.null(history)) {
    check_data(history)
    required <- c(tn, gn, cols)
    if (!all(required %in% names(history))) cli::cli_abort("{.arg history} is missing required columns: {paste(setdiff(required,names(history)),collapse=', ')}.")
  }
  valid_time <- function(v, name) {
    is_date <- inherits(v, "Date")
    if ((!is_date && !is.numeric(v)) || anyNA(v) || any(!is.finite(as.numeric(v))) || (is_date && any(as.numeric(v) != floor(as.numeric(v))))) cli::cli_abort("{.arg {name}} time must be finite numeric or whole-day Date values without missingness.")
    list(value = as.numeric(v), date = is_date)
  }
  newtime <- valid_time(.data[[tn]], ".data")
  ht <- if (is.null(history)) list(value = numeric(), date = newtime$date) else valid_time(history[[tn]], "history")
  if (newtime$date != ht$date) cli::cli_abort("Time columns in {.arg .data} and {.arg history} must both be numeric or both Date.")
  valid_group <- function(v, name) {
    if (anyNA(v) || !(is.character(v) || is.factor(v) || is.logical(v) || is.numeric(v)) || (is.numeric(v) && any(!is.finite(v)))) cli::cli_abort("{.arg {name}} group must be a complete character, factor, logical or finite numeric column.")
    list(value = as.character(v), kind = if (is.character(v) || is.factor(v)) "text" else if (is.logical(v)) "logical" else "numeric")
  }
  newgroup <- if (!length(gn)) list(value = rep("all", nrow(.data)), kind = "all") else valid_group(.data[[gn]], ".data")
  hg <- if (is.null(history)) list(value = character(), kind = newgroup$kind) else if (!length(gn)) list(value = rep("all", nrow(history)), kind = "all") else valid_group(history[[gn]], "history")
  if (newgroup$kind != hg$kind) cli::cli_abort("Group columns in {.arg .data} and {.arg history} must have compatible types.")
  for (nm in cols) {
    for (d in list(.data, history)) {
      if (!is.null(d)) {
        v <- d[[nm]]
        if (!is.numeric(v) || any(!is.na(v) & !is.finite(v))) cli::cli_abort("Feature column {.field {nm}} must be numeric and contain only finite or missing values.")
      }
    }
  }
  out <- tibble::as_tibble(.data)
  for (nm in out_names) out[[nm]] <- rep(NA_real_, nrow(.data))
  for (g in unique(newgroup$value)) {
    ix <- which(newgroup$value == g)
    ih <- which(hg$value == g)
    tnew <- newtime$value[ix]
    th <- ht$value[ih]
    if (any(diff(tnew) <= 0) || any(diff(th) <= 0)) cli::cli_abort("Times must be strictly increasing within each group in {.arg .data} and {.arg history}.")
    if (length(th) && length(tnew) && utils::tail(th, 1) >= tnew[1]) cli::cli_abort("Every history time must precede all new times in its group.")
    nh <- length(ih)
    pos <- nh + seq_along(ix)
    for (j in seq_along(cols)) {
      name <- cols[j]
      old <- if (is.null(history)) numeric() else as.numeric(history[[name]][ih])
      v <- c(old, as.numeric(.data[[name]][ix]))
      lv <- rep(NA_real_, length(ix))
      ok <- pos > lag
      lv[ok] <- v[pos[ok] - lag]
      rv <- rep(NA_real_, length(ix))
      ok <- pos > window
      if (any(ok)) {
        valid <- !is.na(v)
        cs <- c(0, cumsum(replace(v, !valid, 0)))
        na_count <- c(0, cumsum(!valid))
        if (any(!is.finite(cs))) cli::cli_abort("Cumulative feature values overflowed; rescale {.field {name}}.")
        at <- pos[ok]
        numer <- cs[at] - cs[at - window]
        missing <- na_count[at] - na_count[at - window]
        val <- numer / window
        val[missing > 0] <- NA_real_
        rv[ok] <- val
      }
      out[[paste0("lag", lag, "_", name)]][ix] <- lv
      out[[paste0("past_mean", window, "_", name)]][ix] <- rv
    }
  }
  out
}
