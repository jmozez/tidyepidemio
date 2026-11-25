#' Standardize rates across strata
#'
#' Direct standardization weights stratum-specific observed rates by the
#' standard populations. Indirect standardization returns an observed-to-expected
#' ratio using standard rates. Strata must be mutually exclusive and exhaustive;
#' no uncertainty intervals are calculated.
#' @param .data A data frame with one row per stratum.
#' @param events Observed event counts.
#' @param population Observed population or person-time.
#' @param standard Standard population for direct, or standard rate for indirect.
#' @param method Either `"direct"` or `"indirect"`.
#' @param multiplier Positive rate scale used for the output. For indirect
#'   standardization, standard rates must be supplied per one, not per multiplier.
#' @return A one-row tibble with the standardized estimate; for indirect
#'   standardization it also includes observed and expected events.
#' @examples
#' d <- data.frame(events = c(10, 20), pop = c(100, 100), standard = c(150, 50))
#' epi_standardize(d, events, pop, standard)
#' @export
epi_standardize <- function(.data, events, population, standard, method = c("direct", "indirect"), multiplier = 1) {
  check_data(.data)
  method <- match.arg(method)
  check_scalar(multiplier, "multiplier")
  a <- column(.data, rlang::enquo(events), "events")
  n <- column(.data, rlang::enquo(population), "population")
  s <- column(.data, rlang::enquo(standard), "standard")
  if (!length(a)) cli::cli_abort("At least one stratum is required.")
  check_nonnegative(a, "events")
  check_nonnegative(n, "population", positive = TRUE)
  check_nonnegative(s, "standard")
  if (method == "direct") {
    if (sum(s) == 0) cli::cli_abort("The total standard population must be positive.")
    tibble::tibble(method = method, estimate = sum(a / n * s) / sum(s) * multiplier)
  } else {
    expected <- sum(n * s)
    if (expected == 0) cli::cli_abort("Expected events must be positive.")
    tibble::tibble(
      method = method,
      observed = sum(a),
      expected = expected,
      estimate = sum(a) / expected
    )
  }
}
#' Mantel-Haenszel pooled odds ratio
#'
#' Computes the Mantel-Haenszel common odds ratio from individual records, with
#' a Robins-Breslow-Greenland confidence interval and a Breslow-Day test of
#' homogeneity of the stratum odds ratios (with Tarone's correction).
#'
#' The heterogeneity test compares each stratum's exposed-case count with its
#' expectation under the pooled odds ratio. Strata with a zero margin carry no
#' information and are excluded from the test; its degrees of freedom are the
#' number of informative strata minus one. The test has low power with few or
#' sparse strata, and a non-significant result does not prove homogeneity.
#' @param .data A data frame of individual records.
#' @param exposure Binary exposure indicator.
#' @param outcome Binary outcome indicator.
#' @param strata A non-missing stratum variable.
#' @param conf_level Confidence level between zero and one.
#' @return A one-row tibble with the pooled estimate, confidence limits, number
#'   of strata, and the Breslow-Day statistic (`heterogeneity_statistic`),
#'   degrees of freedom (`heterogeneity_df`) and p-value (`heterogeneity_p_value`).
#' @examples
#' d <- data.frame(e = rep(c(0, 0, 1, 1), 2), y = rep(c(0, 1, 0, 1), 2), s = rep(1:2, each = 4))
#' epi_mantel_haenszel(d, e, y, s)
#' @export
epi_mantel_haenszel <- function(.data, exposure, outcome, strata, conf_level = 0.95) {
  check_data(.data)
  check_scalar(conf_level, "conf_level")
  if (conf_level >= 1) cli::cli_abort("{.arg conf_level} must be less than 1.")
  e <- check_binary(column(.data, rlang::enquo(exposure), "exposure"), "exposure")
  y <- check_binary(column(.data, rlang::enquo(outcome), "outcome"), "outcome")
  s <- column(.data, rlang::enquo(strata), "strata")
  if (!length(s) || anyNA(s)) {
    cli::cli_abort(
      "{.arg strata} must contain at least one non-missing value and no missing values."
    )
  }
  tab <- do.call(rbind, lapply(split(seq_along(s), s, drop = TRUE), function(i) {
    c(
      a = sum(e[i] == 1 & y[i] == 1),
      b = sum(e[i] == 1 & y[i] == 0),
      c = sum(e[i] == 0 & y[i] == 1),
      d = sum(e[i] == 0 & y[i] == 0)
    )
  }))
  tab <- matrix(as.double(tab), ncol = 4, dimnames = list(NULL, c("a", "b", "c", "d")))
  a <- tab[, "a"]
  b <- tab[, "b"]
  c <- tab[, "c"]
  d <- tab[, "d"]
  n <- a + b + c + d
  R <- a * d / n
  S <- b * c / n
  estimate <- ratio_safe(sum(R), sum(S))
  if (is.na(estimate)) {
    cli::cli_warn("The Mantel-Haenszel odds ratio is undefined; returning {.val NA}.")
  }
  lo <- hi <- NA_real_
  if (!is.na(estimate) && estimate > 0) {
    P <- (a + d) / n
    Q <- (b + c) / n
    v <- sum(P * R) / (2 * sum(R)^2) + sum(P * S + Q * R) / (2 * sum(R) * sum(S)) + sum(Q * S) / (2 * sum(S)^2)
    z <- stats::qnorm((1 + conf_level) / 2)
    lo <- exp(log(estimate) - z * sqrt(v))
    hi <- exp(log(estimate) + z * sqrt(v))
  }
  het <- breslow_day(tab, estimate)
  tibble::tibble(
    estimate = estimate, conf_low = lo, conf_high = hi, strata = nrow(tab),
    heterogeneity_statistic = het$statistic, heterogeneity_df = het$df, heterogeneity_p_value = het$p_value
  )
}
breslow_day <- function(tab, psi) {
  none <- list(statistic = NA_real_, df = NA_integer_, p_value = NA_real_)
  if (is.na(psi) || psi <= 0 || !is.finite(psi)) {
    return(none)
  }
  n1 <- tab[, "a"] + tab[, "b"]
  n0 <- tab[, "c"] + tab[, "d"]
  m1 <- tab[, "a"] + tab[, "c"]
  lower <- pmax(0, m1 - n0)
  upper <- pmin(n1, m1)
  keep <- upper > lower
  if (sum(keep) < 2) {
    return(none)
  }
  diffs <- vars <- numeric(0)
  for (k in which(keep)) {
    f <- function(x) x * (n0[k] - m1[k] + x) - psi * (n1[k] - x) * (m1[k] - x)
    ex <- stats::uniroot(f, c(lower[k], upper[k]), tol = 1e-10)$root
    vars <- c(vars, 1 / (1 / ex + 1 / (n1[k] - ex) + 1 / (m1[k] - ex) + 1 / (n0[k] - m1[k] + ex)))
    diffs <- c(diffs, tab[k, "a"] - ex)
  }
  stat <- sum(diffs^2 / vars) - sum(diffs)^2 / sum(vars)
  df <- length(diffs) - 1L
  list(statistic = stat, df = df, p_value = stats::pchisq(stat, df, lower.tail = FALSE))
}
