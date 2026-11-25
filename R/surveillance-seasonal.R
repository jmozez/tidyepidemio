#' Seasonal Poisson surveillance using an earlier baseline
#'
#' Fits a Poisson log-linear baseline with Fourier seasonal terms to a separate
#' training data frame, then flags later observed counts that exceed the
#' `(1 - alpha)` Poisson quantile at the fitted mean. The training observations
#' must all precede the new observations; the model is never fit on the new
#' counts. Fourier period is expressed in the same units as the numeric time
#' column. Optional linear trend is centered and scaled using training time only.
#'
#' The interval threshold is conditional on the fitted mean and ignores
#' parameter uncertainty. Independent Poisson counts, a correctly specified
#' seasonal pattern, a stable exposure/population, and an outbreak-free training
#' period are important assumptions. With `family = "negbin"` the baseline is a
#' negative binomial model (`MASS::glm.nb()`), and thresholds and p-values use its
#' estimated dispersion, which reduces false alerts from overdispersed counts.
#' Each row gets an upper-tail p-value `P(Y >= cases)`; with `adjust` other than
#' `"none"`, alerts use p-values adjusted across all screened rows by
#' [stats::p.adjust()], controlling family-wise error or false discovery rate
#' for the batch. Reporting delays, holidays, changing population, baseline
#' outbreaks, trend extrapolation and model selection can still increase false
#' alerts. This is a screening rule, not
#' a validated outbreak detection system; a flag is not an outbreak diagnosis.
#' @param .data An ungrouped data frame of later observations to screen.
#' @param time A numeric time column, strictly increasing in both datasets.
#' @param cases A non-negative integer count column, complete in both datasets.
#' @param training An ungrouped data frame of earlier baseline observations with
#'   the same `time` and `cases` columns.
#' @param period Positive length of a seasonal cycle in time units.
#' @param harmonics Number of sine/cosine harmonics, between 1 and 5.
#' @param trend Whether to include a linear time trend.
#' @param alpha Nominal upper-tail probability strictly between zero and one.
#' @param family Baseline count model: `"poisson"` or `"negbin"`.
#' @param adjust Multiple-testing adjustment passed to [stats::p.adjust()], such
#'   as `"none"`, `"holm"`, `"bonferroni"` or `"BH"`.
#' @return Input tibble with `baseline_expected`, `threshold` (the unadjusted
#'   per-row quantile), `p_value`, `p_adjusted` and logical `alert` columns. Counts exactly equal to the threshold are not flagged.
#' @examples
#' train <- data.frame(t = 1:40, cases = rep(c(4, 6, 8, 6), 10))
#' new <- data.frame(t = 41:42, cases = c(20, 5))
#' epi_seasonal_surveillance(new, t, cases, training = train, period = 4)
#' @export
epi_seasonal_surveillance <- function(.data, time, cases, training, period, harmonics = 1L, trend = FALSE, alpha = 0.05,
                                      family = c("poisson", "negbin"), adjust = "none") {
  family <- match.arg(family)
  adjust <- match.arg(adjust, stats::p.adjust.methods)
  check_data(.data)
  check_data(training)
  check_scalar(period, "period")
  check_window(harmonics, "harmonics")
  check_probability(alpha, "alpha")
  if (harmonics > 5) cli::cli_abort("{.arg harmonics} must not exceed 5.")
  if (!is.logical(trend) || length(trend) != 1 || is.na(trend)) cli::cli_abort("{.arg trend} must be TRUE or FALSE.")
  tn <- names(tidyselect::eval_select(rlang::enquo(time), .data, allow_rename = FALSE))
  cn <- names(tidyselect::eval_select(rlang::enquo(cases), .data, allow_rename = FALSE))
  if (length(tn) != 1L || length(cn) != 1L || identical(tn, cn) || !all(c(tn, cn) %in% names(training))) cli::cli_abort("Select distinct time and cases columns present in both datasets.")
  if (any(c("baseline_expected", "threshold", "p_value", "p_adjusted", "alert") %in% names(.data))) cli::cli_abort("Output columns already exist; rename them before surveillance.")
  t0 <- training[[tn]]
  t1 <- .data[[tn]]
  y0 <- training[[cn]]
  y1 <- .data[[cn]]
  valid_time <- function(t) is.numeric(t) && length(t) > 0 && !anyNA(t) && all(is.finite(t)) && all(diff(t) > 0)
  if (!valid_time(t0) || !valid_time(t1) || utils::tail(t0, 1) >= t1[1]) cli::cli_abort("Time must be finite and strictly increasing within each dataset, with training entirely before new data.")
  check_nonnegative(y0, "training cases")
  check_nonnegative(y1, "cases")
  if (any(y0 != floor(y0)) || any(y1 != floor(y1)) || sum(y0) == 0) cli::cli_abort("Counts must be non-negative integers and training must contain at least one event.")
  nparams <- 1L + 2L * harmonics + as.integer(trend)
  if (length(t0) <= nparams) cli::cli_abort("Training must contain more observations than model parameters.")
  center <- mean(t0)
  scale <- stats::sd(t0)
  basis <- function(t) {
    d <- data.frame(.response = rep(0, length(t)))
    if (trend) d$.trend <- (t - center) / scale
    for (k in seq_len(harmonics)) {
      d[[paste0(".sin", k)]] <- sin(2 * pi * k * t / period)
      d[[paste0(".cos", k)]] <- cos(2 * pi * k * t / period)
    }
    d
  }
  a <- basis(t0)
  a$.response <- y0
  b <- basis(t1)
  form <- stats::reformulate(setdiff(names(a), ".response"), response = ".response")
  fit <- withCallingHandlers(if (family == "negbin") MASS::glm.nb(form, data = a) else stats::glm(form, data = a, family = stats::poisson()), warning = function(w) {
    cli::cli_warn("Seasonal baseline fitting warning: {conditionMessage(w)}")
    invokeRestart("muffleWarning")
  })
  if (!fit$converged || fit$rank < length(stats::coef(fit)) || anyNA(stats::coef(fit))) cli::cli_abort("Seasonal baseline is rank-deficient or did not converge; revise period, harmonics and training data.")
  expected <- as.numeric(stats::predict(fit, newdata = b, type = "response"))
  if (any(!is.finite(expected)) || any(expected <= 0)) cli::cli_abort("Predicted baseline is not finite and positive; inspect trend extrapolation and training data.")
  size <- rep(if (family == "negbin") fit$theta else Inf, length(expected))
  threshold <- surveillance_quantile(alpha, expected, size)
  if (any(!is.finite(threshold))) cli::cli_abort("The threshold is not finite; inspect baseline and alpha.")
  tail <- surveillance_tail(y1, expected, size, adjust)
  out <- tibble::as_tibble(.data)
  out$baseline_expected <- expected
  out$threshold <- threshold
  out$p_value <- tail$p
  out$p_adjusted <- tail$adjusted
  out$alert <- tail$adjusted <= alpha
  out
}
