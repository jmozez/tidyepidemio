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
  if (n > 500 || n * length(radii) > 10000 || n * n_times > 100000) cli::cli_abort("At most 500 locations, 10000 spatial circles, and 100000 location-time cells are supported.")
  radii <- sort(radii)
  windows <- sort(windows)
  memberships <- list()
  centers <- integer()
  rs <- numeric()
  frac <- numeric()
  for (i in seq_len(n)) {
    dist <- sqrt((a - a[i])^2 + (b - b[i])^2)
    for (r in radii) {
      inside <- dist <= r
      f <- sum(pop[inside]) / total_pop
      if (f > 0 && f <= max_fraction && f < 1) {
        memberships[[length(memberships) + 1L]] <- inside
        centers <- c(centers, i)
        rs <- c(rs, r)
        frac <- c(frac, f)
      }
    }
  }
  if (!length(memberships)) cli::cli_abort("No eligible circles; adjust {.arg radii} or {.arg max_fraction}.")
  M <- do.call(cbind, memberships)
  m <- ncol(M)
  if (m * length(windows) > 20000 || as.double(n) * m * length(windows) * max(1, nsim) > 100000000) cli::cli_abort("The candidate set or simulation workload is too large; reduce locations, radii, windows, or simulations.")
  expected <- as.vector(outer(frac, windows / n_times)) * total
  scan <- function(z) {
    observed <- unlist(lapply(windows, function(w) as.numeric(crossprod(M, rowSums(z[, seq.int(n_times - w + 1, n_times), drop = FALSE])))), use.names = FALSE)
    outside <- total - observed
    score <- numeric(length(observed))
    ok <- observed > expected
    score[ok] <- observed[ok] * log(observed[ok] / expected[ok])
    valid <- ok & outside > 0
    score[valid] <- score[valid] + outside[valid] * log(outside[valid] / (total - expected[valid]))
    list(observed = observed, score = score)
  }
  observed <- scan(counts)
  best <- which.max(observed$score)
  spatial_index <- (best - 1L) %% m + 1L
  window_index <- (best - 1L) %/% m + 1L
  obs <- observed$observed[best]
  outside <- total - obs
  inside_exposure <- total_pop * frac[spatial_index] * windows[window_index]
  outside_exposure <- total_pop * n_times - inside_exposure
  rr <- if (outside == 0) Inf else (obs / inside_exposure) / (outside / outside_exposure)
  p <- NA_real_
  if (nsim > 0) {
    more <- 0
    for (i in seq_len(nsim)) {
      draw <- matrix(as.numeric(stats::rmultinom(1, size = total, prob = rep(pop, n_times))), nrow = n)
      if (max(scan(draw)$score) >= observed$score[best] - 1e-12) more <- more + 1L
    }
    p <- (more + 1) / (nsim + 1)
  }
  best_score <- observed$score[best]
  candidate_count <- length(expected)
  best_expected <- expected[best]
  tibble::tibble(center_x = a[centers[spatial_index]], center_y = b[centers[spatial_index]], radius = rs[spatial_index], window = windows[window_index], observed = obs, expected = best_expected, relative_risk = rr, log_likelihood_ratio = best_score, p_value = p, simulations = as.integer(nsim), candidates = candidate_count)
}
