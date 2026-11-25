#' Stratified bootstrap confidence interval for empirical ROC AUC
#'
#' Computes the rank-based empirical AUC, counting tied case-control pairs as
#' one half. Individual cases and controls are resampled independently within
#' their outcome groups; a percentile interval is formed from the resampled
#' AUCs. A lower-is-positive score is supported via `direction = "lower"`.
#' Set a random seed for reproducible intervals.
#'
#' This quantifies sampling uncertainty conditional on the observed numbers of
#' cases and controls and the supplied scores. It does not refit a predictive
#' model, correct training-set optimism, account for clustering or survey
#' sampling, or compare correlated AUCs. Use independent validation data and
#' independent individuals. Small samples and highly discrete scores can give
#' poor percentile-interval coverage; no clinical operating threshold is chosen.
#' @param .data An ungrouped data frame of independent subjects.
#' @param truth Binary reference outcome, 1 for the event.
#' @param score Finite numeric score; probabilities are not required.
#' @param direction Whether `"higher"` or `"lower"` scores are more positive.
#' @param bootstrap Number of resamples, an integer from 100 to 2000.
#' @param conf_level Confidence level strictly between zero and one.
#' @return One-row tibble with AUC, percentile confidence limits, numbers of
#'   cases and controls, confidence level and bootstrap count.
#' @examples
#' d <- data.frame(y = rep(0:1, each = 5), score = c(1, 2, 3, 4, 5, 2, 3, 4, 5, 6))
#' set.seed(17)
#' epi_auc_ci(d, y, score, bootstrap = 100)
#' @export
epi_auc_ci <- function(.data, truth, score, direction = c("higher", "lower"), bootstrap = 1000L, conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  direction <- match.arg(direction)
  y <- check_binary(column(.data, rlang::enquo(truth), "truth"), "truth")
  s <- column(.data, rlang::enquo(score), "score")
  if (!is.numeric(s) || anyNA(s) || any(!is.finite(s))) {
    cli::cli_abort("{.arg score} must be finite numeric without missing values.")
  }
  n1 <- sum(y == 1)
  n0 <- sum(y == 0)
  if (n1 < 2 || n0 < 2) cli::cli_abort("At least two cases and two controls are required.")
  if (!is.numeric(bootstrap) ||
    length(bootstrap) != 1 ||
    is.na(bootstrap) ||
    !is.finite(bootstrap) ||
    bootstrap != floor(bootstrap) ||
    bootstrap < 100 ||
    bootstrap > 2000) {
    cli::cli_abort("{.arg bootstrap} must be an integer between 100 and 2000.")
  }
  if (as.double(length(y)) * bootstrap > 5e+06) {
    cli::cli_abort("At most 5 million resampled records are supported.")
  }
  if (direction == "lower") s <- -s
  controls <- s[y == 0]
  cases <- s[y == 1]
  auc <- function(a, b) {
    n <- as.double(length(a))
    m <- as.double(length(b))
    (sum(rank(c(a, b), ties.method = "average")[seq_len(n)]) - n * (n + 1) / 2) / (n * m)
  }
  estimate <- auc(cases, controls)
  draws <- numeric(bootstrap)
  for (i in seq_len(bootstrap)) {
    draws[i] <- auc(cases[sample.int(n1, n1, replace = TRUE)], controls[sample.int(n0, n0, replace = TRUE)])
  }
  alpha <- 1 - conf_level
  bounds <- stats::quantile(draws, probs = c(alpha / 2, 1 - alpha / 2), names = FALSE)
  tibble::tibble(
    estimate = estimate,
    conf_low = bounds[1],
    conf_high = bounds[2],
    cases = n1,
    controls = n0,
    conf_level = conf_level,
    bootstrap = as.integer(bootstrap)
  )
}
