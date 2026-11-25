#' Sliding-window renewal Rt with gamma posterior intervals
#'
#' With fixed lag weights and a gamma(shape, rate) prior, assumes independent
#' local incidence `I[t] ~ Poisson(R * lambda[t])`, with infectiousness
#' `lambda[t] = sum_s w[s] * (local[t-s] + imported[t-s])`. Assumes a constant R
#' within each rolling window. Imported incidence contributes to infectiousness
#' but not the likelihood numerator. Only windows whose entire lag history is
#' observed are estimated. Zero infectiousness with positive local incidence is
#' incompatible and rejected. Overlapping windows are correlated. The model does
#' not account for uncertain generation intervals, reporting delays, incomplete
#' ascertainment, superspreading, or right censoring; intervals are conditional on
#' the supplied counts, imports, weights and prior.
#' @param .data An ungrouped data frame sorted in equally spaced time order.
#' @param cases Local non-negative integer incidence counts.
#' @param weights Non-negative discrete generation interval probabilities for
#'   lags 1 onward, summing to one.
#' @param window Number of likelihood days in each rolling window.
#' @param imported Optional non-negative integer imported count column. Defaults
#'   to zero imports. Imported cases must be classified before analysis.
#' @param prior_shape,prior_rate Positive shape and rate of the gamma prior.
#' @param conf_level Posterior credible level strictly between zero and one.
#' @return Input tibble with `infectiousness`, `rt_mean`, `rt_low`, `rt_high`;
#'   early rows without full history/window are `NA`.
#' @examples
#' d <- data.frame(day = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
#' epi_rt_gamma(d, cases, weights = 1, window = 3)
#' @export
epi_rt_gamma <- function(.data, cases, weights, window = 7L, imported = NULL, prior_shape = 1, prior_rate = 1, conf_level = 0.95) {
  check_data(.data)
  check_window(window, "window")
  check_scalar(prior_shape, "prior_shape")
  check_scalar(prior_rate, "prior_rate")
  check_probability(conf_level, "conf_level")
  local <- column(.data, rlang::enquo(cases), "cases")
  iq <- rlang::enquo(imported)
  imports <- if (rlang::quo_is_null(iq)) rep(0, length(local)) else column(.data, iq, "imported")
  check_nonnegative(local, "cases")
  check_nonnegative(imports, "imported")
  check_nonnegative(weights, "weights")
  if (any(local != floor(local)) || any(imports != floor(imports))) cli::cli_abort("Local and imported counts must be integers.")
  if (!length(weights) || abs(sum(weights) - 1) > 1e-8) cli::cli_abort("{.arg weights} must be a non-empty probability distribution summing to one.")
  cols <- c("infectiousness", "rt_mean", "rt_low", "rt_high")
  if (any(cols %in% names(.data))) cli::cli_abort("Output columns already exist; rename them before analysis.")
  n <- length(local)
  k <- length(weights)
  lambda <- m <- lo <- hi <- rep(NA_real_, n)
  if (n > k) for (i in seq.int(k + 1, n)) lambda[i] <- sum((local + imports)[i - seq_len(k)] * weights)
  if (any(local > 0 & !is.na(lambda) & lambda == 0)) cli::cli_abort("Positive local incidence occurs when infectiousness is zero. Check case classification, history, and generation weights.")
  start <- k + window
  if (n >= start) {
    for (i in seq.int(start, n)) {
      idx <- seq.int(i - window + 1, i)
      shape <- prior_shape + sum(local[idx])
      rate <- prior_rate + sum(lambda[idx])
      m[i] <- shape / rate
      lo[i] <- stats::qgamma((1 - conf_level) / 2, shape = shape, rate = rate)
      hi[i] <- stats::qgamma((1 + conf_level) / 2, shape = shape, rate = rate)
    }
  }
  out <- tibble::as_tibble(.data)
  out$infectiousness <- lambda
  out$rt_mean <- m
  out$rt_low <- lo
  out$rt_high <- hi
  out
}
