# nolint start: line_length_linter. Advice strings read better unbroken.
#' Statistical advice and interpretation for epidemiology
#'
#' `tep_advise()` advises on epidemiological data: which estimator answers the
#' question, what to check first, and the code to run. `tep_interpret()`
#' explains a result in plain sentences, says what to do after the overall
#' result (and what not to), and how to report it in a paper.
#'
#' With the tidyvisor package installed, `tidyvisor::tidyvisor()` hands
#' epidemiological data and results to these functions, so the same
#' statistical advisor covers epidemiology, community ecology (tidydiversity)
#' and spatial ecology (tidymapr). tidyepidemio does not need tidyvisor.
#'
#' Questions:
#' * `"outbreak"`: how fast are cases growing, and what is the reproduction
#'   number? (case counts over time)
#' * `"association"`: is an exposure associated with an outcome? (risk, odds
#'   and rate ratios, Mantel-Haenszel, adjusted ratios)
#' * `"survival"`: time to an event (Kaplan-Meier, Cox, restricted mean
#'   survival time)
#' * `"diagnostic"`: how well does a test find the condition?
#' * `"surveillance"`: are recent counts above what is expected?
#' * `"causal"`: the effect of an exposure, standardized for confounders
#'   (g-computation, inverse probability weighting)
#'
#' @param x A data frame (to be advised) or a tidyepidemio result (to be
#'   interpreted).
#' @param question What is asked (see above), or `"auto"` to guess it from
#'   the arguments given.
#' @param exposure,outcome,cases,time,event,test,truth,adjust Names (strings)
#'   of the columns in `x`.
#' @param ... Not used.
#' @return A `tep_advice` or a `tep_interpretation` object, printed as
#'   sentences, with the advice in its `sections`.
#' @examples
#' d <- data.frame(exposure = rep(0:1, each = 40), outcome = rep(c(0, 1, 0, 1), c(30, 10, 18, 22)))
#' tep_advise(d, question = "association", exposure = "exposure", outcome = "outcome")
#' tep_interpret(epi_risk_ratio(d, exposure, outcome))
#' @export
tep_advise <- function(x, question = c("auto", "outbreak", "association", "survival", "diagnostic", "surveillance", "causal"),
                       exposure = NULL, outcome = NULL, cases = NULL, time = NULL, event = NULL,
                       test = NULL, truth = NULL, adjust = NULL, ...) {
  question <- rlang::arg_match(question)
  if (!is.data.frame(x)) cli::cli_abort("{.arg x} must be a data frame.")
  if (question == "auto") {
    question <- if (!is.null(test) && !is.null(truth)) {
      "diagnostic"
    } else if (!is.null(time) && !is.null(event)) {
      "survival"
    } else if (!is.null(exposure) && !is.null(outcome)) {
      if (length(adjust)) "causal" else "association"
    } else if (!is.null(cases)) {
      "outbreak"
    } else {
      cli::cli_abort("Give {.arg question}: the columns given do not show what is asked.")
    }
  }
  n <- nrow(x)
  checks <- list(tep_check("Records", n))
  add <- function(check, value, meaning = "") checks[[length(checks) + 1]] <<- tep_check(check, value, meaning)
  col <- function(v) if (!is.null(v) && v %in% names(x)) x[[v]] else NULL
  if (!is.null(col(outcome))) {
    y <- col(outcome)
    ev <- sum(y == 1, na.rm = TRUE)
    add("Outcome events", sprintf("%d of %d (%.1f%%)", ev, n, 100 * ev / n),
        if (ev / n > 0.1) "common outcome (over 10%): odds ratios exaggerate risk ratios; report the risk ratio" else if (ev < 10) "fewer than 10 events: use exact methods and few covariates" else "")
  }
  if (!is.null(col(exposure))) add("Exposure groups", paste(names(table(col(exposure))), table(col(exposure)), sep = ": ", collapse = ", "))
  if (length(adjust)) add("Adjusted for", paste(adjust, collapse = ", "), "confounders, chosen before seeing the results (a causal diagram helps)")
  if (!is.null(col(cases))) {
    cs <- col(cases)
    add("Counts", sprintf("%d time points, %d cases in all", length(cs), sum(cs, na.rm = TRUE)),
        if (any(cs == 0, na.rm = TRUE)) "zeros: a log-linear fit needs counts above zero, or a Poisson/negative binomial model" else "")
  }
  q <- function(v) if (is.null(v)) "<column>" else v
  step <- function(s, rec, why, code = "") tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  adv <- switch(question,
    outbreak = rbind(
      step("Describe", "Epidemic curve", "Plot the counts by onset date before estimating anything; reporting delays make the last days too low.",
           sprintf("epi_epicurve(data, %s)", q(cases))),
      step("Estimate", "Growth rate and doubling time over the exponential phase", "Early in an outbreak cases grow exponentially; choose a window where the log counts rise in a straight line.",
           sprintf("epi_doubling_time(data, %s, %s)", q(time), q(cases))),
      step("Estimate", "Time-varying reproduction number Rt", "Rt needs the serial interval (or generation interval) of the pathogen, from the literature or your own pairs of cases.",
           sprintf("epi_rt(data, %s, weights = <serial interval distribution>)", q(cases))),
      step("Correct", "Nowcast the most recent counts", "Cases with recent onset are not yet reported; correct for the delay before reading the last days of the curve.",
           "epi_nowcast(...)")
    ),
    association = rbind(
      step("Estimate", "Risk ratio (cohort) or odds ratio (case-control)", "The design decides the measure: risks in cohorts and trials, odds in case-control studies; rates when follow-up time differs.",
           sprintf("epi_risk_ratio(data, %s, %s)   # or epi_odds_ratio(), epi_rate_ratio()", q(exposure), q(outcome))),
      step("Confounding", "Stratify or adjust", "A crude ratio mixes the exposure with whatever travels with it; compare it with the Mantel-Haenszel or adjusted ratio.",
           sprintf("epi_mantel_haenszel(data, %s, %s, <stratum>)", q(exposure), q(outcome))),
      step("Small numbers", "Exact test when cells are small", "With expected counts below 5, use an exact test and interval.",
           sprintf("epi_fisher_test(data, %s, %s)", q(exposure), q(outcome)))
    ),
    survival = rbind(
      step("Describe", "Kaplan-Meier curves", "Show survival over time by group, with the number at risk.",
           sprintf("epi_kaplan_meier(data, %s, %s, strata = %s)", q(time), q(event), q(exposure))),
      step("Estimate", "Hazard ratio (Cox model)", "Check proportional hazards (the curves should not cross); if they do, report the restricted mean survival time instead.",
           sprintf("epi_cox_hazard_ratio(data, %s, %s, %s)", q(time), q(event), q(exposure))),
      step("Alternative", "Restricted mean survival time", "An absolute measure that needs no proportional hazards.", "epi_rmst(...)")
    ),
    diagnostic = rbind(
      step("Estimate", "Sensitivity, specificity, predictive values and likelihood ratios", "Predictive values depend on prevalence: report the prevalence they apply to.",
           sprintf("epi_diagnostic(data, %s, %s)", q(test), q(truth))),
      step("Intervals", "Confidence intervals", "Every accuracy measure needs its interval (Wilson or exact).", sprintf("epi_diagnostic_ci(data, %s, %s)", q(test), q(truth))),
      step("Continuous tests", "ROC curve and AUC", "For a score, show the ROC curve and choose the threshold for the purpose.", "epi_roc_curve(...); epi_auc_ci(...)")
    ),
    surveillance = rbind(
      step("Detect", "Compare recent counts with a baseline", "Alerts compare each count with the expected count from a moving baseline; many weeks are tested, so p-values are adjusted.",
           sprintf("epi_surveillance(data, %s, window = 4, alpha = 0.05)", q(cases))),
      step("Seasonality", "Allow for seasons", "A seasonal baseline avoids alerts every winter.", "epi_seasonal_surveillance(...)"),
      step("Calibrate", "Check the false-alarm rate", "Tune the threshold on past data without outbreaks.", "epi_cusum_calibrate(...)")
    ),
    causal = rbind(
      step("Design", "Write down the causal diagram", "Adjust for confounders (common causes of exposure and outcome), not for mediators or colliders.", ""),
      step("Estimate", "Standardized effect by g-computation or inverse probability weighting", "Both estimate the average effect in the population; check the weights and the overlap of the groups.",
           sprintf("epi_gcomp(data, %s, %s, adjust = c(%s))   # or epi_ipw()", q(exposure), q(outcome), paste(if (is.null(adjust)) "<confounders>" else adjust, collapse = ", "))),
      step("Check", "Balance after weighting", "Standardized mean differences below 0.1 after weighting show the groups are comparable.", "epi_balance(...)")
    )
  )
  structure(list(question = question, checks = do.call(rbind, checks), advice = adv), class = "tep_advice")
}

tep_check <- function(check, value, meaning = "") tibble::tibble(check = check, value = as.character(value), meaning = meaning)

#' @export
print.tep_advice <- function(x, ...) {
  heading <- switch(x$question,
    outbreak = "how fast is the outbreak growing?", association = "is the exposure associated with the outcome?",
    survival = "how long until the event?", diagnostic = "how good is the test?",
    surveillance = "are counts above what is expected?", causal = "what is the effect of the exposure?",
    "which analysis?"
  )
  cli::cli_h1(paste("tidyvisor:", heading))
  cli::cli_text("Question: {.strong {x$question}}")
  cli::cli_h2("What the data show")
  for (i in seq_len(nrow(x$checks))) {
    r <- x$checks[i, ]
    note <- if (nzchar(r$meaning)) paste0(" \u2014 ", r$meaning) else ""
    cli::cli_bullets(c("*" = gsub("([{}])", "\\1\\1", paste0(r$check, ": ", r$value, note))))
  }
  cli::cli_h2("Recommended")
  for (i in seq_len(nrow(x$advice))) {
    r <- x$advice[i, ]
    cli::cli_text("{.strong {r$step}}: {r$recommendation}")
    if (nzchar(r$reason)) cli::cli_text("  {.emph {r$reason}}")
    if (nzchar(r$code)) cli::cli_code(strsplit(r$code, "\n")[[1]])
  }
  invisible(x)
}

#' @rdname tep_advise
#' @export
tep_interpret <- function(x, ...) UseMethod("tep_interpret")

#' @export
tep_interpret.default <- function(x, ...) {
  cli::cli_abort(c(
    "tidyepidemio cannot explain an object of class {.cls {class(x)}}.",
    i = "It explains ratios and other {.cls epi_result} objects, and the results of {.fn epi_rt}, {.fn epi_doubling_time}, {.fn epi_diagnostic}, {.fn epi_mantel_haenszel}, {.fn epi_surveillance}, {.fn epi_gcomp}, {.fn epi_ipw} and {.fn epi_kaplan_meier}."
  ))
}

tep_interp <- function(sections, after = NULL, paper = NULL, tables = list()) {
  sections$`After the overall test` <- after
  sections$`For the paper` <- paper
  structure(list(sections = sections, tables = tables), class = "tep_interpretation")
}

#' @export
print.tep_interpretation <- function(x, ...) {
  cli::cli_h1("tidyvisor: what the results show")
  for (s in names(x$sections)) {
    cli::cli_h2(s)
    for (line in x$sections[[s]]) cli::cli_bullets(c("*" = gsub("([{}])", "\\1\\1", line)))
  }
  invisible(x)
}
# nolint end
