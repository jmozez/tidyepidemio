#' Estimate exponential growth from incidence
#'
#' Fits a linear regression of log positive counts against numeric time. Zero
#' counts cannot be logged and are rejected. Time units determine the growth
#' rate units. This is not a count likelihood model.
#' @param .data A data frame with one row per observation.
#' @param time Numeric time.
#' @param cases Positive incidence counts.
#' @return A one-row tibble with growth rate and descriptive sample size.
#' @examples
#' d <- data.frame(day = 1:4, cases = exp(0.2 * (1:4)))
#' epi_growth_rate(d, day, cases)
#' epi_doubling_time(d, day, cases)
#' @export
epi_growth_rate <- function(.data, time, cases) {
  check_data(.data)
  t <- column(.data, rlang::enquo(time), "time")
  y <- column(.data, rlang::enquo(cases), "cases")
  if (!is.numeric(t) || anyNA(t) || any(!is.finite(t)) || length(unique(t)) < 2 || length(t) < 2) cli::cli_abort("{.arg time} must contain at least two distinct finite numeric values.")
  check_nonnegative(y, "cases", positive = TRUE)
  tibble::tibble(growth_rate = unname(stats::coef(stats::lm(log(y) ~ t))[2]), n = length(t))
}
#' @rdname epi_growth_rate
#' @return For doubling time, a tibble with growth rate and doubling time. A
#'   non-positive growth rate gives `NA` doubling time.
#' @export
epi_doubling_time <- function(.data, time, cases) {
  out <- epi_growth_rate(.data, {{ time }}, {{ cases }})
  out$doubling_time <- if (out$growth_rate > 0) log(2) / out$growth_rate else NA_real_
  out
}
#' Renewal-equation effective reproduction number
#'
#' Computes `I[t] / sum(I[t-s] * w[s])` for prior observed incidence. The
#' generation-interval weights start at lag 1, must sum to one, and are not
#' renormalized at the beginning of the series. Early estimates are `NA` until
#' all lags are observed; zero infectiousness also gives `NA`. Imported cases,
#' uncertainty, reporting delays, and right censoring are not modeled.
#' @param .data A data frame in chronological order with equally spaced rows.
#' @param cases Non-negative incidence counts.
#' @param weights Non-negative generation-interval probability mass by lag.
#' @return The input tibble with an `rt` column.
#' @examples
#' epi_rt(data.frame(cases = c(1, 2, 4, 8)), cases, weights = 1)
#' @export
epi_rt <- function(.data, cases, weights) {
  check_data(.data)
  y <- column(.data, rlang::enquo(cases), "cases")
  check_nonnegative(y, "cases")
  check_nonnegative(weights, "weights")
  if (!length(weights) || abs(sum(weights) - 1) > 1e-8) cli::cli_abort("{.arg weights} must be a non-empty probability distribution summing to one.")
  if ("rt" %in% names(.data)) cli::cli_abort("{.arg .data} already has an {.field rt} column.")
  n <- length(y)
  k <- length(weights)
  out <- rep(NA_real_, n)
  if (n > k) {
    for (i in seq.int(k + 1L, n)) {
      den <- sum(y[i - seq_len(k)] * weights)
      if (den > 0) out[i] <- y[i] / den
    }
  }
  dplyr::mutate(tibble::as_tibble(.data), rt = out)
}
#' Summarize observed serial intervals
#'
#' Calculates the difference in days between infectee and infector onset dates.
#' Negative intervals are allowed and should be assessed for data quality.
#' @param .data A data frame with paired onset dates.
#' @param infector Onset date for the infector, as a Date.
#' @param infectee Onset date for the infectee, as a Date.
#' @return A tibble with count, mean and sample standard deviation in days.
#' @examples
#' d <- data.frame(a = as.Date("2020-01-01") + 0:2, b = as.Date("2020-01-01") + 2:4)
#' epi_serial_interval(d, a, b)
#' @export
epi_serial_interval <- function(.data, infector, infectee) {
  check_data(.data)
  a <- column(.data, rlang::enquo(infector), "infector")
  b <- column(.data, rlang::enquo(infectee), "infectee")
  if (!inherits(a, "Date") || !inherits(b, "Date") || anyNA(a) || anyNA(b) || !length(a)) cli::cli_abort("Onset columns must be non-missing Date vectors with at least one pair.")
  x <- as.numeric(b - a)
  tibble::tibble(n = length(x), mean_days = mean(x), sd_days = stats::sd(x))
}
