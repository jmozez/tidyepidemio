#' Rolling-origin renewal forecast backtesting
#'
#' At each expanding training origin, estimates a constant reproduction number
#' from only the preceding incidence using a gamma-Poisson renewal posterior.
#' It then forecasts `horizon` periods with [epi_renewal_forecast()] and pairs
#' each forecast with the later observed count. In `"posterior"` mode, each
#' trajectory draws a fixed future R from the training posterior; `"fixed"` mode
#' uses the posterior mean. Neither model learns time variation or adjusts for
#' imports, reporting delays, susceptible depletion, data revisions or
#' observation error. Posterior intervals are conditional on the prior, known
#' generation weights, model assumptions and observed history; they are not
#' automatically calibrated.
#'
#' The data must be a single complete series with regular numeric or Date time.
#' The initial period and every assessment horizon are disjoint within an origin;
#' assessment windows from different origins can overlap and are dependent.
#' The backtest assumes historical observations were available without delay at
#' their time of origin. In real surveillance, use vintage data reflecting what
#' was known at each forecast date rather than revised final counts. Set a seed
#' for reproducible Monte Carlo forecasts.
#' @param .data Ungrouped data frame ordered by time with one row per period.
#' @param time Regular, strictly increasing numeric or whole-day Date column.
#' @param cases Non-negative integer incidence counts.
#' @param weights Discrete generation-interval probabilities for lags 1 onward,
#'   summing to one.
#' @param initial Number of observations in the first training window; must
#'   exceed the number of generation lags.
#' @param horizon Number of future periods per assessment window.
#' @param stride Number of rows between successive forecast origins.
#' @param mode Either `"posterior"` for gamma-distributed R or `"fixed"` for
#'   the training posterior mean.
#' @param prior_shape,prior_rate Positive gamma prior shape and rate for R.
#' @param nsim Number of simulation trajectories per origin, at least two.
#' @param conf_level Central prediction interval probability, strictly in (0,1).
#' @return One row per origin and future horizon, with origin/target times,
#'   observed outcome, posterior mean R and forecast mean, median and interval
#'   bounds. Each origin uses only its training observations.
#' @examples
#' d <- data.frame(day = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
#' set.seed(1)
#' backtest <- epi_renewal_backtest(d, day, cases,
#'   weights = 1, initial = 4,
#'   horizon = 2, nsim = 100
#' )
#' wis(backtest, observed, forecast_median, forecast_low, forecast_high, alpha = .05)
#' @export
epi_renewal_backtest <- function(
  .data,
  time,
  cases,
  weights,
  initial,
  horizon = 1L,
  stride = 1L,
  mode = c("posterior", "fixed"),
  prior_shape = 1,
  prior_rate = 1,
  nsim = 1000L,
  conf_level = 0.95
) {
  check_data(.data)
  t <- column(.data, rlang::enquo(time), "time")
  y <- column(.data, rlang::enquo(cases), "cases")
  check_nonnegative(y, "cases")
  check_nonnegative(weights, "weights")
  check_window(initial, "initial")
  check_window(horizon, "horizon")
  check_window(stride, "stride")
  check_window(nsim, "nsim")
  check_scalar(prior_shape, "prior_shape")
  check_scalar(prior_rate, "prior_rate")
  check_probability(conf_level, "conf_level")
  mode <- match.arg(mode)
  is_date <- inherits(t, "Date")
  if ((!is_date && !is.numeric(t)) ||
    anyNA(t) ||
    any(!is.finite(as.numeric(t))) ||
    (is_date && any(as.numeric(t) != floor(as.numeric(t)))) ||
    length(t) < 2) {
    cli::cli_abort("{.arg time} must contain at least two finite numeric or whole-day Date values.")
  }
  dt <- diff(as.numeric(t))
  if (any(dt <= 0) || any(abs(dt - dt[1]) > max(1, abs(dt[1])) * 1e-10)) {
    cli::cli_abort("{.arg time} must be strictly increasing and regularly spaced.")
  }
  if (any(y != floor(y)) ||
    !length(weights) ||
    abs(sum(weights) - 1) > 1e-08 ||
    initial <= length(weights)) {
    cli::cli_abort(
      "Incidence must be integer, weights must sum to one, and initial training must exceed the number of lags."
    )
  }
  if (as.double(initial) + horizon > length(y)) {
    cli::cli_abort("Not enough rows for the initial training window and assessment horizon.")
  }
  if (nsim < 2) cli::cli_abort("At least two simulation trajectories are required.")
  origins <- seq.int(initial, length(y) - horizon, by = stride)
  if (as.double(length(origins)) * nsim * horizon > 1e+07 ||
    as.double(length(origins)) * nsim * length(weights) > 1e+07) {
    cli::cli_abort(
      "The backtest simulation workload is too large; reduce origins, simulations, horizon or lag count."
    )
  }
  k <- length(weights)
  lambda <- numeric(length(y))
  for (i in seq.int(k + 1L, length(y))) lambda[i] <- sum(y[i - seq_len(k)] * weights)
  if (any(y[seq.int(k + 1L, length(y))] > 0 & lambda[seq.int(k + 1L, length(y))] == 0)) {
    cli::cli_abort(
      "Positive incidence follows zero infectiousness; inspect case history and weights."
    )
  }
  events_cum <- cumsum(replace(y, seq_len(k), 0))
  lambda_cum <- cumsum(lambda)
  results <- lapply(origins, function(origin) {
    shape <- prior_shape + events_cum[origin]
    rate <- prior_rate + lambda_cum[origin]
    train <- data.frame(.incidence = y[seq_len(origin)])
    if (mode == "posterior") {
      fc <- epi_renewal_forecast(
        train,
        .data$.incidence,
        weights = weights,
        horizon = horizon,
        rt_shape = shape,
        rt_rate = rate,
        nsim = nsim,
        conf_level = conf_level
      )
    } else {
      fc <- epi_renewal_forecast(
        train,
        .data$.incidence,
        weights = weights,
        horizon = horizon,
        rt = shape / rate,
        nsim = nsim,
        conf_level = conf_level
      )
    }
    target <- origin + seq_len(horizon)
    tibble::tibble(
      origin = origin,
      origin_time = t[rep(origin, horizon)],
      horizon = seq_len(horizon),
      target_time = t[target],
      observed = y[target],
      posterior_mean_rt = shape / rate,
      forecast_mean = fc$mean,
      forecast_median = fc$median,
      forecast_low = fc$lower,
      forecast_high = fc$upper,
      conf_level = conf_level
    )
  })
  dplyr::bind_rows(results)
}
