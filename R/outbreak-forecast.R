#' Probabilistic renewal forecasts
#'
#' Simulates a renewal process forward from observed recent incidence.
#' For each trajectory, future counts are independent Poisson draws conditional
#' on the previous observed/simulated history: `I[t] ~ Poisson(R * sum(w[s] *
#' I[t-s]))`. Use a fixed `rt`, or supply `rt_shape` and `rt_rate` to draw a
#' single Gamma(shape, rate) reproduction number per trajectory. The latter can
#' propagate a compatible gamma posterior, but does not model time variation in R.
#' The initial history is treated as exact and remains observed; future counts
#' recursively use simulated counts. The forecast has no future imports, reporting
#' process, uncertain weights, depletion of susceptibles, or interventions. An
#' all-zero history is absorbing. Prediction intervals are empirical Monte Carlo
#' quantiles, not guaranteed-calibrated intervals. Set a seed for reproducibility.
#' @param .data An ungrouped data frame of incidence in chronological order at
#'   equally spaced time intervals, with at least one row per generation lag.
#' @param cases Non-negative integer incidence counts.
#' @param weights Non-negative generation-interval probabilities for lags 1
#'   onward, summing to one.
#' @param horizon Positive integer number of future steps.
#' @param rt A fixed non-negative reproduction number; mutually exclusive with
#'   `rt_shape` and `rt_rate`.
#' @param rt_shape,rt_rate Positive shape and rate for an optional gamma
#'   distribution of R, both required if `rt` is not provided.
#' @param nsim Number of independent Monte Carlo trajectories, at least two.
#' @param conf_level Central prediction interval probability, strictly between
#'   zero and one.
#' @return A tibble with future step, Monte Carlo mean, median, interval bounds,
#'   and number of simulations. Time zero is the last observation; actual dates
#'   must be assigned by the caller. Values are counts, not rates.
#' @examples
#' d <- data.frame(cases = c(1, 2, 4, 8))
#' set.seed(1)
#' epi_renewal_forecast(d, cases, weights = 1, horizon = 3, rt = 1.2, nsim = 100)
#' @export
epi_renewal_forecast <- function(
  .data,
  cases,
  weights,
  horizon = 7L,
  rt = NULL,
  rt_shape = NULL,
  rt_rate = NULL,
  nsim = 1000L,
  conf_level = 0.95
) {
  check_data(.data)
  y <- column(.data, rlang::enquo(cases), "cases")
  check_nonnegative(y, "cases")
  check_nonnegative(weights, "weights")
  check_window(horizon, "horizon")
  check_window(nsim, "nsim")
  check_probability(conf_level, "conf_level")
  if (any(y != floor(y)) ||
    !length(weights) ||
    abs(sum(weights) - 1) > 1e-08 ||
    length(y) < length(weights)) {
    cli::cli_abort(
      "Use integer incidence, at least one observation per lag and generation weights summing to one."
    )
  }
  if (nsim < 2 || as.double(nsim) * horizon > 1e+07 || as.double(nsim) * length(weights) > 1e+07) {
    cli::cli_abort(
      "Use at least 2 simulations and at most 10 million simulated horizon or history cells."
    )
  }
  if (!is.null(rt)) {
    if (!is.null(rt_shape) || !is.null(rt_rate)) {
      cli::cli_abort("Specify either {.arg rt} or both gamma parameters, not both.")
    }
    check_scalar(rt, "rt", inclusive = TRUE)
    rr <- rep(rt, nsim)
  } else {
    if (is.null(rt_shape) || is.null(rt_rate)) {
      cli::cli_abort("Provide {.arg rt} or both {.arg rt_shape} and {.arg rt_rate}.")
    }
    check_scalar(rt_shape, "rt_shape")
    check_scalar(rt_rate, "rt_rate")
    rr <- stats::rgamma(nsim, shape = rt_shape, rate = rt_rate)
  }
  k <- length(weights)
  history <- matrix(rep(utils::tail(y, k), each = nsim), nrow = nsim)
  sims <- matrix(0, nrow = nsim, ncol = horizon)
  for (i in seq_len(horizon)) {
    lam <- as.vector(history[, k:1L, drop = FALSE] %*% weights) * rr
    if (any(!is.finite(lam)) || any(lam < 0)) {
      cli::cli_abort(
        "The simulation produced non-finite expected incidence; check the model inputs and horizon."
      )
    }
    draw <- stats::rpois(nsim, lam)
    if (any(!is.finite(draw))) {
      cli::cli_abort(
        "The simulation produced non-finite incidence; check the model inputs and horizon."
      )
    }
    sims[, i] <- draw
    if (k == 1L) history[, 1L] <- draw else history <- cbind(history[, 2:k, drop = FALSE], draw)
  }
  alpha <- 1 - conf_level
  tibble::tibble(
    step = seq_len(horizon),
    mean = colMeans(sims),
    median = apply(sims, 2, stats::quantile, probs = 0.5, type = 1, names = FALSE),
    lower = apply(sims, 2, stats::quantile, probs = alpha / 2, type = 1, names = FALSE),
    upper = apply(sims, 2, stats::quantile, probs = 1 - alpha / 2, type = 1, names = FALSE),
    simulations = as.integer(nsim)
  )
}
