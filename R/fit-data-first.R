#' Fit simplified epidemic models with data-first column selection
#'
#' Data-first alternatives to the formula-based engine functions used by
#' parsnip. The renewal fit estimates a constant reproduction number using
#' a conditional Poisson mean and fixed generation weights. The compartmental
#' fit estimates transmission by least squares with the population, recovery
#' and initial states fixed. These methods use the same models and assumptions
#' as [epi_renewal()] and [epi_compartmental()]; this is not a calibrated or
#' validated forecasting system. Select exactly one distinct column for each
#' argument; non-syntactic names can be selected using backticks or `all_of()`.
#' @param .data An ungrouped data frame with consecutive integer time steps.
#' @param time A single time column selected using tidy selection.
#' @param cases A single non-negative integer incidence column for renewal.
#' @param infectious A single non-negative infectious prevalence column for the
#'   compartmental fit. The first value supplies the initial infectious count.
#' @param weights Generation-interval probabilities by lag, summing to one.
#' @param population Fixed total population greater than initial compartments.
#' @param gamma Fixed non-negative recovery rate.
#' @param beta_max Positive upper bound for transmission-rate optimization.
#' @param model Either `"sir"` or `"seir"`.
#' @param sigma Fixed positive progression rate, required for SEIR.
#' @param initial_exposed Fixed non-negative initial exposed count, zero for SIR.
#' @param initial_recovered Fixed non-negative initial recovered count.
#' @return A fitted `epi_model` suitable for `predict()`, `generics::tidy()`,
#'   `generics::glance()` and `generics::augment()`. This is an engine model,
#'   not a parsnip model specification.
#' @examples
#' d <- data.frame(day = 1:5, cases = c(1, 2, 4, 8, 16))
#' fit <- epi_fit_renewal(d, day, cases, weights = 1)
#' predict(fit, newdata = data.frame(day = 6:7))
#' c <- data.frame(day = 0:4, infectious = c(5, 6, 7, 8, 9))
#' epi_fit_compartmental(c, day, infectious, population = 1000, gamma = .1)
#' @export
epi_fit_renewal <- function(.data, time, cases, weights = 1) {
  formula <- epi_selected_formula(.data, rlang::enquo(time), rlang::enquo(cases))
  fit_epi_renewal(formula, data = .data, weights = weights)
}
#' @rdname epi_fit_renewal
#' @export
epi_fit_compartmental <- function(.data, time, infectious, population, gamma, beta_max = 10, model = c("sir", "seir"), sigma = NULL, initial_exposed = 0, initial_recovered = 0) {
  formula <- epi_selected_formula(.data, rlang::enquo(time), rlang::enquo(infectious))
  fit_epi_compartmental(formula, data = .data, population = population, gamma = gamma, beta_max = beta_max, model = model, sigma = sigma, initial_exposed = initial_exposed, initial_recovered = initial_recovered)
}
epi_selected_formula <- function(.data, tq, yq) {
  check_data(.data)
  select_one <- function(q, what) {
    selected <- names(tidyselect::eval_select(q, .data, allow_rename = FALSE))
    if (length(selected) != 1L) cli::cli_abort("Select exactly one column for {.arg {what}}.")
    selected
  }
  t <- select_one(tq, "time")
  y <- select_one(yq, "outcome")
  if (identical(t, y)) cli::cli_abort("Time and outcome must be distinct columns.")
  rlang::new_formula(rlang::sym(y), rlang::sym(t), env = rlang::caller_env())
}
