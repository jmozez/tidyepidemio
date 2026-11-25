#' Covariate-adjusted Poisson incidence rate ratio
#'
#' Fits a log-link Poisson regression with log person-time as an offset and
#' reports the exponentiated binary exposure coefficient with a normal-Wald
#' confidence interval. Model-based errors require independent counts, a
#' correctly specified multiplicative rate model and Poisson variance. Use
#' `robust = "HC0"` or `"HC1"` for sandwich errors that remain valid under
#' overdispersion, and `cluster` for recurrent events or other dependence within
#' clusters. Weights, effect modification and spline terms work as in
#' [epi_adjusted_odds_ratio()]. Missing data are not handled. Assess fit and confounding assumptions
#' separately; this is not automatically a causal effect.
#' @param .data Ungrouped data frame with one row per record or aggregated cell.
#' @param events Non-negative integer event counts.
#' @param time Positive person-time or other exposure per row.
#' @param exposure Binary 0/1 exposure column.
#' @param adjust Tidy selection of complete numeric, factor or logical covariates.
#' @param conf_level Confidence level strictly between zero and one.
#' @inheritParams epi_adjusted_odds_ratio
#' @return An `epi_result` tibble containing the adjusted rate ratio, Wald
#'   confidence limits, event and record counts, and covariate names.
#' @examples
#' d <- data.frame(
#'   e = rep(0:1, each = 6), events = c(1, 2, 1, 2, 3, 1, 3, 4, 2, 4, 5, 3),
#'   time = rep(10, 12), age = rep(1:3, 4)
#' )
#' epi_adjusted_rate_ratio(d, events, time, e, adjust = age)
#' @export
epi_adjusted_rate_ratio <- function(.data, events, time, exposure, adjust = c(), conf_level = 0.95,
                                    weights = NULL, cluster = NULL, robust = c("model", "HC0", "HC1"),
                                    modifier = NULL, nonlinear = c()) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  robust <- match.arg(robust)
  yn <- adjusted_one_name(.data, rlang::enquo(events), "events")
  tn <- adjusted_one_name(.data, rlang::enquo(time), "time")
  en <- adjusted_one_name(.data, rlang::enquo(exposure), "exposure")
  used <- c(yn, tn, en)
  if (anyDuplicated(used)) cli::cli_abort("Events, time and exposure must be distinct columns.")
  y <- .data[[yn]]
  t <- .data[[tn]]
  e <- check_binary(.data[[en]], "exposure")
  check_nonnegative(y, "events")
  check_nonnegative(t, "time", positive = TRUE)
  if (length(y) < 4 || any(y != floor(y)) || sum(y) == 0 || length(unique(e)) < 2) {
    cli::cli_abort(
      "At least four records, integer counts with at least one event, and both exposure levels are required."
    )
  }
  selected <- names(tidyselect::eval_select(rlang::enquo(adjust), .data, allow_rename = FALSE))
  if (any(selected %in% used)) {
    cli::cli_abort("Adjustment columns must exclude events, time and exposure.")
  }
  adjusted_glm(.data, y, e, selected, used, stats::poisson(), "adjusted_rate_ratio", conf_level,
    rlang::enquo(weights), rlang::enquo(cluster), rlang::enquo(modifier), rlang::enquo(nonlinear), robust,
    offset = log(t), extra = list(n = length(y), events = sum(y))
  )
}
