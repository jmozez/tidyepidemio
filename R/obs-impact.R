#' Attributable fractions from individual-level risks
#'
#' Calculates the exposed attributable fraction `(risk_exposed -
#' risk_unexposed) / risk_exposed` and the population attributable fraction
#' `(risk_population - risk_unexposed) / risk_population`. Risk is the observed
#' binary outcome proportion in each group. The fractions may be negative when
#' exposure is protective. A zero denominator produces a missing fraction.
#'
#' These are unadjusted descriptive contrasts. Interpreting them as the fraction
#' of outcomes prevented by removing exposure requires consistency, exchangeability,
#' positivity, comparable follow-up and an appropriate intervention. These
#' assumptions are not checked; confounding and selection bias can be important.
#' This function does not estimate adjusted effects or confidence intervals.
#' @param .data An ungrouped data frame of individual records.
#' @param exposure Binary 0/1 exposure indicator.
#' @param outcome Binary 0/1 outcome indicator over comparable follow-up.
#' @return One-row tibble containing group and population risks, exposed and
#'   population attributable fractions, and sample size.
#' @examples
#' d <- data.frame(e = rep(0:1, each = 4), y = c(0, 0, 0, 1, 0, 1, 1, 1))
#' epi_attributable_fraction(d, e, y)
#' @export
epi_attributable_fraction <- function(.data, exposure, outcome) {
  check_data(.data)
  e <- check_binary(column(.data, rlang::enquo(exposure), "exposure"), "exposure")
  y <- check_binary(column(.data, rlang::enquo(outcome), "outcome"), "outcome")
  if (!length(e) || length(unique(e)) < 2) cli::cli_abort("Both exposure groups must contain observations.")
  p0 <- mean(y[e == 0])
  p1 <- mean(y[e == 1])
  p <- mean(y)
  af <- if (p1 == 0) NA_real_ else (p1 - p0) / p1
  paf <- if (p == 0) NA_real_ else (p - p0) / p
  if (is.na(af) || is.na(paf)) cli::cli_warn("At least one risk denominator is zero; the corresponding fraction is undefined.")
  tibble::tibble(risk_unexposed = p0, risk_exposed = p1, risk_population = p, attributable_fraction_exposed = af, population_attributable_fraction = paf, n = length(y))
}
#' Number needed to treat or harm
#'
#' Compares a binary adverse outcome in treated and untreated groups over the
#' same follow-up. A lower treated risk gives number needed to treat (NNT); a
#' higher treated risk gives number needed to harm (NNH). The absolute risk
#' reduction is `risk_untreated - risk_treated`; the reported number is its
#' reciprocal magnitude, rounded up to a whole person. Identical risks return
#' `NA` rather than infinity and `type = "no_difference"`.
#'
#' This is an unadjusted descriptive contrast, not a randomized treatment effect
#' unless justified by study design and assumptions. NNT/NNH depends on outcome
#' definition, baseline risk and follow-up duration. This function does not
#' calculate confidence intervals; inversion of intervals crossing zero requires
#' careful interpretation and is not a single conventional finite interval.
#' @param .data An ungrouped data frame of individual records.
#' @param treatment Binary treatment indicator; 1 denotes treated.
#' @param outcome Binary adverse outcome indicator; 1 denotes an adverse event.
#' @return A one-row tibble with risks, absolute risk reduction, `type`, and
#'   the rounded-up `number_needed`.
#' @examples
#' d <- data.frame(treated = rep(0:1, each = 4), adverse = c(1, 1, 0, 0, 1, 0, 0, 0))
#' epi_number_needed(d, treated, adverse)
#' @export
epi_number_needed <- function(.data, treatment, outcome) {
  check_data(.data)
  t <- check_binary(column(.data, rlang::enquo(treatment), "treatment"), "treatment")
  y <- check_binary(column(.data, rlang::enquo(outcome), "outcome"), "outcome")
  if (!length(t) || length(unique(t)) < 2) cli::cli_abort("Both treatment groups must contain observations.")
  n0 <- as.double(sum(t == 0))
  n1 <- as.double(sum(t == 1))
  a0 <- sum(y[t == 0])
  a1 <- sum(y[t == 1])
  numerator <- a0 * n1 - a1 * n0
  reduction <- numerator / (n0 * n1)
  type <- if (numerator > 0) "NNT" else if (numerator < 0) "NNH" else "no_difference"
  needed <- if (numerator == 0) NA_real_ else ceiling((n0 * n1) / abs(numerator))
  tibble::tibble(risk_untreated = a0 / n0, risk_treated = a1 / n1, absolute_risk_reduction = reduction, type = type, number_needed = needed, n_untreated = n0, n_treated = n1)
}
