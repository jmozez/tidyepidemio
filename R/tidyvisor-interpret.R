# Interpretations of tidyepidemio results: the numbers in sentences, what to
# do after the overall result, and how to report it ("For the paper").
# nolint start: line_length_linter. Advice strings read better unbroken.

tep_num <- function(x) trimws(formatC(signif(x, 3), digits = 3, format = "fg"))
tep_p <- function(p) if (is.na(p)) "p = NA" else if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
tep_rv <- function() paste(R.version$major, R.version$minor, sep = ".")
tep_methods <- function(what) sprintf("Methods: %s, and the software (R %s, tidyepidemio %s; citation(\"tidyepidemio\")).", what, tep_rv(), as.character(utils::packageVersion("tidyepidemio")))
tep_fig_rules <- "Figure style for journals: one column (about 85 mm) or the page (about 180 mm); axes labelled with units; a color-blind-safe palette; intervals shown, with what they are stated in the caption; text at least 8 pt; vector PDF."
tep_save <- 'ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm")   # one journal column'

tep_measure_name <- function(m) {
  m <- sub("^fisher_", "", m)
  m <- sub("^mantel_haenszel_", "Mantel-Haenszel ", m)
  gsub("_", " ", m)
}

#' @export
tep_interpret.epi_result <- function(x, ...) {
  rows <- seq_len(nrow(x))
  ratio <- grepl("ratio", x$measure)
  null <- ifelse(ratio, 1, 0)
  clear <- x$conf_low > null | x$conf_high < null
  lines <- vapply(rows, function(i) {
    m <- tep_measure_name(x$measure[i])
    s <- sprintf("The %s is %s (95%% CI %s to %s%s).", m, tep_num(x$estimate[i]), tep_num(x$conf_low[i]), tep_num(x$conf_high[i]),
                 if ("p_value" %in% names(x)) paste0(", ", tep_p(x$p_value[i])) else "")
    meaning <- if (!isTRUE(clear[i])) {
      sprintf("The interval includes %s: the data are consistent with no association.", null[i])
    } else if (ratio[i]) {
      what <- if (grepl("odds", x$measure[i])) "odds of the outcome" else if (grepl("hazard", x$measure[i])) "hazard of the event" else if (grepl("rate", x$measure[i])) "rate of the outcome" else "risk of the outcome"
      sprintf("The %s %s %s%% %s in the exposed than in the unexposed.", what, if (grepl("^odds", what)) "are" else "is", tep_num(abs(x$estimate[i] - 1) * 100), if (x$estimate[i] >= 1) "higher" else "lower")
    } else {
      sprintf("The difference is %s.", tep_num(x$estimate[i]))
    }
    paste(s, meaning)
  }, "")
  notes <- c(
    if (any(grepl("^odds_ratio|fisher_odds", x$measure)) && all(c("exposed_events", "exposed_total") %in% names(x)) &&
        (sum(x$exposed_events) + sum(x$unexposed_events)) / (sum(x$exposed_total) + sum(x$unexposed_total)) > 0.1) {
      "The outcome is common (over 10%): the odds ratio is further from 1 than the risk ratio, so report the risk ratio as well."
    },
    if ("adjusted_for" %in% names(x) && any(nzchar(x$adjusted_for))) sprintf("Adjusted for %s.", paste(unique(x$adjusted_for), collapse = ", ")) else "A crude estimate: confounding is not removed."
  )
  any_clear <- any(clear, na.rm = TRUE)
  m1 <- tep_measure_name(x$measure[1])
  after <- c(
    if (any_clear) "Check that the association is not explained by confounding: stratify (epi_mantel_haenszel()) or adjust (epi_adjusted_risk_ratio(), epi_adjusted_odds_ratio()) for the confounders named in advance, and report crude and adjusted estimates side by side." else "No clear association: do not go on to search subgroups or alternative cut-points until one is significant. Report the estimate with its interval and the size of effect the study could have detected.",
    "With several exposure levels, report each against the same reference group, and test for a trend if the levels are ordered, rather than testing every pair."
  )
  paper <- c(
    sprintf("Results: 'The %s for %s was %s (95%% CI %s to %s)%s.'", m1, "exposure", tep_num(x$estimate[1]), tep_num(x$conf_low[1]), tep_num(x$conf_high[1]),
            if ("p_value" %in% names(x)) paste0(", ", tep_p(x$p_value[1])) else ""),
    "Report the estimate with its 95% CI (and the counts behind it), not the p-value alone; give crude and adjusted estimates side by side.",
    "Figure: a forest plot of the estimates with their intervals on a log scale, with a line at 1:",
    "ggplot2::autoplot(result)", tep_save, tep_fig_rules,
    "Table: exposed and unexposed with events and totals (or person-time), the crude and adjusted estimates with intervals, and what was adjusted for.",
    tep_methods("the design (cohort, case-control, cross-sectional), the measure and why, the interval method, the confounders and how they were chosen; follow STROBE for observational studies")
  )
  tep_interp(list(Result = c(lines, notes)), after, paper, list(result = x))
}

#' @export
tep_interpret.tep_growth <- function(x, ...) {
  r <- x$growth_rate
  dt <- if ("doubling_time" %in% names(x)) x$doubling_time else if (r > 0) log(2) / r else NA
  s <- list(Growth = c(
    sprintf("Cases change by %s%% per time unit (growth rate r = %s, from %d time points).", tep_num(100 * (exp(r) - 1)), tep_num(r), x$n),
    if (r > 0) sprintf("They double every %s time units.", tep_num(dt)) else if (r < 0) sprintf("They halve every %s time units.", tep_num(log(2) / -r)) else "The counts are flat.",
    "The rate comes from a straight line through the log counts: it holds only over the exponential phase."
  ))
  after <- c(
    "Estimate the uncertainty before reporting: fit a Poisson or negative binomial model over the window (the interval of r, and so of the doubling time).",
    "To turn r into a reproduction number, use the serial interval: epi_rt(), or R = 1 / M(-r) for a known generation interval (Wallinga and Lipsitch 2007)."
  )
  paper <- c(
    sprintf("Results: 'Cases grew by %s%% per time unit (r = %s)%s, over the %d time points of the exponential phase.'", tep_num(100 * (exp(r) - 1)), tep_num(r), if (r > 0) sprintf(", doubling every %s time units", tep_num(dt)) else "", x$n),
    "Figure: the epidemic curve on a log scale with the fitted line over the window:", "ggplot2::autoplot(epi_epicurve(...))", tep_save, tep_fig_rules,
    "Table: the growth rate and doubling time with their intervals, and the window used.",
    tep_methods("the window of exponential growth and how it was chosen, the model, and the reporting delay")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_rt <- function(x, ...) {
  rt <- x$rt[is.finite(x$rt)]
  last <- utils::tail(rt, 1)
  s <- list(`Reproduction number` = c(
    sprintf("Rt ranges from %s to %s; the latest value is %s.", tep_num(min(rt)), tep_num(max(rt)), tep_num(last)),
    if (last > 1) "Rt above 1: each case is causing more than one new case, so the outbreak is growing." else "Rt below 1: the outbreak is shrinking.",
    "The latest values rest on the fewest cases and are the least certain; reporting delays push them down."
  ))
  after <- c(
    "Get intervals before acting on Rt: epi_rt_gamma() gives Rt with its credible interval under a gamma prior.",
    "Nowcast recent counts (epi_nowcast()) so that reporting delay is not read as a fall in Rt."
  )
  paper <- c(
    sprintf("Results: 'The time-varying reproduction number fell from %s to %s; the latest estimate was %s.'", tep_num(rt[1]), tep_num(last), tep_num(last)),
    "Report Rt with its interval, the serial interval (mean, SD and source), and the window of smoothing.",
    "Figure: Rt over time with its band and a line at 1, under the epidemic curve:", "ggplot2::autoplot(x, type = \"rt\")", tep_save, tep_fig_rules,
    tep_methods("the estimation method (Cori et al. 2013), the serial interval and its source, the smoothing window, and how reporting delay was handled")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_diagnostic <- function(x, ...) {
  s <- list(Accuracy = c(
    sprintf("Sensitivity %s%%: the test finds %s%% of those with the condition.", tep_num(100 * x$sensitivity), tep_num(100 * x$sensitivity)),
    sprintf("Specificity %s%%: it is negative in %s%% of those without.", tep_num(100 * x$specificity), tep_num(100 * x$specificity)),
    sprintf("Positive predictive value %s%% and negative predictive value %s%%, at the prevalence of this sample.", tep_num(100 * x$ppv), tep_num(100 * x$npv)),
    sprintf("Likelihood ratios: positive %s, negative %s.", tep_num(x$lr_positive), tep_num(x$lr_negative))
  ))
  after <- c(
    "Add intervals before reporting: epi_diagnostic_ci().",
    "Predictive values change with prevalence: recompute them for the setting where the test will be used (epi_predictive_values())."
  )
  paper <- c(
    sprintf("Results: 'Sensitivity was %s%% and specificity %s%% (n = %d; %d with the condition).'", tep_num(100 * x$sensitivity), tep_num(100 * x$specificity), x$tp + x$fp + x$fn + x$tn, x$tp + x$fn),
    "Report the 2 x 2 table and each measure with its 95% CI; follow STARD for diagnostic accuracy studies.",
    "Figure: for a continuous test, the ROC curve with the chosen threshold marked:", "epi_plot_roc(...)", tep_save, tep_fig_rules,
    tep_methods("the reference standard, how the threshold was chosen, and the interval method")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_mantel_haenszel <- function(x, ...) {
  het <- x$heterogeneity_p_value
  s <- list(`Stratified estimate` = c(
    sprintf("The Mantel-Haenszel odds ratio across %d strata is %s (95%% CI %s to %s).", x$strata, tep_num(x$estimate), tep_num(x$conf_low), tep_num(x$conf_high)),
    sprintf("Heterogeneity across strata: statistic %s on %s df, %s.", tep_num(x$heterogeneity_statistic), x$heterogeneity_df, tep_p(het))
  ))
  after <- if (!is.na(het) && het < 0.05) {
    "The strata differ (effect modification): report the stratum-specific estimates, not the pooled one."
  } else {
    "No clear heterogeneity: the pooled estimate summarizes the strata; compare it with the crude estimate to see how much confounding the stratification removed."
  }
  paper <- c(
    sprintf("Results: 'After stratifying by the confounder, the odds ratio was %s (95%% CI %s to %s; Mantel-Haenszel, %d strata; test of heterogeneity %s).'", tep_num(x$estimate), tep_num(x$conf_low), tep_num(x$conf_high), x$strata, tep_p(het)),
    "Table: the crude estimate, each stratum's estimate and the pooled Mantel-Haenszel estimate, with intervals.",
    tep_methods("the stratification variable and why, and the heterogeneity test")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_surveillance <- function(x, ...) {
  n_alert <- sum(x$alert, na.rm = TRUE)
  s <- list(Alerts = c(
    sprintf("%d of %d time points raise an alert (adjusted p-value at or below the threshold).", n_alert, nrow(x)),
    "An alert is a signal to investigate, not proof of an outbreak: check reporting changes and data errors first."
  ))
  after <- if (n_alert) "Investigate each alert: confirm cases, look at the line list for clusters in place or person, and compare with the same weeks of past years." else "No alerts: do not lower the threshold until something appears, which raises the false-alarm rate; calibrate it on past data instead (epi_cusum_calibrate())."
  paper <- c(
    sprintf("Results: '%d of %d time points exceeded the alert threshold.'", n_alert, nrow(x)),
    "Figure: the counts over time with the baseline and threshold, and the alerts marked.", tep_save, tep_fig_rules,
    tep_methods("the baseline window, the threshold and how it was calibrated, and the adjustment for multiple time points")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_causal <- function(x, ...) {
  ci <- function(i) if (is.na(x$conf_low[i])) "" else sprintf(" (95%% CI %s to %s)", tep_num(x$conf_low[i]), tep_num(x$conf_high[i]))
  lines <- vapply(seq_len(nrow(x)), function(i) sprintf("%s: %s%s.", gsub("_", " ", x$measure[i]), tep_num(x$estimate[i]), ci(i)), "")
  key <- which(grepl("difference|ratio", x$measure))
  key <- if (length(key)) key[1] else 1L
  s <- list(`Standardized effect` = c(lines,
    if (x$bootstrap[1] > 0) sprintf("Intervals from %d bootstrap samples (%d succeeded).", x$bootstrap[1], x$bootstrap_success[1]) else "No intervals were computed: rerun with bootstrap = 1000 before reporting.",
    "This is the effect if everyone were exposed versus if no one were, assuming no unmeasured confounding."))
  after <- c(
    "Check balance (epi_balance()) and the overlap of the groups; extreme weights mean some people have no comparable counterparts.",
    "Run a sensitivity analysis for unmeasured confounding (an E-value) before giving the estimate a causal reading."
  )
  paper <- c(
    sprintf("Results: 'Standardized for the confounders, the %s was %s%s.'", gsub("_", " ", x$measure[key]), tep_num(x$estimate[key]), ci(key)),
    "Show the causal diagram, the balance before and after standardization, and the crude and standardized estimates.",
    tep_methods("the causal diagram and the confounders it implies, the estimator (g-computation or IPW), the models used, and the bootstrap")
  )
  tep_interp(s, after, paper, list(result = x))
}

#' @export
tep_interpret.tep_survival <- function(x, ...) {
  strata <- unique(x$strata)
  s <- list(Survival = c(
    sprintf("Kaplan-Meier estimates for %d group%s, up to time %s.", length(strata), if (length(strata) > 1) "s" else "", tep_num(max(x$time))),
    vapply(strata, function(g) {
      d <- x[x$strata == g, ]
      sprintf("%s: survival %s at the last time (95%% CI %s to %s).", g, tep_num(utils::tail(d$estimate, 1)), tep_num(utils::tail(d$conf_low, 1)), tep_num(utils::tail(d$conf_high, 1)))
    }, "")
  ))
  after <- if (length(strata) > 1) c(
    "To compare the groups, estimate a hazard ratio (epi_cox_hazard_ratio()) and check that the curves do not cross; if they do, compare restricted mean survival times (epi_rmst()).",
    "With more than two groups, compare each with the same reference rather than testing every pair."
  ) else "For one group there is nothing to compare; report survival at fixed times with intervals."
  paper <- c(
    "Results: give survival at fixed times (for example 1 and 5 years) with 95% CIs, and the median survival if reached.",
    "Figure: the Kaplan-Meier curves with confidence bands and a table of the number at risk below:", "ggplot2::autoplot(km)", tep_save, tep_fig_rules,
    tep_methods("the time origin, the event, how censoring arose, and the interval method")
  )
  tep_interp(s, after, paper, list(result = x))
}
# nolint end
