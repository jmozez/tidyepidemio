#' Epidemiological frequency measures
#'
#' Functions operate on complete records, rejecting missing and invalid inputs.
#' Incidence and attack rate are cumulative proportions; prevalence is a point
#' prevalence. Person-time rates use the units supplied by the caller.
#' @param .data A data frame, with one row per individual.
#' @param event A 0/1 event indicator.
#' @param case A 0/1 indicator of existing disease.
#' @param time Non-negative follow-up time per person.
#' @param multiplier A positive scale factor; for example 1000 for per 1000.
#' @return A one-row tibble with numerator, denominator, and estimate.
#' @examples
#' d <- data.frame(event = c(1, 0, 1), time = c(1, 2, 3))
#' epi_incidence(d, event)
#' epi_prevalence(d, event)
#' epi_attack_rate(d, event, multiplier=100)
#' epi_person_time(d, event, time, multiplier = 100)
#' @export
epi_incidence <- function(.data, event, multiplier = 1) {
  check_data(.data); check_scalar(multiplier, "multiplier"); x <- check_binary(column(.data, rlang::enquo(event), "event"), "event")
  if (!length(x)) cli::cli_abort("{.arg .data} must have at least one row.")
  tibble::tibble(events = sum(x), population = length(x), estimate = mean(x) * multiplier)
}
#' @rdname epi_incidence
#' @export
epi_prevalence <- function(.data, case, multiplier = 1) {
  check_data(.data); check_scalar(multiplier, "multiplier"); x <- check_binary(column(.data, rlang::enquo(case), "case"), "case")
  if (!length(x)) cli::cli_abort("{.arg .data} must have at least one row.")
  tibble::tibble(cases = sum(x), population = length(x), estimate = mean(x) * multiplier)
}
#' @rdname epi_incidence
#' @export
epi_attack_rate <- function(.data, event, multiplier = 1) epi_incidence(.data, {{event}}, multiplier = multiplier)
#' @rdname epi_incidence
#' @export
epi_person_time <- function(.data, event, time, multiplier = 1) {
  check_data(.data); check_scalar(multiplier, "multiplier"); e <- check_binary(column(.data, rlang::enquo(event), "event"), "event"); t <- column(.data, rlang::enquo(time), "time"); check_nonnegative(t, "time")
  if (sum(t) <= 0) cli::cli_abort("Total follow-up time must be positive.")
  tibble::tibble(events = sum(e), person_time = sum(t), estimate = sum(e) / sum(t) * multiplier)
}
