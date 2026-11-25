#' Aggregate an epidemic curve
#'
#' Counts one case per input row by onset date, optionally stratified by a
#' grouping column, and fills absent bins with zero. Weekly bins start on Monday;
#' daily bins start on the onset date. When `start` and `end` are supplied they
#' must enclose every observed onset date, preventing silent case loss. Bounds
#' are inclusive and weekly bounds are rounded down to their bin's Monday.
#' The function does not distinguish dates of onset from specimen or report
#' dates, correct incomplete ascertainment, or insert unknown-onset cases.
#' @param .data An ungrouped data frame with one row per case.
#' @param onset Non-missing Date column of case onset dates.
#' @param group Optional complete character, factor, logical or numeric group
#'   column. Defaults to a single group named `"All"`.
#' @param interval Either `"day"` or `"week"`.
#' @param start,end Optional single Date bounds, defaulting to the earliest and
#'   latest observed onset date.
#' @return A tibble with `group`, bin-start `date`, and integer `cases`, ordered
#'   by first appearance of group and ascending date. Empty bins are zero.
#' @examples
#' d <- data.frame(onset = as.Date("2024-01-01") + c(0, 0, 2), region = c("a", "b", "a"))
#' epi_epicurve(d, onset, group = region)
#' @export
epi_epicurve <- function(.data, onset, group = NULL, interval = c("day", "week"), start = NULL, end = NULL) {
  check_data(.data)
  interval <- match.arg(interval)
  date <- column(.data, rlang::enquo(onset), "onset")
  if (!inherits(date, "Date") ||
    !length(date) ||
    anyNA(date) ||
    any(!is.finite(as.numeric(date))) ||
    any(as.numeric(date) != floor(as.numeric(date)))) {
    cli::cli_abort("{.arg onset} must contain at least one non-missing, finite whole-day Date.")
  }
  gq <- rlang::enquo(group)
  g <- if (rlang::quo_is_null(gq)) rep("All", length(date)) else column(.data, gq, "group")
  if (anyNA(g) ||
    !(is.character(g) || is.factor(g) || is.numeric(g) || is.logical(g)) ||
    (is.numeric(g) && any(!is.finite(g)))) {
    cli::cli_abort(
      "{.arg group} must be a complete character, factor, logical or finite numeric column."
    )
  }
  date_bound <- function(x, name, default) {
    if (is.null(x)) {
      return(default)
    }
    if (!inherits(x, "Date") ||
      length(x) != 1L ||
      is.na(x) ||
      !is.finite(as.numeric(x)) ||
      as.numeric(x) != floor(as.numeric(x))) {
      cli::cli_abort("{.arg {name}} must be a single finite whole-day Date.")
    }
    x
  }
  start <- date_bound(start, "start", min(date))
  end <- date_bound(end, "end", max(date))
  if (start > min(date) || end < max(date) || start > end) {
    cli::cli_abort("Date bounds must enclose every observed onset date.")
  }
  bin_date <- function(
    x
  ) {
    if (interval == "day") {
      x
    } else {
      as.Date(floor((as.numeric(x) - 4) / 7) * 7 + 4, origin = "1970-01-01")
    }
  }
  date <- bin_date(date)
  start <- bin_date(start)
  end <- bin_date(end)
  by <- if (interval == "day") 1 else 7
  bins_n <- as.numeric(end - start) / by + 1
  groups <- unique(as.character(g))
  if (!is.finite(bins_n) || bins_n * length(groups) > 1e+06) {
    cli::cli_abort("At most one million group-date bins are supported.")
  }
  dates <- seq(start, end, by = paste(by, "days"))
  g <- as.character(g)
  pieces <- lapply(groups, function(id) {
    index <- match(date[g == id], dates)
    counts <- tabulate(index, nbins = length(dates))
    tibble::tibble(group = id, date = dates, cases = as.integer(counts))
  })
  dplyr::bind_rows(pieces)
}
