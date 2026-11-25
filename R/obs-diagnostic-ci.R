#' Confidence intervals for diagnostic proportions
#'
#' Calculates sensitivity, specificity, positive predictive value and negative
#' predictive value with Wilson or exact Clopper-Pearson binomial intervals.
#' Predictive values depend on sample prevalence and may not generalize to a
#' different setting. Conditional binomial intervals assume independent subjects,
#' accurate reference classification, representative sampling, and fixed
#' denominators; they do not incorporate uncertainty in prevalence adjustment,
#' clustering, verification bias, imperfect reference standards, or sampling
#' design. Likelihood ratios and Youden's index are reported by [epi_diagnostic()]
#' without intervals.
#' @param .data A data frame with one row per subject.
#' @param test Binary index-test result, where 1 is positive.
#' @param truth Binary reference status, where 1 means diseased.
#' @param method `"wilson"` or `"exact"`.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A four-row tibble with metric, numerator, denominator, estimate and
#'   confidence limits. A zero denominator gives missing estimate and limits.
#' @examples
#' d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
#' epi_diagnostic_ci(d, test, truth, method = "exact")
#' @export
epi_diagnostic_ci <- function(.data, test, truth, method = c("wilson", "exact"), conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  method <- match.arg(method)
  t <- check_binary(column(.data, rlang::enquo(test), "test"), "test")
  y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  if (!length(t)) cli::cli_abort("{.arg .data} must contain at least one record.")
  tp <- sum(t == 1 & y == 1)
  tn <- sum(t == 0 & y == 0)
  fp <- sum(t == 1 & y == 0)
  fn <- sum(t == 0 & y == 1)
  num <- c(tp, tn, tp, tn)
  den <- c(tp + fn, tn + fp, tp + fp, tn + fn)
  p <- lo <- hi <- rep(NA_real_, 4)
  z <- stats::qnorm((1 + conf_level) / 2)
  alpha <- 1 - conf_level
  for (i in seq_len(4)) {
    if (den[i] > 0) {
      a <- num[i]
      n <- den[i]
      p[i] <- a / n
      if (method == "exact") {
        lo[i] <- if (a == 0) 0 else stats::qbeta(alpha / 2, a, n - a + 1)
        hi[i] <- if (a == n) 1 else stats::qbeta(1 - alpha / 2, a + 1, n - a)
      } else {
        scale <- 1 + z^2 / n
        center <- (p[i] + z^2 / (2 * n)) / scale
        half <- z * sqrt(p[i] * (1 - p[i]) / n + z^2 / (4 * n^2)) / scale
        lo[i] <- max(0, center - half)
        hi[i] <- min(1, center + half)
      }
    }
  }
  if (any(den == 0)) cli::cli_warn("Some diagnostic denominators are zero; their estimates and intervals are missing.")
  tibble::tibble(metric = c("sensitivity", "specificity", "ppv", "npv"), numerator = num, denominator = den, estimate = p, conf_low = lo, conf_high = hi, conf_level = conf_level, method = method)
}
