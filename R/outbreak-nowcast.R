#' Nowcast final reported incidence from reporting delays
#'
#' Models observed reports for each onset date as a Poisson-thinned count with
#' known reporting fraction `F(age)`, where `age` is days from onset to the
#' analysis date. Independent gamma(shape, rate) priors are assigned to each
#' date's ultimate expected reported count. Conditional on the observed count,
#' the number of future reports has a negative-binomial posterior predictive
#' distribution with size `prior_shape + observed` and success probability
#' `(prior_rate + F) / (prior_rate + 1)`. The nowcast is the already observed
#' count plus this future-report count. The bounds are posterior predictive
#' intervals for the **final reported count**, not intervals for the latent mean
#' or the total number of infections.
#'
#' Assumes the provided delay distribution is known, constant across dates and
#' representative of eventual reports. It does not correct for permanently
#' unreported infections, changing delay distributions, reporting day effects,
#' revisions, duplicated reports, unknown onset dates, or temporal dependence.
#' The gamma prior is independent across dates and can dominate dates with low
#' reporting completeness. Missing dates are not inserted. Delay probabilities
#' are discrete for delays 0, 1, ..., with total one. All input observations
#' must represent reports actually available as of `as_of`.
#' @param .data An ungrouped data frame with one row per unique onset date.
#' @param onset Non-missing `Date` column containing onset dates.
#' @param reported Non-negative integer number of reports received by `as_of`.
#' @param as_of A single `Date` representing the data extraction date.
#' @param delay_prob Non-negative delay probabilities indexed from delay zero,
#'   summing to one. Include the entire assumed eventual reporting distribution.
#' @param prior_shape,prior_rate Positive shape and rate of the gamma prior for
#'   each onset date's eventual mean reported count.
#' @param conf_level Central posterior predictive interval probability in (0,1).
#' @return Input tibble with `reporting_fraction`, `nowcast_mean`, `nowcast_low`,
#'   and `nowcast_high`. Rows with full reporting fraction have a degenerate
#'   prediction equal to the observed count.
#' @examples
#' d <- data.frame(onset = as.Date("2024-01-01") + 0:2, reported = c(10, 8, 3))
#' epi_nowcast(d, onset, reported,
#'   as_of = as.Date("2024-01-03"),
#'   delay_prob = c(.5, .3, .2), prior_shape = 2, prior_rate = 1
#' )
#' @export
epi_nowcast <- function(.data, onset, reported, as_of, delay_prob, prior_shape = 1, prior_rate = 1, conf_level = 0.95) {
  check_data(.data)
  date <- column(.data, rlang::enquo(onset), "onset")
  y <- column(.data, rlang::enquo(reported), "reported")
  if (!inherits(date, "Date") || anyNA(date) || anyDuplicated(date)) {
    cli::cli_abort("{.arg onset} must contain unique, non-missing Date values.")
  }
  if (!inherits(as_of, "Date") ||
    length(as_of) != 1L ||
    is.na(as_of) ||
    !is.finite(as.numeric(as_of))) {
    cli::cli_abort("{.arg as_of} must be a single finite Date.")
  }
  if (any(!is.finite(as.numeric(date))) ||
    any(date > as_of) ||
    any(as.numeric(date) != floor(as.numeric(date))) ||
    as.numeric(as_of) != floor(as.numeric(as_of))) {
    cli::cli_abort(
      "Onset and analysis dates must be finite whole days, with onset not later than {.arg as_of}."
    )
  }
  check_nonnegative(y, "reported")
  if (any(y != floor(y))) cli::cli_abort("{.arg reported} must contain integer counts.")
  check_nonnegative(delay_prob, "delay_prob")
  if (!length(delay_prob) || abs(sum(delay_prob) - 1) > 1e-08) {
    cli::cli_abort("{.arg delay_prob} must be a non-empty probability distribution summing to one.")
  }
  check_scalar(prior_shape, "prior_shape")
  check_scalar(prior_rate, "prior_rate")
  check_probability(conf_level, "conf_level")
  output_names <- c("reporting_fraction", "nowcast_mean", "nowcast_low", "nowcast_high")
  if (any(output_names %in% names(.data))) {
    cli::cli_abort("Output columns already exist; rename them before nowcasting.")
  }
  age <- as.numeric(as_of - date)
  cdf <- cumsum(delay_prob / sum(delay_prob))
  cdf[length(cdf)] <- 1
  f <- cdf[pmin(age + 1, length(cdf))]
  if (any(f == 0 & y > 0)) {
    cli::cli_abort(
      "Positive reports are incompatible with zero reporting probability at their onset age."
    )
  }
  shape <- prior_shape + y
  rate <- prior_rate + f
  prob <- rate / (prior_rate + 1)
  alpha <- 1 - conf_level
  if (any(!is.finite(shape)) || any(!is.finite(rate)) || any(!is.finite(prob)) || any(prob <= 0)) {
    cli::cli_abort("The posterior parameters are not finite; check count and prior magnitudes.")
  }
  mean <- y + (1 - f) * shape / rate
  lo <- y + stats::qnbinom(alpha / 2, size = shape, prob = prob)
  hi <- y + stats::qnbinom(1 - alpha / 2, size = shape, prob = prob)
  out <- tibble::as_tibble(.data)
  out$reporting_fraction <- f
  out$nowcast_mean <- mean
  out$nowcast_low <- lo
  out$nowcast_high <- hi
  out
}
