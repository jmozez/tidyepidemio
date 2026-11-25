#' Simulate SIR or SEIR with time-varying rates
#'
#' The schedule has one row per time step, with non-negative transmission
#' (`beta`), recovery (`gamma`), and, for SEIR, progression (`sigma`) rates.
#' All rates apply during the corresponding step. This supports explicitly
#' scheduled interventions, not feedback policies or transmission heterogeneity.
#' The infection, progression and recovery probabilities use exponential hazards
#' over `dt`, with each transition based on the state at the start of the step.
#' Deterministic transitions are conditional expected flows; stochastic
#' transitions are independent binomial draws from their source compartments.
#' The first output row is the initial state and has missing transition flows.
#' The output has no births, deaths, importations or observation model. These are
#' discrete-time approximations, not continuous-time exact Markov or ODE models.
#' Set the R random seed for reproducible stochastic simulations.
#' @param .data A non-empty data frame, with one row per time step and numeric
#'   `beta` and `gamma` columns; SEIR also requires `sigma`.
#' @param initial A one-row data frame with `S`, `I`, `R` and for SEIR `E`.
#' @param dt Positive duration of each step, in units compatible with the rates.
#' @param model Either `"sir"` or `"seir"`.
#' @param stochastic Whether to draw integer transitions.
#' @return A tibble with time, compartment counts and new infection, progression
#'   and recovery flows. SIR progression flow is always missing.
#' @examples
#' schedule <- data.frame(beta = c(.3, .3, .1, .1), gamma = .1)
#' epi_simulate_schedule(schedule, initial = data.frame(S = 999, I = 1, R = 0))
#' @export
epi_simulate_schedule <- function(.data, initial, dt = 1, model = c("sir", "seir"), stochastic = FALSE) {
  check_data(.data)
  check_data(initial)
  model <- match.arg(model)
  check_scalar(dt, "dt")
  if (!is.logical(stochastic) || length(stochastic) != 1L || is.na(stochastic)) {
    cli::cli_abort("{.arg stochastic} must be TRUE or FALSE.")
  }
  comp <- if (model == "sir") c("S", "I", "R") else c("S", "E", "I", "R")
  rate <- if (model == "sir") c("beta", "gamma") else c("beta", "gamma", "sigma")
  if (nrow(initial) != 1L || !all(comp %in% names(initial))) {
    cli::cli_abort(
      "{.arg initial} must be one row with compartment columns {paste(comp,collapse=', ')}."
    )
  }
  if (!nrow(.data) || !all(rate %in% names(.data))) {
    cli::cli_abort(
      "The non-empty schedule must contain numeric rate columns {paste(rate,collapse=', ')}."
    )
  }
  if (nrow(.data) > 1000000) cli::cli_abort("At most one million schedule steps are supported.")
  for (nm in comp) check_nonnegative(initial[[nm]], nm)
  for (nm in rate) check_nonnegative(.data[[nm]], nm)
  state <- unlist(initial[1, comp], use.names = TRUE)
  N <- sum(state)
  if (!is.finite(N) || N <= 0) {
    cli::cli_abort("Initial population must have a finite positive total.")
  }
  if (stochastic && any(state != floor(state))) {
    cli::cli_abort("Stochastic compartment counts must be integers.")
  }
  steps <- nrow(.data)
  mat <- matrix(0, steps + 1L, length(comp), dimnames = list(NULL, comp))
  mat[1, ] <- state
  infections <- progressions <- recoveries <- rep(NA_real_, steps + 1L)
  transition <- function(n, p) if (stochastic) stats::rbinom(1, n, p) else n * p
  for (i in seq_len(steps)) {
    s <- state
    infection <- transition(s["S"], -expm1(-.data$beta[i] * s["I"] / N * dt))
    recovery <- transition(s["I"], -expm1(-.data$gamma[i] * dt))
    state["S"] <- s["S"] - infection
    state["R"] <- s["R"] + recovery
    if (model == "seir") {
      progress <- transition(s["E"], -expm1(-.data$sigma[i] * dt))
      state["E"] <- s["E"] + infection - progress
      state["I"] <- s["I"] + progress - recovery
      progressions[i + 1L] <- progress
    } else {
      state["I"] <- s["I"] + infection - recovery
    }
    mat[i + 1L, ] <- state
    infections[i + 1L] <- infection
    recoveries[i + 1L] <- recovery
  }
  out <- tibble::as_tibble(data.frame(time = seq.int(0, steps) * dt, mat, check.names = FALSE))
  out$new_infections <- infections
  out$new_progressions <- progressions
  out$new_recoveries <- recoveries
  out
}
