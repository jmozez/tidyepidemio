#' Marginal risk standardization via the g-formula
#'
#' Fits a logistic outcome model with binary exposure and selected baseline
#' covariates, predicts each individual's risk under exposure 0 and exposure 1,
#' and averages predictions over the empirical covariate distribution. Reports
#' standardized risks, their difference and their ratio. With no covariates the
#' standardized risks equal the observed risks in the two exposure groups.
#'
#' A causal interpretation requires consistency, conditional exchangeability
#' (no unmeasured confounding), positivity/overlap, appropriate temporal order,
#' no informative missingness or censoring, and a correctly specified outcome
#' model. These assumptions cannot be verified by the function. Only independent
#' individual records, linear numeric covariate terms and main effects are
#' supported. No weighting, interactions, time-varying confounding, clustered
#' bootstrap, or missing-data handling is implemented.
#'
#' With `bootstrap > 0`, ordinary nonparametric individual resampling refits the
#' model and restandardizes to the resampled population. Intervals are percentile
#' intervals. Failed or warned fits are omitted, with a warning; if more than
#' 10 percent fail, the function aborts without reporting intervals. Intervals
#' conditional on successful fits can still be biased. Set a seed for
#' reproducibility; more than 100 replicates are generally advisable.
#' @param .data An ungrouped data frame of independent individuals.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param adjust Tidy selection of complete baseline covariates; numeric,
#'   factor or logical. Defaults to no covariates.
#' @param bootstrap Number of resamples, either 0 or an integer from 100 to 2000.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A tibble with four estimates (`risk_unexposed`, `risk_exposed`,
#'   `risk_difference`, `risk_ratio`), confidence limits, record count, requested
#'   and successful bootstrap replicates. Limits are `NA` without bootstrap;
#'   the ratio is `NA` when the unexposed risk is zero.
#' @examples
#' d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
#' d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
#' epi_gcomp(d, e, y, adjust = age)
#' @export
epi_gcomp <- function(.data, exposure, outcome, adjust = c(), bootstrap = 0L, conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  eq <- rlang::enquo(exposure)
  oq <- rlang::enquo(outcome)
  aq <- rlang::enquo(adjust)
  one_name <- function(q, what) {
    nm <- names(tidyselect::eval_select(q, .data, allow_rename = FALSE))
    if (length(nm) != 1L) cli::cli_abort("Select exactly one column for {.arg {what}}.")
    nm
  }
  en <- one_name(eq, "exposure")
  yn <- one_name(oq, "outcome")
  if (identical(en, yn)) cli::cli_abort("Exposure and outcome must be distinct columns.")
  e <- check_binary(.data[[en]], "exposure")
  y <- check_binary(.data[[yn]], "outcome")
  n <- length(y)
  if (n < 4 || length(unique(e)) < 2 || length(unique(y)) < 2) cli::cli_abort("At least four observations and both exposure and outcome levels are required.")
  cols <- names(tidyselect::eval_select(aq, .data, allow_rename = FALSE))
  if (any(cols %in% c(en, yn))) cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  for (nm in cols) {
    v <- .data[[nm]]
    if (anyNA(v) || !(is.numeric(v) || is.factor(v) || is.logical(v)) || (is.numeric(v) && any(!is.finite(v))) || length(unique(v)) < 2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor or logical, and have at least two observed values.")
  }
  if (!is.numeric(bootstrap) || length(bootstrap) != 1 || is.na(bootstrap) || !is.finite(bootstrap) || bootstrap != floor(bootstrap) || !(bootstrap == 0 || (bootstrap >= 100 && bootstrap <= 2000))) cli::cli_abort("{.arg bootstrap} must be 0 or an integer from 100 to 2000.")
  if (as.double(n) * bootstrap > 5000000) cli::cli_abort("At most 5 million resampled records are supported.")
  dat <- data.frame(.outcome = y, .exposure = e)
  for (j in seq_along(cols)) dat[[paste0(".cov", j)]] <- .data[[cols[j]]]
  covs <- if (length(cols)) paste0(".cov", seq_along(cols)) else character()
  form <- stats::reformulate(c(".exposure", covs), response = ".outcome")
  compute <- function(d) {
    if (length(unique(d$.exposure)) < 2 || length(unique(d$.outcome)) < 2) stop("Missing exposure or outcome level")
    fit <- stats::glm(form, data = d, family = stats::binomial())
    if (!fit$converged || fit$rank < length(stats::coef(fit)) || anyNA(stats::coef(fit))) stop("Rank-deficient or non-convergent model")
    if (abs(stats::coef(fit)[".exposure"]) > 15 || any(stats::fitted(fit) < 1e-8 | stats::fitted(fit) > 1 - 1e-8)) warning("Possible separation or extreme fitted probabilities")
    d0 <- d
    d1 <- d
    d0$.exposure <- 0
    d1$.exposure <- 1
    p0 <- mean(stats::predict(fit, newdata = d0, type = "response"))
    p1 <- mean(stats::predict(fit, newdata = d1, type = "response"))
    if (!is.finite(p0) || !is.finite(p1)) stop("Non-finite standardized risk")
    c(p0, p1, p1 - p0, if (p0 == 0) NA_real_ else p1 / p0)
  }
  observed <- tryCatch(withCallingHandlers(compute(dat), warning = function(w) {
    cli::cli_warn("Outcome model warning: {conditionMessage(w)}")
    invokeRestart("muffleWarning")
  }), error = function(err) cli::cli_abort("Unable to fit the outcome model: {conditionMessage(err)}"))
  if (is.na(observed[4])) cli::cli_warn("The unexposed standardized risk is zero; the risk ratio is undefined.")
  low <- high <- rep(NA_real_, 4)
  successful <- 0L
  if (bootstrap > 0) {
    boot <- matrix(NA_real_, nrow = bootstrap, ncol = 4)
    for (i in seq_len(bootstrap)) {
      # Warnings such as numerical separation invalidate this replicate.
      value <- tryCatch(withCallingHandlers(compute(dat[sample.int(n, n, replace = TRUE), , drop = FALSE]), warning = function(w) stop(conditionMessage(w))), error = function(e) rep(NA_real_, 4))
      if (all(is.finite(value))) {
        boot[i, ] <- value
        successful <- successful + 1L
      }
    }
    failed <- bootstrap - successful
    if (failed > 0.1 * bootstrap) cli::cli_abort("{failed} of {bootstrap} bootstrap fits failed or warned; intervals are not reported. Inspect overlap and sparsity.")
    if (failed > 0) cli::cli_warn("{failed} of {bootstrap} bootstrap fits failed or warned and were omitted; intervals may be biased.")
    ok <- stats::complete.cases(boot)
    alpha <- 1 - conf_level
    low <- apply(boot[ok, , drop = FALSE], 2, stats::quantile, probs = alpha / 2, names = FALSE)
    high <- apply(boot[ok, , drop = FALSE], 2, stats::quantile, probs = 1 - alpha / 2, names = FALSE)
    if (is.na(observed[4])) {
      low[4] <- NA_real_
      high[4] <- NA_real_
    }
  }
  tibble::tibble(measure = c("risk_unexposed", "risk_exposed", "risk_difference", "risk_ratio"), estimate = unname(observed), conf_low = low, conf_high = high, n = n, bootstrap = as.integer(bootstrap), bootstrap_success = successful)
}
