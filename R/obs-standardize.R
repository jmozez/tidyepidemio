#' Standardize rates across strata
#'
#' Direct standardization weights stratum-specific observed rates by the
#' standard populations. Indirect standardization returns an observed-to-expected
#' ratio using standard rates. Strata must be mutually exclusive and exhaustive;
#' no uncertainty intervals are calculated.
#' @param .data A data frame with one row per stratum.
#' @param events Observed event counts.
#' @param population Observed population or person-time.
#' @param standard Standard population for direct, or standard rate for indirect.
#' @param method Either `"direct"` or `"indirect"`.
#' @param multiplier Positive rate scale used for the output. For indirect
#'   standardization, standard rates must be supplied per one, not per multiplier.
#' @return A one-row tibble with the standardized estimate; for indirect
#'   standardization it also includes observed and expected events.
#' @examples
#' d <- data.frame(events = c(10, 20), pop = c(100, 100), standard = c(150, 50))
#' epi_standardize(d, events, pop, standard)
#' @export
epi_standardize <- function(.data, events, population, standard, method = c("direct", "indirect"), multiplier = 1) {
  check_data(.data); method <- match.arg(method); check_scalar(multiplier,"multiplier")
  a <- column(.data, rlang::enquo(events), "events"); n <- column(.data, rlang::enquo(population), "population"); s <- column(.data, rlang::enquo(standard), "standard")
  if (!length(a)) cli::cli_abort("At least one stratum is required.")
  check_nonnegative(a, "events"); check_nonnegative(n, "population", positive=TRUE); check_nonnegative(s, "standard")
  if (method == "direct") { if (sum(s) == 0) cli::cli_abort("The total standard population must be positive."); tibble::tibble(method = method, estimate = sum(a/n*s)/sum(s)*multiplier) }
  else { expected <- sum(n*s); if (expected == 0) cli::cli_abort("Expected events must be positive."); tibble::tibble(method=method, observed=sum(a), expected=expected, estimate=sum(a)/expected) }
}
#' Mantel-Haenszel pooled odds ratio
#'
#' Computes the Mantel-Haenszel common odds ratio from individual records. This
#' is a point estimate only, not a test of effect heterogeneity.
#' @param .data A data frame of individual records.
#' @param exposure Binary exposure indicator.
#' @param outcome Binary outcome indicator.
#' @param strata A non-missing stratum variable.
#' @return A one-row tibble with the pooled estimate and number of strata.
#' @examples
#' d <- data.frame(e = rep(c(0,0,1,1), 2), y = rep(c(0,1,0,1), 2), s = rep(1:2, each=4))
#' epi_mantel_haenszel(d, e, y, s)
#' @export
epi_mantel_haenszel <- function(.data, exposure, outcome, strata) {
  check_data(.data); e <- check_binary(column(.data, rlang::enquo(exposure), "exposure"), "exposure"); y <- check_binary(column(.data, rlang::enquo(outcome), "outcome"), "outcome"); s <- column(.data, rlang::enquo(strata), "strata")
  if (!length(s) || anyNA(s)) cli::cli_abort("{.arg strata} must contain at least one non-missing value and no missing values.")
  pieces <- lapply(split(seq_along(s), s, drop=TRUE), function(i) { a<-as.double(sum(e[i]==1 & y[i]==1)); b<-as.double(sum(e[i]==1 & y[i]==0)); c<-as.double(sum(e[i]==0 & y[i]==1)); d<-as.double(sum(e[i]==0 & y[i]==0)); c(a*d/length(i), b*c/length(i)) })
  num <- sum(vapply(pieces, `[`, numeric(1), 1)); den <- sum(vapply(pieces, `[`, numeric(1), 2));
  if (den == 0) cli::cli_warn("The Mantel-Haenszel odds ratio is undefined; returning {.val NA}.")
  tibble::tibble(estimate=ratio_safe(num, den), strata=length(pieces))
}
