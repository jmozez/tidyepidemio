#' Propensity-weighted marginal effects with optional bootstrap
#'
#' Fits a logistic propensity model for a binary exposure and computes separately
#' normalized (Hájek) inverse-probability-weighted outcome risks, their difference
#' and their ratio for the average-treatment-effect target population. Stabilized
#' weights use the sample marginal exposure probabilities; group normalization
#' means stabilized and unstabilized weights yield the same point risks. The
#' returned propensity range, maximum weight and group effective sample sizes are
#' descriptive diagnostics, not evidence that overlap or balance is adequate.
#'
#' With `bootstrap > 0`, individual records are resampled, the propensity model
#' is refit, and weights and contrasts are recalculated in every replicate.
#' Intervals are percentile intervals; no cluster or survey-design bootstrap is
#' included. Warned or failed bootstrap fits are omitted; more than 10 percent
#' failures abort the analysis. Intervals conditional on successful fits can
#' still be biased. Set a seed for reproducibility. Uncertainty from model
#' selection or unmeasured confounding is not included.
#'
#' Causal interpretation requires consistency, conditional exchangeability,
#' positivity, correct exposure-model specification, pre-exposure covariates,
#' independent observations and appropriate censoring and missingness assumptions.
#' These assumptions cannot be verified here. No weight trimming, missing-data
#' handling, interactions, nonlinear terms or longitudinal treatment is provided.
#' Use [epi_balance()] and substantive knowledge to assess the design.
#' @param .data An ungrouped data frame of independent individuals.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param adjust Tidy selection of complete baseline numeric, factor or logical
#'   covariates; defaults to an intercept-only exposure model.
#' @param stabilized Whether to use stabilized ATE weights.
#' @param bootstrap Number of individual bootstrap resamples, either 0 or an
#'   integer between 100 and 2000.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A four-row tibble of weighted risks, risk difference and risk ratio,
#'   with percentile limits (missing without bootstrap), group effective sample
#'   sizes, propensity range, maximum weight and bootstrap counts.
#' @examples
#' d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
#' d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
#' epi_ipw(d, e, y, adjust = age)
#' @export
epi_ipw <- function(.data, exposure, outcome, adjust = c(), stabilized = TRUE, bootstrap = 0L, conf_level = 0.95) {
  tep_tag("causal", {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  if (!is.logical(stabilized) || length(stabilized) != 1 || is.na(stabilized)) {
    cli::cli_abort("{.arg stabilized} must be TRUE or FALSE.")
  }
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
  if (n < 4 || length(unique(e)) < 2 || length(unique(y)) < 2) {
    cli::cli_abort("At least four observations and both exposure and outcome levels are required.")
  }
  cols <- names(tidyselect::eval_select(aq, .data, allow_rename = FALSE))
  if (any(cols %in% c(en, yn))) {
    cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  }
  for (nm in cols) {
    v <- .data[[nm]]
    if (anyNA(v) ||
      !(is.numeric(v) || is.factor(v) || is.logical(v)) ||
      (is.numeric(v) && any(!is.finite(v))) ||
      length(unique(v)) < 2) {
      cli::cli_abort(
        "Adjustment column {.field {nm}} must be complete, numeric, factor or logical, and have at least two observed values." # nolint: line_length_linter.
      )
    }
  }
  if (!is.numeric(bootstrap) ||
    length(bootstrap) != 1 ||
    is.na(bootstrap) ||
    !is.finite(bootstrap) ||
    bootstrap != floor(bootstrap) ||
    !(bootstrap == 0 || (bootstrap >= 100 && bootstrap <= 2000))) {
    cli::cli_abort("{.arg bootstrap} must be 0 or an integer from 100 to 2000.")
  }
  if (as.double(n) * bootstrap > 5e+06) {
    cli::cli_abort("At most 5 million resampled records are supported.")
  }
  dat <- data.frame(.exposure = e, .outcome = y)
  for (j in seq_along(cols)) dat[[paste0(".cov", j)]] <- .data[[cols[j]]]
  covs <- if (length(cols)) paste0(".cov", seq_along(cols)) else "1"
  form <- stats::reformulate(covs, response = ".exposure")
  compute <- function(d) {
    if (length(unique(d$.exposure)) < 2 || length(unique(d$.outcome)) < 2) {
      stop("Missing exposure or outcome level")
    }
    fit <- stats::glm(form, data = d, family = stats::binomial())
    if (!fit$converged || fit$rank < length(stats::coef(fit)) || anyNA(stats::coef(fit))) {
      stop("Rank-deficient or non-convergent propensity model")
    }
    p <- unname(stats::fitted(fit))
    if (any(!is.finite(p) | p <= 0 | p >= 1)) {
      stop("Propensities at zero or one give undefined weights")
    }
    if (any(p < .01 | p > .99)) warning("Extreme propensity scores indicate possible poor overlap")
    e <- d$.exposure
    y <- d$.outcome
    marginal <- mean(e)
    w <- ifelse(
      e == 1,
      if (stabilized) marginal / p else 1 / p,
      if (stabilized) (1 - marginal) / (1 - p) else 1 / (1 - p)
    )
    if (any(!is.finite(w))) stop("Non-finite propensity weights")
    group <- function(k) {
      ww <- w[e == k]
      yy <- y[e == k]
      ww <- ww / max(ww)
      c(risk = sum(ww * yy) / sum(ww), ess = sum(ww)^2 / sum(ww^2))
    }
    z <- group(0)
    o <- group(1)
    if (z["risk"] == 0) warning("Unexposed weighted risk is zero; the risk ratio is undefined")
    c(
      risk_unexposed = unname(z["risk"]),
      risk_exposed = unname(o["risk"]),
      risk_difference = unname(o["risk"] - z["risk"]),
      risk_ratio = if (z["risk"] == 0) NA_real_ else unname(o["risk"] / z["risk"]),
      ess_unexposed = unname(z["ess"]),
      ess_exposed = unname(o["ess"]),
      propensity_min = min(p),
      propensity_max = max(p),
      max_weight = max(w)
    )
  }
  observed <- tryCatch(withCallingHandlers(compute(dat), warning = function(w) {
    cli::cli_warn("Propensity analysis warning: {conditionMessage(w)}")
    invokeRestart("muffleWarning")
  }), error = function(err) cli::cli_abort("Unable to estimate weighted effects: {conditionMessage(err)}"))
  low <- high <- rep(NA_real_, 4)
  successful <- 0L
  if (bootstrap > 0) {
    boot <- matrix(NA_real_, nrow = bootstrap, ncol = 4)
    for (i in seq_len(bootstrap)) {
      value <- tryCatch(
        withCallingHandlers(
          compute(dat[sample.int(n, n, replace = TRUE), , drop = FALSE]),
          warning = function(w) stop(conditionMessage(w))
        ),
        error = function(err) rep(NA_real_, 9)
      )
      if (all(is.finite(value[1:4]))) {
        boot[i, ] <- value[1:4]
        successful <- successful + 1L
      }
    }
    failed <- bootstrap - successful
    if (failed > 0.1 * bootstrap) {
      cli::cli_abort(
        "{failed} of {bootstrap} bootstrap fits failed or warned; intervals are not reported. Inspect overlap and sparsity." # nolint: line_length_linter.
      )
    }
    if (failed > 0) {
      cli::cli_warn(
        "{failed} of {bootstrap} bootstrap fits failed or warned and were omitted; intervals may be biased."
      )
    }
    ok <- stats::complete.cases(boot)
    alpha <- 1 - conf_level
    low <- apply(boot[ok, , drop = FALSE], 2, stats::quantile, probs = alpha / 2, names = FALSE)
    high <- apply(boot[ok, , drop = FALSE], 2, stats::quantile, probs = 1 - alpha / 2, names = FALSE)
    if (is.na(observed[4])) {
      low[4] <- NA_real_
      high[4] <- NA_real_
    }
  }
  tibble::tibble(
    measure = names(observed)[1:4],
    estimate = unname(observed[1:4]),
    conf_low = low,
    conf_high = high,
    n = n,
    ess_unexposed = unname(observed[5]),
    ess_exposed = unname(observed[6]),
    propensity_min = unname(observed[7]),
    propensity_max = unname(observed[8]),
    max_weight = unname(observed[9]),
    bootstrap = as.integer(bootstrap),
    bootstrap_success = successful
  )
  })
}
