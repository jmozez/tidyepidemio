#' Simulate a discrete-time SIR or SEIR epidemic
#'
#' Uses mass-action transmission with per-step infection probability
#' `1 - exp(-beta * I / N * dt)`. Progression and recovery similarly use
#' exponential transition probabilities. Transitions use the start-of-step state,
#' and there are no births, deaths, imports, or interventions. Deterministic
#' transitions use expected counts; stochastic transitions use independent
#' binomial draws. Supply rates per time unit; `dt` sets step length. Set a seed
#' before stochastic runs for reproducibility.
#' @param .data A one-row data frame containing numeric `S`, `I`, `R`, and for
#'   SEIR, `E` compartment counts.
#' @param beta Non-negative transmission rate.
#' @param gamma Non-negative recovery rate.
#' @param sigma Non-negative progression rate, required for SEIR.
#' @param steps Number of discrete time steps.
#' @param dt Positive time step.
#' @param model Either `"sir"` or `"seir"`.
#' @param stochastic Whether to sample transitions rather than take expectations.
#' @return A tibble with time and compartment columns, including initial state.
#' @examples
#' epi_simulate(data.frame(S=999, I=1, R=0), beta=0.3, gamma=0.1, steps=10)
#' @export
epi_simulate <- function(.data, beta, gamma, sigma = NULL, steps = 100L, dt = 1, model = c("sir", "seir"), stochastic = FALSE) {
  check_data(.data); model <- match.arg(model); check_scalar(beta,"beta",inclusive=TRUE); check_scalar(gamma,"gamma",inclusive=TRUE); check_scalar(dt,"dt")
  if (length(steps)!=1L || !is.numeric(steps) || is.na(steps) || !is.finite(steps) || steps < 0 || steps != floor(steps) || steps > 1e6) cli::cli_abort("{.arg steps} must be an integer from 0 to 1000000.")
  if (!is.logical(stochastic) || length(stochastic)!=1 || is.na(stochastic)) cli::cli_abort("{.arg stochastic} must be TRUE or FALSE.")
  if (model=="seir") check_scalar(sigma,"sigma",inclusive=TRUE)
  required <- if (model=="sir") c("S","I","R") else c("S","E","I","R")
  if (nrow(.data)!=1 || !all(required %in% names(.data))) cli::cli_abort("{.arg .data} must have exactly one row and columns {paste(required, collapse=', ')}.")
  state <- unlist(.data[1, required], use.names=TRUE); check_nonnegative(state,"compartments"); N <- sum(state)
  if (N<=0) cli::cli_abort("The total population must be positive.")
  if (stochastic && any(state != floor(state))) cli::cli_abort("Stochastic compartment counts must be integers.")
  mat <- matrix(0, nrow=steps+1L, ncol=length(state), dimnames=list(NULL, names(state))); mat[1,] <- state
  transition <- function(n,p) if (stochastic) stats::rbinom(1,n,p) else n*p
  if (steps > 0) for (i in seq_len(steps)) {
    s <- state; infection <- transition(s["S"], -expm1(-beta*s["I"]/N*dt)); recovery <- transition(s["I"], -expm1(-gamma*dt))
    state["S"] <- s["S"]-infection; state["R"] <- s["R"]+recovery
    if (model=="seir") { progress <- transition(s["E"], -expm1(-sigma*dt)); state["E"] <- s["E"]+infection-progress; state["I"] <- s["I"]+progress-recovery } else state["I"] <- s["I"]+infection-recovery
    mat[i+1,] <- state
  }
  tibble::as_tibble(data.frame(time=seq.int(0,steps)*dt, mat, check.names=FALSE))
}
