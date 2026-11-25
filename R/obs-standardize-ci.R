#' Confidence intervals for standardized rates and ratios
#'
#' For direct standardization, uses the Fay-Feuer gamma interval for a weighted
#' sum of independent Poisson counts. For indirect standardization, calculates
#' an exact Poisson interval for the standardized mortality/incidence ratio
#' (SMR/SIR), conditional on the expected count. Standard rates must be supplied
#' per one, not per multiplier. The indirect ratio is dimensionless and is not
#' multiplied. Assumes independent Poisson counts, fixed population/exposure and
#' fixed standard rates; overdispersion or uncertain standard rates invalidate
#' these simple intervals.
#' @param .data Data frame with one row per stratum.
#' @param events Non-negative integer event counts.
#' @param population Positive population or person-time.
#' @param standard Standard population for direct, or rate per one for indirect.
#' @param method Either `"direct"` or `"indirect"`.
#' @param multiplier Positive scale factor for a directly standardized rate.
#' @param conf_level Confidence level strictly between zero and one.
#' @return One-row tibble with method, estimate and confidence limits.
#' @references Fay MP and Feuer EJ (1997). Confidence intervals for directly
#'   standardized rates: a method based on the gamma distribution. Statistics in
#'   Medicine 16:791-801. doi:10.1002/(SICI)1097-0258(19970415)16:7<791::AID-SIM500>3.0.CO;2-#
#' @examples
#' d <- data.frame(events = c(10, 20), pop = c(100, 100), standard = c(150, 50))
#' epi_standardize_ci(d, events, pop, standard)
#' @export
epi_standardize_ci <- function(
  .data,
  events,
  population,
  standard,
  method = c("direct", "indirect"),
  multiplier = 1,
  conf_level = 0.95
) {
  check_data(.data)
  method <- match.arg(method)
  check_scalar(multiplier, "multiplier")
  check_probability(conf_level, "conf_level")
  a <- column(.data, rlang::enquo(events), "events")
  n <- column(.data, rlang::enquo(population), "population")
  s <- column(.data, rlang::enquo(standard), "standard")
  check_nonnegative(a, "events")
  check_nonnegative(n, "population", positive = TRUE)
  check_nonnegative(s, "standard")
  if (!length(a) || any(a != floor(a))) {
    cli::cli_abort("At least one stratum and integer event counts are required.")
  }
  alpha <- 1 - conf_level
  if (method == "direct") {
    if (sum(s) <= 0) cli::cli_abort("Total standard population must be positive.")
    w <- s / sum(s) / n
    estimate <- sum(w * a)
    variance <- sum(w^2 * a)
    maxw <- max(w)
    lo <- if (estimate == 0) {
      0
    } else {
      stats::qgamma(alpha / 2, shape = estimate^2 / variance, scale = variance / estimate)
    }
    up_mean <- estimate + maxw
    up_var <- variance + maxw^2
    hi <- stats::qgamma(1 - alpha / 2, shape = up_mean^2 / up_var, scale = up_var / up_mean)
    tibble::tibble(
      method = method,
      estimate = estimate * multiplier,
      conf_low = lo * multiplier,
      conf_high = hi * multiplier,
      conf_level = conf_level
    )
  } else {
    expected <- sum(n * s)
    if (expected <= 0) cli::cli_abort("Expected events must be positive.")
    obs <- sum(a)
    lo <- if (obs == 0) 0 else stats::qchisq(alpha / 2, 2 * obs) / 2
    hi <- stats::qchisq(1 - alpha / 2, 2 * (obs + 1)) / 2
    tibble::tibble(
      method = method,
      observed = obs,
      expected = expected,
      estimate = obs / expected,
      conf_low = lo / expected,
      conf_high = hi / expected,
      conf_level = conf_level
    )
  }
}
