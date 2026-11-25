#' Derive cohort follow-up and administrative censoring
#'
#' Computes observed follow-up from entry and exit dates, with an optional
#' administrative censoring date. If the original exit is after `censor_at`,
#' follow-up ends at the censoring date and the event indicator becomes zero.
#' An event on the censoring date is retained. A subject entering after the
#' censoring date is rejected rather than silently discarded; zero-day follow-up
#' is allowed. Each row is assumed to represent one distinct subject.
#'
#' This helper does not infer event dates from the record or handle recurrent
#' events, competing risks, delayed reporting, loss-to-follow-up mechanisms,
#' time-varying covariates or causal assumptions. A year is a fixed `365.25`
#' days, not a calendar-year calculation. Censoring must be appropriately handled
#' in the downstream analysis.
#' @param .data An ungrouped data frame, one row per subject.
#' @param entry,exit Complete whole-day Date columns of entry and observed exit.
#' @param event Binary event indicator, 1 if the event occurred at the exit date
#'   and 0 if exit was already censoring.
#' @param censor_at Optional single whole-day Date for administrative censoring.
#' @param unit Either `"days"` or `"years"`; years are calculated using 365.25 days.
#' @return Input tibble with `followup_end` (Date), `follow_up` (numeric time in
#'   selected units), and binary `event_observed` columns.
#' @examples
#' d <- data.frame(
#'   start = as.Date("2024-01-01") + c(0, 1),
#'   end = as.Date("2024-01-01") + c(5, 10), event = c(1, 1)
#' )
#' epi_follow_up(d, start, end, event, censor_at = as.Date("2024-01-08"))
#' @export
epi_follow_up <- function(.data, entry, exit, event, censor_at = NULL, unit = c("days", "years")) {
  check_data(.data)
  unit <- match.arg(unit)
  a <- column(.data, rlang::enquo(entry), "entry")
  b <- column(.data, rlang::enquo(exit), "exit")
  e <- check_binary(column(.data, rlang::enquo(event), "event"), "event")
  check_dates <- function(x, name) {
    if (!inherits(x, "Date") ||
      anyNA(x) ||
      any(!is.finite(as.numeric(x))) ||
      any(as.numeric(x) != floor(as.numeric(x)))) {
      cli::cli_abort("{.arg {name}} must contain complete finite whole-day Date values.")
    }
  }
  check_dates(a, "entry")
  check_dates(b, "exit")
  if (any(b < a)) cli::cli_abort("Exit dates must not precede entry dates.")
  if (!is.null(censor_at)) {
    if (length(censor_at) != 1L) cli::cli_abort("{.arg censor_at} must be a single Date.")
    check_dates(censor_at, "censor_at")
    if (any(a > censor_at)) {
      cli::cli_abort(
        "Entry dates must not be after {.arg censor_at}; explicitly exclude ineligible records first."
      )
    }
  }
  out_cols <- c("followup_end", "follow_up", "event_observed")
  if (any(out_cols %in% names(.data))) {
    cli::cli_abort("Output follow-up columns already exist; rename them first.")
  }
  end <- if (is.null(censor_at)) {
    b
  } else {
    as.Date(pmin(as.numeric(b), as.numeric(censor_at)), origin = "1970-01-01")
  }
  observed <- if (is.null(censor_at)) e else e * as.numeric(b <= censor_at)
  elapsed <- as.numeric(end - a)
  if (unit == "years") elapsed <- elapsed / 365.25
  out <- tibble::as_tibble(.data)
  out$followup_end <- end
  out$follow_up <- elapsed
  out$event_observed <- observed
  out
}
