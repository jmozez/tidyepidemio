#' Parsnip epidemic model specifications
#'
#' These regression model specifications fit a single, ungrouped epidemic
#' series using the `tidyepidemio` engine. Use a formula of the form
#' `incidence ~ time` with consecutive integer time steps. The renewal model
#' estimates one constant reproduction number via a conditional Poisson model
#' with a fixed generation-interval distribution. The compartmental model fits
#' a deterministic SIR or SEIR trajectory to infectious prevalence using least
#' squares, with fixed population, recovery, and (for SEIR) progression rates;
#' only transmission is estimated. The first observation supplies the initial
#' number infectious, and initial exposed and recovered numbers are fixed.
#' Fitting can be weakly identified and the objective may have multiple minima. Predictions are point estimates only, not calibrated probabilistic
#' forecasts. These simplified models do not adjust for imports, observation
#' error, reporting delays, changes in interventions, or heterogeneous mixing.
#' @param .data Optional data frame, retained as a data-first convention. It is
#'   not used for fitting; supply data to `parsnip::fit()` instead.
#' @param mode Only `"regression"` is supported.
#' @param engine Only `"tidyepidemio"` is supported.
#' @return A parsnip model specification.
#' @examples
#' d <- data.frame(time = 1:6, cases = c(1, 2, 4, 8, 16, 32))
#' spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights = 1)
#' fit <- parsnip::fit(spec, cases ~ time, data = d)
#' predict(fit, new_data = data.frame(time = 7:8))
#' @export
epi_renewal <- function(.data = NULL, mode = "regression", engine = "tidyepidemio") {
  if (!is.null(.data) && !is.data.frame(.data)) cli::cli_abort("{.arg .data} must be NULL or a data frame.")
  if (!identical(mode, "regression")) cli::cli_abort("Only regression mode is supported.")
  parsnip::new_model_spec("epi_renewal", args = list(), eng_args = NULL, mode = mode, user_specified_mode = !missing(mode), method = NULL, engine = engine, user_specified_engine = !missing(engine))
}
#' @rdname epi_renewal
#' @examples
#' d <- data.frame(time = 0:4, infectious = c(5, 6, 7, 8, 9))
#' spec <- epi_compartmental() |>
#'   parsnip::set_engine("tidyepidemio", population = 1000, gamma = 0.1)
#' fit <- parsnip::fit(spec, infectious ~ time, data = d)
#' predict(fit, new_data = data.frame(time = 5:6))
#' seir <- epi_compartmental() |>
#'   parsnip::set_engine("tidyepidemio",
#'     population = 1000, gamma = .1,
#'     model = "seir", sigma = .2, initial_exposed = 5
#'   )
#' parsnip::fit(seir, infectious ~ time, data = d)
#' @export
epi_compartmental <- function(.data = NULL, mode = "regression", engine = "tidyepidemio") {
  if (!is.null(.data) && !is.data.frame(.data)) cli::cli_abort("{.arg .data} must be NULL or a data frame.")
  if (!identical(mode, "regression")) cli::cli_abort("Only regression mode is supported.")
  parsnip::new_model_spec("epi_compartmental", args = list(), eng_args = NULL, mode = mode, user_specified_mode = !missing(mode), method = NULL, engine = engine, user_specified_engine = !missing(engine))
}

.onLoad <- function(libname, pkgname) {
  epi_classes <- c("epi_linelist", "epi_cohort", "epi_ts")
  for (a in epi_classes) {
    for (b in epi_classes) {
      vctrs::s3_register("vctrs::vec_ptype2", paste(a, b, sep = "."), vec_ptype2.epi_tbl.epi_tbl)
      vctrs::s3_register("vctrs::vec_cast", paste(a, b, sep = "."), vec_cast.epi_tbl.epi_tbl)
    }
  }
  for (a in epi_classes) {
    for (b in c("data.frame", "tbl_df")) {
      for (generic in c("vctrs::vec_ptype2", "vctrs::vec_cast")) {
        vctrs::s3_register(generic, paste(a, b, sep = "."), epi_reject_plain_combine)
        vctrs::s3_register(generic, paste(b, a, sep = "."), epi_reject_plain_combine)
      }
    }
  }
  vctrs::s3_register("vctrs::vec_ptype2", "grouped_epi_tbl.grouped_epi_tbl", epi_group_ptype2)
  vctrs::s3_register("vctrs::vec_cast", "grouped_epi_tbl.grouped_epi_tbl", epi_group_cast)
  for (b in c("data.frame", "tbl_df", "grouped_df", epi_classes)) {
    for (generic in c("vctrs::vec_ptype2", "vctrs::vec_cast")) {
      vctrs::s3_register(generic, paste("grouped_epi_tbl", b, sep = "."), epi_group_reject_mixed)
      vctrs::s3_register(generic, paste(b, "grouped_epi_tbl", sep = "."), epi_group_reject_mixed)
    }
  }
  for (model in c("epi_renewal", "epi_compartmental")) {
    if (model %in% parsnip::get_model_env()$models) next
    parsnip::set_new_model(model)
    parsnip::set_model_mode(model, "regression")
    parsnip::set_model_engine(model, "regression", "tidyepidemio")
    parsnip::set_dependency(model, eng = "tidyepidemio", pkg = "tidyepidemio", mode = "regression")
    parsnip::set_fit(model, mode = "regression", eng = "tidyepidemio", value = list(interface = "formula", protect = c("formula", "data"), func = c(pkg = "tidyepidemio", fun = if (model == "epi_renewal") "fit_epi_renewal" else "fit_epi_compartmental"), defaults = list()))
    parsnip::set_encoding(model, mode = "regression", eng = "tidyepidemio", options = list(predictor_indicators = "none", compute_intercept = FALSE, remove_intercept = FALSE, allow_sparse_x = FALSE))
    parsnip::set_pred(model, eng = "tidyepidemio", mode = "regression", type = "numeric", value = list(pre = NULL, post = NULL, func = c(fun = "predict"), args = list(object = quote(object$fit), newdata = quote(new_data))))
  }
}
validate_model_data <- function(formula, data) {
  check_data(data)
  if (!inherits(formula, "formula") || length(formula) != 3L || !is.symbol(formula[[2]]) || !is.symbol(formula[[3]]) || identical(formula[[2]], formula[[3]])) cli::cli_abort("Use distinct, simple column names in a formula of the form outcome ~ time.")
  vars <- c(as.character(formula[[2]]), as.character(formula[[3]]))
  y <- data[[vars[1]]]
  t <- data[[vars[2]]]
  if (is.null(y) || is.null(t)) cli::cli_abort("Outcome and time must be columns in data.")
  check_nonnegative(y, "outcome")
  if (!length(t) || !is.numeric(t) || anyNA(t) || any(!is.finite(t)) || any(t != floor(t)) || length(t) < 2 || any(diff(t) != 1)) cli::cli_abort("Time must consist of at least two consecutive increasing integer steps.")
  list(y = y, time = t, time_name = vars[2], outcome = vars[1])
}
#' Epidemic model engine functions
#'
#' Low-level fit functions used by the parsnip engines. See [epi_renewal()] for
#' the model definitions and assumptions.
#' @param formula A formula with one response and one numeric time column.
#' @param data Ungrouped data in consecutive time order.
#' @param weights Generation-interval probabilities for lags 1 onward.
#' @param population Fixed total population, greater than initial compartments.
#' @param gamma Fixed non-negative per-step recovery rate.
#' @param beta_max Upper bound for optimization of the transmission rate.
#' @param model Either `"sir"` or `"seir"`.
#' @param sigma Fixed positive per-step progression rate for SEIR.
#' @param initial_exposed Fixed non-negative initial exposed count, defaulting
#'   to zero; must be zero for SIR.
#' @param initial_recovered Fixed initial recovered count for either model.
#' @return A fitted `epi_model` object.
#' @examples
#' fit_epi_renewal(cases ~ time, data.frame(time = 1:4, cases = c(1, 2, 4, 8)), weights = 1)
#' d <- data.frame(time = 0:4, infectious = c(5, 6, 7, 8, 9))
#' fit_epi_compartmental(infectious ~ time, d, population = 1000, gamma = .1)
#' @keywords internal
#' @export
fit_epi_renewal <- function(formula, data, weights = c(1)) {
  d <- validate_model_data(formula, data)
  if (any(d$y != floor(d$y))) cli::cli_abort("Renewal incidence must be integer counts.")
  check_nonnegative(weights, "weights")
  if (!length(weights) || abs(sum(weights) - 1) > 1e-8) cli::cli_abort("Generation weights must sum to one.")
  k <- length(weights)
  n <- length(d$y)
  if (n <= k) cli::cli_abort("More observations than generation lags are needed.")
  lambda <- vapply(seq.int(k + 1, n), function(i) sum(d$y[i - seq_len(k)] * weights), numeric(1))
  if (sum(lambda) <= 0 || any(lambda == 0 & d$y[seq.int(k + 1, n)] > 0)) cli::cli_abort("Observed incidence is incompatible with the supplied generation weights and history.")
  r <- sum(d$y[seq.int(k + 1, n)]) / sum(lambda)
  fitted <- c(rep(NA_real_, k), r * lambda)
  structure(list(kind = "renewal", estimate = r, weights = weights, time = d$time, outcome_name = d$outcome, time_name = d$time_name, observed = d$y, fitted = fitted), class = "epi_model")
}
#' @rdname fit_epi_renewal
#' @export
fit_epi_compartmental <- function(formula, data, population, gamma, beta_max = 10, model = c("sir", "seir"), sigma = NULL, initial_exposed = 0, initial_recovered = 0) {
  d <- validate_model_data(formula, data)
  model <- match.arg(model)
  check_scalar(population, "population")
  check_scalar(gamma, "gamma", inclusive = TRUE)
  check_scalar(beta_max, "beta_max")
  check_scalar(initial_exposed, "initial_exposed", inclusive = TRUE)
  check_scalar(initial_recovered, "initial_recovered", inclusive = TRUE)
  if (model == "seir") {
    check_scalar(sigma, "sigma")
    if (length(d$y) < 3) cli::cli_abort("At least three observations are required for an SEIR transmission fit.")
  } else if (initial_exposed != 0 || !is.null(sigma)) cli::cli_abort("For SIR, {.arg initial_exposed} must be zero and {.arg sigma} must be NULL.")
  initial_susceptible <- population - d$y[1] - initial_exposed - initial_recovered
  if (d$y[1] <= 0 || initial_susceptible <= 0 || any(d$y > population)) cli::cli_abort("Initial infectious prevalence and susceptible population must be positive, and observations must not exceed population.")
  initial <- data.frame(S = initial_susceptible, E = initial_exposed, I = d$y[1], R = initial_recovered)
  make_curve <- function(beta, steps) epi_simulate(initial, beta = beta, gamma = gamma, sigma = sigma, steps = steps, model = model)$I
  objective <- function(beta) sum((d$y - make_curve(beta, length(d$y) - 1L))^2)
  opt <- stats::optimize(objective, c(0, beta_max))
  candidate <- c(0, opt$minimum, beta_max)
  values <- vapply(candidate, objective, numeric(1))
  beta <- candidate[which.min(values)]
  if (beta == 0 || beta == beta_max) cli::cli_warn("Transmission estimate is on an optimization boundary; reassess the data and {.arg beta_max}.")
  structure(list(kind = "compartmental", model = model, estimate = beta, gamma = gamma, sigma = sigma, initial_exposed = initial_exposed, initial_recovered = initial_recovered, population = population, time = d$time, outcome_name = d$outcome, time_name = d$time_name, observed = d$y, fitted = make_curve(beta, length(d$y) - 1L)), class = "epi_model")
}
#' @export
predict.epi_model <- function(object, newdata, ...) {
  if (!is.data.frame(newdata) || !object$time_name %in% names(newdata)) cli::cli_abort("New data must contain time column {.field {object$time_name}}.")
  t <- newdata[[object$time_name]]
  first <- object$time[1]
  last <- utils::tail(object$time, 1)
  if (!is.numeric(t) || anyNA(t) || any(!is.finite(t)) || any(t != floor(t)) || any(t < first)) cli::cli_abort("Prediction times must be finite integers at or after the first training time.")
  if (!length(t)) {
    return(numeric())
  }
  if (max(t) - first > 1000000) cli::cli_abort("The requested prediction horizon is too large.")
  if (object$kind == "compartmental") {
    y0 <- object$observed[1]
    model <- if (is.null(object$model)) "sir" else object$model
    e0 <- if (is.null(object$initial_exposed)) 0 else object$initial_exposed
    r0 <- if (is.null(object$initial_recovered)) 0 else object$initial_recovered
    initial <- data.frame(S = object$population - y0 - e0 - r0, E = e0, I = y0, R = r0)
    vals <- epi_simulate(initial, beta = object$estimate, gamma = object$gamma, sigma = object$sigma, steps = max(t) - first, model = model)$I
  } else {
    # In-sample predictions condition on observed past incidence. Future values
    # recursively use expected incidence, seeded by the observed training tail.
    vals <- object$fitted
    history <- object$observed
    k <- length(object$weights)
    if (max(t) > last) {
      for (i in seq_len(max(t) - last)) {
        new <- object$estimate * sum(utils::tail(history, k)[k:1] * object$weights)
        history <- c(history, new)
        vals <- c(vals, new)
      }
    }
  }
  unname(vals[t - first + 1L])
}
