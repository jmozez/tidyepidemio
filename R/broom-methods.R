#' Tidy epidemiological results and fitted epidemic models
#'
#' `tidy()` returns a tibble of effect estimates or model parameters. `glance()`
#' returns a one-row description. `augment()` on an `epi_model` returns fitted
#' and residual values for training data, or predictions for supplied new data.
#' For the renewal model, early fitted values are missing until all lags exist.
#' @param x An `epi_result` or `epi_model` object.
#' @param data Optional new data for `augment()`; default uses training records.
#' @param ... Unused.
#' @return A tibble of estimates, summary information, or augmented observations.
#' @examples
#' d <- data.frame(e = rep(0:1, each = 4), y = c(0, 0, 0, 1, 0, 1, 1, 1))
#' x <- epi_risk_ratio(d, e, y)
#' generics::tidy(x)
#' f <- fit_epi_renewal(y ~ time, data.frame(time = 1:4, y = c(1, 2, 4, 8)))
#' generics::augment(f)
#' @export
#' @method tidy epi_result
tidy.epi_result <- function(x, ...) tibble::as_tibble(x)
#' @rdname tidy.epi_result
#' @export
#' @method glance epi_result
glance.epi_result <- function(x, ...) tibble::tibble(measure = x$measure, estimate = x$estimate, conf_low = x$conf_low, conf_high = x$conf_high)
#' @rdname tidy.epi_result
#' @export
#' @method tidy epi_model
tidy.epi_model <- function(x, ...) {
  if (x$kind == "renewal") {
    tibble::tibble(term = "R", estimate = x$estimate)
  } else {
    if (identical(x$model, "seir")) tibble::tibble(term = c("beta", "gamma", "sigma"), estimate = c(x$estimate, x$gamma, x$sigma), fixed = c(FALSE, TRUE, TRUE)) else tibble::tibble(term = c("beta", "gamma"), estimate = c(x$estimate, x$gamma), fixed = c(FALSE, TRUE))
  }
}
#' @rdname tidy.epi_result
#' @export
#' @method glance epi_model
glance.epi_model <- function(x, ...) {
  usable <- !is.na(x$fitted)
  tibble::tibble(model = x$kind, nobs = length(x$observed), n_fitted = sum(usable), rmse = if (any(usable)) sqrt(mean((x$observed[usable] - x$fitted[usable])^2)) else NA_real_)
}
#' @rdname tidy.epi_result
#' @export
#' @method augment epi_model
augment.epi_model <- function(x, data = NULL, ...) {
  if (is.null(data)) {
    result <- tibble::as_tibble(stats::setNames(list(x$time, x$observed, x$fitted, x$observed - x$fitted), c(x$time_name, x$outcome_name, ".fitted", ".resid")))
  } else {
    if (!is.data.frame(data)) cli::cli_abort("{.arg data} must be a data frame.")
    if (any(c(".fitted", ".resid") %in% names(data))) cli::cli_abort("Data already contain {.field .fitted} or {.field .resid}.")
    result <- tibble::as_tibble(data)
    result$.fitted <- stats::predict(x, newdata = data)
    if (x$outcome_name %in% names(data)) {
      if (!is.numeric(data[[x$outcome_name]])) cli::cli_abort("Outcome values must be numeric.")
      result$.resid <- data[[x$outcome_name]] - result$.fitted
    }
  }
  result
}
new_epi_result <- function(x) vctrs::new_data_frame(x, n = nrow(x), class = c("epi_result", "tbl_df", "tbl"))
