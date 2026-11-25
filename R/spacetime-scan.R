#' Prospective circular space-time Poisson scan
#'
#' Searches circles centered on input locations and trailing windows ending at
#' the most recent time period. `cases` selects one integer-count column per
#' consecutive, equally sized time period, ordered oldest to newest. Each
#' circle-window is compared with all remaining location-time cells using the
#' conditional Poisson log likelihood ratio; only increases are considered.
#' Under the null, the total cases are distributed multinomially with each
#' location-time cell weighted by that location's fixed population. The global
#' Monte Carlo p-value compares the maximum observed score with the maxima across
#' the identical candidate set in each null simulation, using
#' `(1 + number >= observed) / (nsim + 1)`. `nsim=0` skips the test.
#'
#' Assumptions are a constant underlying risk over space and time, independent
#' Poisson counts, fixed populations, comparable periods, and a spatial point
#' representation of each location. The candidate set uses projected planar
#' coordinates, not latitude/longitude, and does not adjust for seasonality,
#' trends, covariates, changing populations, reporting delay or overdispersion.
#' It does not implement a flexible space-time scan or multiple-outbreak
#' correction across repeated runs. A flag is not evidence of causation. Set a
#' seed to reproduce Monte Carlo results. Simultaneous testing across repeated
#' surveillance dates requires additional calibration.
#' @param .data Data frame, one row per location, with case-count columns for
#'   each equally spaced time period.
#' @param x,y Numeric finite projected coordinate columns, in units of radii.
#' @param cases Tidy selection of case-count columns ordered oldest to newest.
#' @param population Positive population or exposure at each location, held
#'   constant across all time periods.
#' @param radii Positive distinct candidate circle radii.
#' @param windows Positive distinct integer trailing window lengths no larger
#'   than the number of selected case columns. Defaults to all possible lengths.
#' @param max_fraction Maximum fraction of total population within each circle,
#'   strictly between zero and one.
#' @param nsim Number of conditional null simulations; 0 skips the test.
#' @return One-row tibble describing the maximum-scoring circle and trailing
#'   window, inside observed and expected counts, relative risk, log likelihood
#'   ratio, and globally calibrated Monte Carlo p-value. If all scores are zero,
#'   the first candidate is arbitrary. Relative risk is infinite when all cases
#'   are inside the winning space-time window.
#' @references Kulldorff M (2001). Prospective time periodic geographical disease
#'   surveillance using a scan statistic. Journal of the Royal Statistical
#'   Society Series A 164:61-72. doi:10.1111/1467-985X.00186
#' @examples
#' d <- data.frame(
#'   x = c(0, 1, 10, 11), y = 0, pop = 100,
#'   day1 = c(1, 1, 1, 1), day2 = c(8, 7, 1, 1)
#' )
#' set.seed(1)
#' epi_spacetime_scan(d, x, y, c(day1, day2), pop, radii = c(.1, 1), nsim = 19)
#' @export
epi_spacetime_scan <- function(.data, x, y, cases, population, radii, windows = NULL, max_fraction = 0.5, nsim = 199L) {
  check_data(.data)
  a <- column(.data, rlang::enquo(x), "x")
  b <- column(.data, rlang::enquo(y), "y")
  pop <- column(.data, rlang::enquo(population), "population")
  case_names <- names(tidyselect::eval_select(rlang::enquo(cases), .data, allow_rename = FALSE))
  if (!length(case_names) || any(!vapply(.data[case_names], is.numeric, logical(1)))) cli::cli_abort("Select at least one numeric case-count column.")
  counts <- as.matrix(.data[case_names])
  check_nonnegative(as.numeric(counts), "cases")
  check_nonnegative(pop, "population", positive = TRUE)
  check_nonnegative(radii, "radii", positive = TRUE)
  check_probability(max_fraction, "max_fraction")
  if (!is.numeric(a) || !is.numeric(b) || anyNA(a) || anyNA(b) || any(!is.finite(a)) || any(!is.finite(b))) cli::cli_abort("Coordinates must be finite numeric projected coordinates.")
  n <- nrow(.data)
  n_times <- ncol(counts)
  total <- sum(counts)
  total_pop <- sum(pop)
  if (n < 2 || any(counts != floor(counts)) || total <= 0 || !is.finite(total) || total > .Machine$integer.max || !is.finite(total_pop)) cli::cli_abort("At least two locations and a positive total of integer cases within the integer limit are required; population must total finite.")
  if (!length(radii) || anyDuplicated(radii)) cli::cli_abort("{.arg radii} must be a non-empty vector of distinct radii.")
  if (is.null(windows)) windows <- seq_len(n_times)
  if (!is.numeric(windows) || !length(windows) || anyNA(windows) || any(!is.finite(windows)) || any(windows < 1 | windows > n_times | windows != floor(windows)) || anyDuplicated(windows)) cli::cli_abort("{.arg windows} must contain distinct integer lengths between 1 and the number of periods.")
  if (length(nsim) != 1L || !is.numeric(nsim) || is.na(nsim) || !is.finite(nsim) || nsim < 0 || nsim != floor(nsim) || nsim > 10000) cli::cli_abort("{.arg nsim} must be an integer between 0 and 10000.")
  if (n > 3000 || as.double(n) * length(radii) > 100000 || as.double(n) * n_times > 2000000) cli::cli_abort("At most 3000 locations, 100000 spatial circles, and 2 million location-time cells are supported.")
  windows <- as.integer(sort(windows))
  cand <- scan_candidates_cpp(as.double(a), as.double(b), as.double(pop), as.double(sort(radii)), max_fraction)
  m <- length(cand$center)
  if (!m) cli::cli_abort("No eligible circles; adjust {.arg radii} or {.arg max_fraction}.")
  if (as.double(length(cand$idx)) * length(windows) * max(1, nsim) > 5e10) cli::cli_abort("The candidate set or simulation workload is too large; reduce locations, radii, windows, or simulations.")
  expected <- as.vector(outer(cand$fraction, windows / n_times)) * total
  storage.mode(counts) <- "double"
  scan_res <- scan_scores_cpp(cand$ptr, cand$idx, expected, windows, counts, total)
  best <- which.max(scan_res$score)
  spatial_index <- (best - 1L) %% m + 1L
  window_index <- (best - 1L) %/% m + 1L
  obs <- scan_res$observed[best]
  outside <- total - obs
  inside_exposure <- total_pop * cand$fraction[spatial_index] * windows[window_index]
  outside_exposure <- total_pop * n_times - inside_exposure
  rr <- if (outside == 0) Inf else (obs / inside_exposure) / (outside / outside_exposure)
  p <- NA_real_
  if (nsim > 0) {
    maxima <- scan_simulate_max(cand, expected, windows, n, n_times, total, pop, nsim)
    p <- (sum(maxima >= scan_res$score[best] - 1e-12) + 1) / (nsim + 1)
  }
  n_candidates <- length(expected)
  tibble::tibble(center_x = a[cand$center[spatial_index]], center_y = b[cand$center[spatial_index]], radius = cand$radius[spatial_index], window = windows[window_index], observed = obs, expected = expected[best], relative_risk = rr, log_likelihood_ratio = scan_res$score[best], p_value = p, simulations = as.integer(nsim), candidates = n_candidates)
}
