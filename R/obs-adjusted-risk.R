#' Adjusted risk ratio using modified Poisson regression
#'
#' Fits a Poisson log-link model to a binary outcome and reports an exponentiated
#' exposure coefficient with a sandwich-based normal-Wald interval. The sandwich
#' estimator uses uncorrected HC0 independent-observation scores by default, or
#' cluster-summed scores when `cluster` is supplied; `robust = "HC1"` adds the
#' usual small-sample factor. Normal inference can be inaccurate with few clusters. Unlike a
#' Poisson mean model for counts, this method uses a robust variance estimator
#' because the outcome is binary. Fitted means can exceed one; a warning is
#' issued and the working model should then be scrutinized.
#'
#' Requires complete data, a correctly specified log risk model, appropriate
#' independence or independent clusters, sufficient overlap and large-sample
#' inference. The result is a covariate-conditional risk ratio, not automatically
#' a causal effect. Weights, effect modification and spline terms work as in
#' [epi_adjusted_odds_ratio()]. There is no imputation or assessment of
#' confounding assumptions.
#' @param .data An ungrouped data frame, one row per individual.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param adjust Tidy selection of complete numeric, factor or logical covariates.
#' @param cluster Optional complete cluster identifier column. If supplied, all
#'   observations within a cluster may be dependent; distinct clusters are
#'   assumed independent.
#' @param conf_level Confidence level strictly between zero and one.
#' @param robust Sandwich standard-error type, `"HC0"` or `"HC1"`.
#' @inheritParams epi_adjusted_odds_ratio
#' @return An `epi_result` tibble with risk ratio, confidence limits, number of
#'   observations, standard-error type, cluster count and covariate names.
#' @examples
#' d <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
#' d$y <- as.integer(d$rep <= 1 + d$e + (d$age %% 2))
#' epi_adjusted_risk_ratio(d, e, y, adjust = age)
#' @export
epi_adjusted_risk_ratio <- function(.data, exposure, outcome, adjust = c(), cluster = NULL, conf_level = 0.95,
                                    weights = NULL, robust = c("HC0", "HC1"), modifier = NULL, nonlinear = c()) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  robust <- match.arg(robust)
  en <- adjusted_one_name(.data, rlang::enquo(exposure), "exposure")
  yn <- adjusted_one_name(.data, rlang::enquo(outcome), "outcome")
  if (identical(en, yn)) cli::cli_abort("Exposure and outcome must be distinct columns.")
  e <- check_binary(.data[[en]], "exposure")
  y <- check_binary(.data[[yn]], "outcome")
  if (length(y) < 4 || length(unique(e)) < 2 || length(unique(y)) < 2) cli::cli_abort("Both exposure and outcome levels and at least four records are required.")
  selected <- names(tidyselect::eval_select(rlang::enquo(adjust), .data, allow_rename = FALSE))
  if (any(selected %in% c(en, yn))) cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  over_one <- function(fit, mu) if (any(mu > 1 + 1e-8)) cli::cli_warn("Some fitted risks exceed one; inspect the log risk model and its predictions.")
  adjusted_glm(.data, y, e, selected, c(en, yn), stats::poisson(link = "log"), "adjusted_risk_ratio", conf_level,
    rlang::enquo(weights), rlang::enquo(cluster), rlang::enquo(modifier), rlang::enquo(nonlinear), robust,
    extra = list(n = length(y)), check_fit = over_one, keep_clusters = TRUE
  )
}
