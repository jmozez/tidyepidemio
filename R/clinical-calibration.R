#' Grouped binary risk calibration
#'
#' Divides predictions into equal-width probability bins and compares the mean
#' predicted risk with the observed outcome proportion. All bins are returned;
#' empty bins have zero observations and missing means and limits. Probabilities
#' exactly one enter the final bin. Wilson limits are approximate binomial
#' intervals for the observed proportion within a bin; they do not account for
#' model estimation, dependence, clustered sampling, variation in risks within
#' bins, or the choice of bins. No weights or missing-data handling are included.
#'
#' Assess calibration on data independent of model development, ideally with
#' temporal or external validation. Apparent calibration on training data can be
#' optimistic. Binning can conceal miscalibration and results depend on bin width.
#' @param .data An ungrouped data frame with one row per individual.
#' @param truth Binary 0/1 observed outcome, with 1 denoting the event.
#' @param estimate Predicted event probability, numeric and between zero and one.
#' @param bins Number of equal-width bins, an integer between 1 and 1000.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A tibble with bin boundaries, sample size, predicted and observed
#'   risks and Wilson limits for the observed risk.
#' @examples
#' d <- data.frame(y = c(0, 0, 1, 1), p = c(.1, .3, .7, .9))
#' epi_calibration(d, y, p, bins = 2)
#' @export
epi_calibration <- function(.data, truth, estimate, bins = 10L, conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  check_window(bins, "bins")
  if (bins > 1000) cli::cli_abort("{.arg bins} must not exceed 1000.")
  y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  p <- column(.data, rlang::enquo(estimate), "estimate")
  if (!length(y) || !is.numeric(p) || anyNA(p) || any(!is.finite(p)) || any(p < 0 | p > 1)) cli::cli_abort("Predictions must be finite probabilities in [0,1], with at least one record.")
  bin <- pmin(floor(p * bins) + 1, bins)
  nr <- tabulate(bin, nbins = bins)
  predicted <- observed <- low <- high <- rep(NA_real_, bins)
  z <- stats::qnorm((1 + conf_level) / 2)
  for (i in which(nr > 0)) {
    ix <- bin == i
    predicted[i] <- mean(p[ix])
    observed[i] <- mean(y[ix])
    n <- nr[i]
    den <- 1 + z^2 / n
    center <- (observed[i] + z^2 / (2 * n)) / den
    half <- z * sqrt(observed[i] * (1 - observed[i]) / n + z^2 / (4 * n^2)) / den
    low[i] <- max(0, center - half)
    high[i] <- min(1, center + half)
  }
  tibble::tibble(bin = seq_len(bins), lower = (seq_len(bins) - 1) / bins, upper = seq_len(bins) / bins, n = nr, mean_predicted = predicted, observed_risk = observed, conf_low = low, conf_high = high)
}
