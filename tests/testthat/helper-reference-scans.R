# Original pure-R scan implementations (before the C++ kernels), kept only to
# check that the compiled versions return identical results.
reference_spatial_scan <- function(.data, x, y, cases, population, radii, max_fraction = 0.5, nsim = 199L) {
  check_data(.data)
  a <- column(.data, rlang::enquo(x), "x")
  b <- column(.data, rlang::enquo(y), "y")
  count <- column(.data, rlang::enquo(cases), "cases")
  pop <- column(.data, rlang::enquo(population), "population")
  if (!is.numeric(a) || !is.numeric(b) || anyNA(a) || anyNA(b) || any(!is.finite(a)) || any(!is.finite(b))) cli::cli_abort("Coordinates must be finite numeric projected coordinates.")
  check_nonnegative(count, "cases")
  check_nonnegative(pop, "population", positive = TRUE)
  check_nonnegative(radii, "radii", positive = TRUE)
  check_probability(max_fraction, "max_fraction")
  if (length(count) < 2 || any(count != floor(count)) || sum(count) == 0) cli::cli_abort("At least two locations and a positive total of integer cases are required.")
  if (!is.finite(sum(pop)) || !is.finite(sum(count)) || sum(count) > .Machine$integer.max) cli::cli_abort("Total population must be finite and total cases must not exceed the integer limit.")
  if (!length(radii) || anyDuplicated(radii)) cli::cli_abort("{.arg radii} must be a non-empty vector of distinct radii.")
  if (length(nsim) != 1 || !is.numeric(nsim) || is.na(nsim) || !is.finite(nsim) || nsim < 0 || nsim != floor(nsim) || nsim > 100000) cli::cli_abort("{.arg nsim} must be an integer between 0 and 100000.")
  n <- length(count)
  if (n > 1000 || n * length(radii) > 20000) cli::cli_abort("At most 1000 locations and 20000 candidate circles are supported.")
  radii <- sort(radii)
  memberships <- list()
  centers <- integer()
  candidate_radii <- numeric()
  fractions <- numeric()
  total_pop <- sum(pop)
  for (i in seq_len(n)) {
    distance <- sqrt((a - a[i])^2 + (b - b[i])^2)
    for (r in radii) {
      inside <- distance <= r
      fraction <- sum(pop[inside]) / total_pop
      if (fraction > 0 && fraction <= max_fraction && fraction < 1) {
        memberships[[length(memberships) + 1L]] <- inside
        centers <- c(centers, i)
        candidate_radii <- c(candidate_radii, r)
        fractions <- c(fractions, fraction)
      }
    }
  }
  if (!length(memberships)) cli::cli_abort("No eligible circles. Adjust {.arg radii} or {.arg max_fraction}.")
  M <- do.call(cbind, memberships)
  total <- sum(count)
  expected <- total * fractions
  scan_scores <- function(z) {
    inside <- as.numeric(crossprod(M, z))
    outside <- total - inside
    scores <- numeric(length(inside))
    ok <- inside > expected
    scores[ok] <- inside[ok] * log(inside[ok] / expected[ok])
    valid <- ok & outside > 0
    scores[valid] <- scores[valid] + outside[valid] * log(outside[valid] / (total - expected[valid]))
    scores
  }
  scores <- scan_scores(count)
  best <- which.max(scores)
  obs <- as.numeric(crossprod(M[, best], count))
  outside <- total - obs
  inside_pop <- total_pop * fractions[best]
  rr <- if (outside == 0) Inf else (obs / inside_pop) / (outside / (total_pop - inside_pop))
  p <- NA_real_
  if (nsim > 0) {
    more <- 0
    for (j in seq_len(nsim)) {
      sim <- as.numeric(stats::rmultinom(1, size = total, prob = pop))
      if (max(scan_scores(sim)) >= scores[best] - 1e-12) more <- more + 1L
    }
    p <- (more + 1) / (nsim + 1)
  }
  tibble::tibble(center_x = a[centers[best]], center_y = b[centers[best]], radius = candidate_radii[best], observed = obs, expected = expected[best], population = inside_pop, relative_risk = rr, log_likelihood_ratio = scores[best], p_value = p, simulations = as.integer(nsim), candidates = ncol(M))
}
reference_spacetime_scan <- function(.data, x, y, cases, population, radii, windows = NULL, max_fraction = 0.5, nsim = 199L) {
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
