#' Covariate-adjusted Cox proportional hazards ratio
#'
#' Fits a Cox model with a binary exposure and optional covariates, using the
#' `survival` package. Entry times allow left truncation via `(entry, time]`
#' risk intervals. The exposure coefficient is exponentiated and accompanied
#' by a normal-Wald confidence interval. Ties use the specified Cox method.
#'
#' Requires independent observations, independent censoring/truncation
#' conditional on covariates, correct covariate specification and proportional
#' hazards. The function does not check these assumptions, account for
#' competing risks, clustering, time-varying covariates, or assess a causal
#' effect. Sparse data or separation can make the estimates unreliable.
#' @param .data An ungrouped data frame, one independent record per person.
#' @param time Non-negative observed exit or follow-up time.
#' @param event Binary indicator: 1 for the event, 0 for censoring.
#' @param exposure Binary 0/1 exposure.
#' @param adjust Tidy selection of complete numeric, factor or logical covariate
#'   columns; defaults to no additional covariates.
#' @param entry Optional non-negative entry time column for left truncation;
#'   values must be strictly less than exit time. Defaults to no truncation.
#' @param ties One of `"efron"`, `"breslow"`, or `"exact"`.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble with hazard ratio, Wald confidence limits,
#'   number of observations and events, and covariate names.
#' @examples
#' d <- data.frame(
#'   t = 1:12, event = c(1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1),
#'   e = rep(0:1, 6), age = rep(30:33, 3)
#' )
#' epi_cox_hazard_ratio(d, t, event, e, adjust = age)
#' @export
epi_cox_hazard_ratio <- function(.data, time, event, exposure, adjust = c(), entry = NULL, ties = c("efron", "breslow", "exact"), conf_level = 0.95) {
  check_data(.data)
  check_probability(conf_level, "conf_level")
  ties <- match.arg(ties)
  tq <- rlang::enquo(time)
  yq <- rlang::enquo(event)
  eq <- rlang::enquo(exposure)
  aq <- rlang::enquo(adjust)
  iq <- rlang::enquo(entry)
  one_name <- function(q, what) {
    n <- names(tidyselect::eval_select(q, .data, allow_rename = FALSE))
    if (length(n) != 1L) cli::cli_abort("Select exactly one column for {.arg {what}}.")
    n
  }
  tn <- one_name(tq, "time")
  yn <- one_name(yq, "event")
  en <- one_name(eq, "exposure")
  names_used <- c(tn, yn, en)
  if (!rlang::quo_is_null(iq)) names_used <- c(names_used, one_name(iq, "entry"))
  if (anyDuplicated(names_used)) cli::cli_abort("Time, event, exposure and entry must be distinct columns.")
  t <- .data[[tn]]
  event <- check_binary(.data[[yn]], "event")
  exp <- check_binary(.data[[en]], "exposure")
  check_nonnegative(t, "time")
  if (length(t) < 4 || sum(event) == 0 || length(unique(exp)) < 2) cli::cli_abort("At least four observations, one event and both exposure levels are required.")
  entry_time <- NULL
  if (length(names_used) == 4L) {
    entry_time <- .data[[names_used[4]]]
    check_nonnegative(entry_time, "entry")
    if (any(entry_time >= t)) cli::cli_abort("Every entry time must be strictly less than its exit time.")
  }
  selected <- names(tidyselect::eval_select(aq, .data, allow_rename = FALSE))
  if (any(selected %in% names_used)) cli::cli_abort("Adjustment columns must exclude time, event, entry and exposure.")
  for (nm in selected) {
    z <- .data[[nm]]
    if (anyNA(z) || !(is.numeric(z) || is.factor(z) || is.logical(z)) || (is.numeric(z) && any(!is.finite(z))) || length(unique(z)) < 2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor, or logical, and have at least two observed values.")
  }
  frame <- data.frame(.time = t, .event = event, .exposure = exp)
  if (!is.null(entry_time)) frame$.entry <- entry_time
  for (i in seq_along(selected)) frame[[paste0(".cov", i)]] <- .data[[selected[i]]]
  covs <- if (length(selected)) paste0(".cov", seq_along(selected)) else character()
  lhs <- if (is.null(entry_time)) "survival::Surv(.time, .event)" else "survival::Surv(.entry, .time, .event)"
  form <- stats::reformulate(c(".exposure", covs), response = lhs)
  fit <- withCallingHandlers(survival::coxph(form, data = frame, ties = ties), warning = function(w) {
    cli::cli_warn("Cox fitting warning: {conditionMessage(w)}")
    invokeRestart("muffleWarning")
  })
  co <- stats::coef(fit)
  if (anyNA(co) || any(!is.finite(co)) || !".exposure" %in% names(co)) cli::cli_abort("The Cox model is rank-deficient or the exposure coefficient is not estimable.")
  se <- sqrt(diag(stats::vcov(fit)))[".exposure"]
  beta <- co[".exposure"]
  z <- stats::qnorm((1 + conf_level) / 2)
  if (!is.finite(se)) cli::cli_abort("The exposure standard error is not estimable.")
  if (se > 10 || abs(beta) > 15) cli::cli_warn("Possible separation or sparse data; Wald inference may be unreliable.")
  new_epi_result(tibble::tibble(measure = "hazard_ratio", estimate = unname(exp(beta)), conf_low = unname(exp(beta - z * se)), conf_high = unname(exp(beta + z * se)), n = length(event), events = sum(event), adjusted_for = paste(selected, collapse = ", ")))
}
