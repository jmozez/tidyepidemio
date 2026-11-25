#' Monte Carlo calibration of a finite-horizon Poisson CUSUM
#'
#' Simulates independent Poisson counts under externally supplied baseline means
#' and calculates the maximum one-sided CUSUM over the entire monitoring horizon
#' using the same recursion as [epi_cusum()]. The threshold is slightly greater
#' than the `k`th ordered simulated maximum, where
#' `k = ceiling((nsim + 1) * (1 - alpha))`. Under exchangeability of the null
#' simulations and a future null sequence, this strict rank construction controls
#' the marginal probability that its maximum crosses the threshold at at most
#' `(nsim + 1 - k) / (nsim + 1)`, including simulation randomness; ties only make
#' it more conservative. This is not a confidence guarantee conditional on the
#' particular simulated calibration set and is not average run length control.
#'
#' Calibration is valid only if the assumed independent count baseline is a
#' suitable null for the entire horizon. Set `size` to simulate negative binomial
#' null counts for overdispersed series. With `n_series > 1`, each series is
#' calibrated at the Sidak level `1 - (1 - alpha)^(1 / n_series)`, which bounds
#' the probability of any false alarm across that many independent series.
#' Estimated baselines, serial dependence and reporting changes can still
#' invalidate it.
#' It does not account for later restarting, changing horizon, or retuning the
#' threshold. Set a seed to reproduce the Monte Carlo result.
#' @param .data A non-empty data frame containing the baseline sequence, one row
#'   per monitoring time step.
#' @param baseline Positive expected count at each monitoring step.
#' @param relative_risk Alternative-to-baseline rate ratio, strictly above one.
#' @param alpha Desired maximum false-alarm probability, strictly in (0,1).
#' @param nsim Number of null trajectories; must be large enough for the rank.
#' @param initial Non-negative CUSUM statistic at the start of each trajectory.
#' @param size Negative binomial size (dispersion) for null counts; `Inf`
#'   (default) gives Poisson counts. Smaller values mean more overdispersion.
#' @param n_series Number of independent series monitored together.
#' @return One-row tibble with `threshold`, `alpha`, `series_alpha`, `marginal_bound`,
#'   `simulations`, and the number of monitoring `steps`.
#' @examples
#' d <- data.frame(base = rep(2, 10))
#' set.seed(1)
#' epi_cusum_calibrate(d, base, relative_risk = 2, alpha = .1, nsim = 99)
#' @export
epi_cusum_calibrate <- function(
  .data,
  baseline,
  relative_risk = 2,
  alpha = 0.05,
  nsim = 999L,
  initial = 0,
  size = Inf,
  n_series = 1L
) {
  check_data(.data)
  mu <- column(.data, rlang::enquo(baseline), "baseline")
  check_nonnegative(mu, "baseline", positive = TRUE)
  check_scalar(relative_risk, "relative_risk", min = 1)
  check_probability(alpha, "alpha")
  check_window(nsim, "nsim")
  check_scalar(initial, "initial", inclusive = TRUE)
  if (!is.numeric(size) || length(size) != 1 || is.na(size) || size <= 0) {
    cli::cli_abort("{.arg size} must be a positive number or Inf.")
  }
  check_window(n_series, "n_series")
  family_alpha <- alpha
  series_alpha <- 1 - (1 - alpha)^(1 / n_series)
  alpha <- series_alpha
  if (!length(mu)) cli::cli_abort("At least one baseline period is required.")
  if (as.double(nsim) * length(mu) > 1e+07) {
    cli::cli_abort("At most 10 million simulation steps are supported.")
  }
  k <- ceiling((as.double(nsim) + 1) * (1 - alpha))
  if (k > nsim) cli::cli_abort("Increase {.arg nsim} so that it is at least 1 / alpha - 1.")
  current <- rep(initial, nsim)
  maximum <- rep(0, nsim)
  for (m in mu) {
    draws <- if (is.finite(size)) stats::rnbinom(nsim, size = size, mu = m) else stats::rpois(nsim, m)
    current <- pmax(0, current + draws * log(relative_risk) - (relative_risk - 1) * m)
    maximum <- pmax(maximum, current)
  }
  q <- sort(maximum, partial = k)[k]
  threshold <- q + 1e-12 * max(1, abs(q))
  if (!is.finite(threshold)) cli::cli_abort("Calibration produced a non-finite threshold.")
  tibble::tibble(
    threshold = threshold,
    alpha = family_alpha,
    series_alpha = series_alpha,
    marginal_bound = (nsim + 1 - k) / (nsim + 1),
    simulations = as.integer(nsim),
    steps = length(mu)
  )
}
# Upper-tail p-values P(Y >= y) for Poisson (size = Inf) or negative binomial
# counts, with an optional multiple-testing adjustment over non-missing values.
surveillance_tail <- function(y, mean, size, adjust) {
  p <- rep(NA_real_, length(y))
  ok <- !is.na(mean)
  p[ok] <- ifelse(is.finite(size[ok]), stats::pnbinom(y[ok] - 1, size = size[ok], mu = mean[ok], lower.tail = FALSE),
    stats::ppois(y[ok] - 1, mean[ok], lower.tail = FALSE)
  )
  adj <- p
  adj[ok] <- stats::p.adjust(p[ok], method = adjust)
  list(p = p, adjusted = adj)
}
surveillance_quantile <- function(alpha, mean, size) {
  ifelse(
    is.finite(size),
    stats::qnbinom(alpha, size = size, mu = mean, lower.tail = FALSE),
    stats::qpois(alpha, mean, lower.tail = FALSE)
  )
}
