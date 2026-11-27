# Epidemiological delays, superspreading and case fatality ----------------

delay_families <- c("lognormal", "gamma", "weibull")

# Natural parameters from the unconstrained vector used by optim().
delay_par <- function(theta, family) {
  switch(family,
    lognormal = c(meanlog = theta[[1]], sdlog = exp(theta[[2]])),
    gamma = c(shape = exp(theta[[1]]), scale = exp(theta[[2]])),
    weibull = c(shape = exp(theta[[1]]), scale = exp(theta[[2]]))
  )
}

delay_cdf <- function(x, p, family) {
  switch(family,
    lognormal = stats::plnorm(x, p[["meanlog"]], p[["sdlog"]]),
    gamma = stats::pgamma(x, shape = p[["shape"]], scale = p[["scale"]]),
    weibull = stats::pweibull(x, p[["shape"]], p[["scale"]])
  )
}

delay_logpdf <- function(x, p, family) {
  switch(family,
    lognormal = stats::dlnorm(x, p[["meanlog"]], p[["sdlog"]], log = TRUE),
    gamma = stats::dgamma(x, shape = p[["shape"]], scale = p[["scale"]], log = TRUE),
    weibull = stats::dweibull(x, p[["shape"]], p[["scale"]], log = TRUE)
  )
}

delay_quantile <- function(prob, p, family) {
  switch(family,
    lognormal = stats::qlnorm(prob, p[["meanlog"]], p[["sdlog"]]),
    gamma = stats::qgamma(prob, shape = p[["shape"]], scale = p[["scale"]]),
    weibull = stats::qweibull(prob, p[["shape"]], p[["scale"]])
  )
}

delay_moments <- function(p, family) {
  switch(family,
    lognormal = {
      m <- exp(p[["meanlog"]] + p[["sdlog"]]^2 / 2)
      c(mean = m, sd = m * sqrt(exp(p[["sdlog"]]^2) - 1))
    },
    gamma = c(
      mean = p[["shape"]] * p[["scale"]],
      sd = sqrt(p[["shape"]]) * p[["scale"]]
    ),
    weibull = {
      m <- p[["scale"]] * gamma(1 + 1 / p[["shape"]])
      v <- p[["scale"]]^2 * gamma(1 + 2 / p[["shape"]]) - m^2
      c(mean = m, sd = sqrt(max(v, 0)))
    }
  )
}

# Integral of the CDF from 0 to x, G(x) = x F(x) - E[X; X <= x], in closed
# form for each family. The probability of an observed daily delay d when
# both events are known only to the day (primary event uniform within its
# day) is G(d + 1) - 2 G(d) + G(d - 1).
delay_cdf_integral <- function(x, p, family) {
  out <- numeric(length(x))
  pos <- x > 0
  if (!any(pos)) return(out)
  z <- x[pos]
  partial <- switch(family,
    lognormal = exp(p[["meanlog"]] + p[["sdlog"]]^2 / 2) *
      stats::pnorm((log(z) - p[["meanlog"]] - p[["sdlog"]]^2) / p[["sdlog"]]),
    gamma = p[["shape"]] * p[["scale"]] *
      stats::pgamma(z, shape = p[["shape"]] + 1, scale = p[["scale"]]),
    weibull = p[["scale"]] * gamma(1 + 1 / p[["shape"]]) *
      stats::pgamma((z / p[["scale"]])^p[["shape"]], shape = 1 + 1 / p[["shape"]])
  )
  out[pos] <- z * delay_cdf(z, p, family) - partial
  out
}

delay_pmf_double <- function(d, p, family) {
  g <- function(x) delay_cdf_integral(x, p, family)
  pmax(g(d + 1) - 2 * g(d) + g(d - 1), 0)
}

delay_loglik <- function(theta, x, upper, family, censoring) {
  p <- delay_par(theta, family)
  if (censoring == "double") {
    ll <- log(delay_pmf_double(x, p, family))
    if (!is.null(upper)) {
      g <- function(z) delay_cdf_integral(z, p, family)
      ll <- ll - log(g(upper + 1) - g(upper))
    }
  } else {
    ll <- suppressWarnings(delay_logpdf(x, p, family))
    if (!is.null(upper)) ll <- ll - log(delay_cdf(upper, p, family))
  }
  s <- sum(ll)
  if (!is.finite(s)) -1e100 else s
}

delay_start <- function(x, family) {
  x <- pmax(x, 0.5)
  m <- mean(x)
  v <- max(stats::var(x), 0.25)
  switch(family,
    lognormal = c(mean(log(x)), log(max(stats::sd(log(x)), 0.1))),
    gamma = c(log(m^2 / v), log(v / m)),
    weibull = c(log(1.2), log(m))
  )
}

#' Estimate an epidemiological delay distribution
#'
#' @description
#' Fits lognormal, gamma and Weibull distributions to delays between two
#' events, such as symptom onset to reporting, onset to death or the serial
#' interval, by maximum likelihood. With daily data both events are known
#' only to the day, so the observed delay is doubly interval censored; with
#' an ongoing outbreak, long delays are not yet observed, so the data are
#' right truncated. Ignoring either biases the estimated mean, usually
#' downwards (Park et al. 2024). This function accounts for both, using the
#' exact (closed-form) probability of each whole-day delay when the primary
#' event is uniformly distributed within its day (Charniga et al. 2024).
#'
#' @param .data A data frame with one row per individual.
#' @param delay Observed delays. With `censoring = "double"`, whole numbers
#'   of days (0 or more); with `censoring = "none"`, exact positive delays.
#' @param max_delay Optional column with the longest delay that could have
#'   been observed for each individual (days from the primary event to the
#'   end of data collection). Supplying it corrects for right truncation.
#' @param family One or more of `"lognormal"`, `"gamma"` and `"weibull"`.
#' @param censoring `"double"` (default) for whole-day data, `"none"` for
#'   exact delays.
#' @param conf_level Confidence level for the mean (delta method on the log
#'   scale).
#' @return A `tep_delay` tibble with one row per family, best first by AIC:
#'   `family`, `parameters` (a list column of named estimates), `mean`,
#'   `mean_lower`, `mean_upper`, `sd`, `median`, `q95` (95th percentile),
#'   `loglik`, `aic`, `delta_aic`, `n`, `censoring` and `truncated`. Pass it
#'   to [epi_delay_pmf()] for discretised probabilities to use with
#'   [epi_cfr()], [epi_nowcast()] or [epi_rt()].
#' @references Park, S. W., Akhmetzhanov, A. R., Charniga, K., Cori, A.,
#'   Davies, N. G., Dushoff, J., Funk, S., Gostic, K., Grenfell, B.,
#'   Linton, N. M., Lipsitch, M., Lison, A., Overton, C. E., Ward, T. and
#'   Abbott, S. (2024). Estimating epidemiological delay distributions for
#'   infectious diseases. medRxiv. \doi{10.1101/2024.01.12.24301247}
#'
#'   Charniga, K., Park, S. W., Akhmetzhanov, A. R., Cori, A., Dushoff,
#'   J., Funk, S., Gostic, K. M., Linton, N. M., Lison, A., Overton, C. E.,
#'   Pulliam, J. R. C., Ward, T., Cauchemez, S. and Abbott, S. (2024). Best
#'   practices for estimating and reporting epidemiological delay
#'   distributions of infectious diseases. PLOS Computational Biology, 20,
#'   e1012520. \doi{10.1371/journal.pcbi.1012520}
#' @examples
#' set.seed(1)
#' onset <- runif(300, 0, 40)
#' report <- onset + rlnorm(300, 1.5, 0.5)
#' d <- data.frame(delay = floor(report) - floor(onset))
#' epi_delay_dist(d, delay)
#'
#' # Only reports up to day 40 are known: correct for right truncation
#' d$max_delay <- 40 - floor(onset)
#' seen <- d[d$delay <= d$max_delay, ]
#' epi_delay_dist(seen, delay, max_delay = max_delay, family = "lognormal")
#' @export
epi_delay_dist <- function(.data, delay, max_delay = NULL,
                           family = c("lognormal", "gamma", "weibull"),
                           censoring = c("double", "none"),
                           conf_level = 0.95) {
  tep_tag("delay", {
  check_data(.data)
  censoring <- rlang::arg_match(censoring)
  if (!is.character(family) || !length(family) || !all(family %in% delay_families)) {
    cli::cli_abort("{.arg family} must contain {.or {.val {delay_families}}}.")
  }
  family <- unique(family)
  check_scalar(conf_level, "conf_level")
  if (conf_level >= 1) cli::cli_abort("{.arg conf_level} must be below 1.")
  x <- column(.data, rlang::enquo(delay), "delay")
  check_nonnegative(x, "delay", positive = censoring == "none")
  if (censoring == "double" && any(abs(x - round(x)) > 1e-8)) {
    cli::cli_abort(c(
      "{.arg delay} must contain whole days when {.code censoring = \"double\"}.",
      "i" = "Use {.code censoring = \"none\"} for exact delays."
    ))
  }
  if (length(x) < 2) cli::cli_abort("{.arg delay} needs at least two values.")
  q <- rlang::enquo(max_delay)
  upper <- NULL
  if (!rlang::quo_is_null(q)) {
    upper <- column(.data, q, "max_delay")
    check_nonnegative(upper, "max_delay")
    if (any(x > upper + 1e-8)) {
      cli::cli_abort("Each {.arg delay} must be no longer than its {.arg max_delay}.")
    }
  }
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  fits <- lapply(family, function(fam) {
    fn <- function(th) -delay_loglik(th, x, upper, fam, censoring)
    opt <- stats::optim(delay_start(x, fam), fn, method = "BFGS", hessian = TRUE,
      control = list(maxit = 500, reltol = 1e-12))
    p <- delay_par(opt$par, fam)
    mom <- delay_moments(p, fam)
    vc <- tryCatch(solve(opt$hessian), error = function(e) NULL)
    se <- NA_real_
    if (!is.null(vc)) {
      lm <- function(th) log(delay_moments(delay_par(th, fam), fam)[["mean"]])
      gr <- vapply(seq_along(opt$par), function(i) {
        h <- 1e-5 * max(1, abs(opt$par[i]))
        e <- replace(numeric(length(opt$par)), i, h)
        (lm(opt$par + e) - lm(opt$par - e)) / (2 * h)
      }, 1)
      se <- sqrt(max(drop(t(gr) %*% vc %*% gr), 0))
    }
    tibble::tibble(
      family = fam, parameters = list(p), mean = mom[["mean"]],
      mean_lower = mom[["mean"]] * exp(-z * se),
      mean_upper = mom[["mean"]] * exp(z * se), sd = mom[["sd"]],
      median = delay_quantile(0.5, p, fam), q95 = delay_quantile(0.95, p, fam),
      loglik = -opt$value, aic = 2 * opt$value + 4
    )
  })
  out <- dplyr::bind_rows(fits)
  out <- out[order(out$aic), , drop = FALSE]
  out$delta_aic <- out$aic - min(out$aic)
  out$n <- length(x)
  out$censoring <- censoring
  out$truncated <- !is.null(upper)
  out
  })
}

#' Discretised probabilities of a fitted delay
#'
#' Converts a delay distribution from [epi_delay_dist()] into the
#' probability of each whole-day delay, using the same double interval
#' censoring as the fit, so it can be used as a reporting delay
#' ([epi_cfr()], [epi_nowcast()]) or as generation-interval weights
#' ([epi_rt()], after dropping day 0 and renormalising).
#'
#' @param fit A `tep_delay` tibble from [epi_delay_dist()].
#' @param max_delay Longest delay to include, in days.
#' @param family Family to use; defaults to the best by AIC (first row).
#' @return A tibble with `delay` (0 to `max_delay`) and `probability`,
#'   renormalised to sum to one.
#' @examples
#' set.seed(2)
#' d <- data.frame(delay = round(rgamma(200, 4, 1)))
#' fit <- epi_delay_dist(d, delay, family = "gamma")
#' epi_delay_pmf(fit, max_delay = 15)
#' @export
epi_delay_pmf <- function(fit, max_delay, family = NULL) {
  if (!inherits(fit, "tep_delay")) {
    cli::cli_abort("{.arg fit} must come from {.fn epi_delay_dist}.")
  }
  check_scalar(max_delay, "max_delay", min = 0, inclusive = TRUE)
  row <- if (is.null(family)) 1L else match(family, fit$family)
  if (length(row) != 1 || is.na(row)) {
    cli::cli_abort("{.arg family} must be one of {.val {fit$family}}.")
  }
  fam <- fit$family[[row]]
  p <- fit$parameters[[row]]
  d <- 0:floor(max_delay)
  pr <- delay_pmf_double(d, p, fam)
  tibble::tibble(delay = d, probability = pr / sum(pr))
}

#' Reproduction number and dispersion of secondary cases (superspreading)
#'
#' @description
#' `epi_offspring()` fits a negative binomial offspring distribution to the
#' number of secondary cases caused by each case (from contact tracing),
#' estimating the reproduction number `R` and the dispersion `k`. Small `k`
#' (below about 1) means transmission is concentrated in a few
#' superspreaders (Lloyd-Smith et al. 2005). `prop_80` is the proportion of
#' cases expected to cause 80% of transmission (Endo et al. 2020).
#'
#' `epi_chain_size()` estimates the same two quantities from the final
#' sizes of transmission chains (clusters), each started by one introduced
#' case, using the chain-size distribution of Blumberg and Lloyd-Smith
#' (2013). This needs `R` below 1 (chains that died out).
#'
#' @param .data A data frame with one row per case (`epi_offspring()`) or
#'   per transmission chain (`epi_chain_size()`).
#' @param secondary Number of secondary cases caused by each case.
#' @param size Total number of cases in each chain, including the index
#'   case (1 or more).
#' @param conf_level Confidence level (Wald intervals on the log scale).
#' @return A one-row tibble with `n`, `r`, `r_lower`, `r_upper`, `k`,
#'   `k_lower`, `k_upper`, `prop_80`, `p_zero` (expected proportion of
#'   cases with no secondary cases), `loglik` and, for `epi_offspring()`,
#'   `aic_poisson` and `aic_negbin` (a smaller negative binomial AIC is
#'   evidence of overdispersion).
#' @references Lloyd-Smith, J. O., Schreiber, S. J., Kopp, P. E. and Getz,
#'   W. M. (2005). Superspreading and the effect of individual variation on
#'   disease emergence. Nature, 438, 355-359. \doi{10.1038/nature04153}
#'
#'   Blumberg, S. and Lloyd-Smith, J. O. (2013). Inference of R0 and
#'   transmission heterogeneity from the size distribution of stuttering
#'   chains. PLOS Computational Biology, 9, e1002993.
#'   \doi{10.1371/journal.pcbi.1002993}
#'
#'   Endo, A., Abbott, S., Kucharski, A. J. and Funk, S. (2020). Estimating
#'   the overdispersion in COVID-19 transmission using outbreak sizes
#'   outside China. Wellcome Open Research, 5, 67.
#'   \doi{10.12688/wellcomeopenres.15842.3}
#' @examples
#' set.seed(3)
#' d <- data.frame(secondary = rnbinom(150, size = 0.3, mu = 1.2))
#' epi_offspring(d, secondary)
#'
#' chains <- data.frame(size = c(rep(1, 40), rep(2, 9), rep(3, 4), 5, 8, 21))
#' epi_chain_size(chains, size)
#' @export
epi_offspring <- function(.data, secondary, conf_level = 0.95) {
  tep_tag("offspring", {
  check_data(.data)
  x <- column(.data, rlang::enquo(secondary), "secondary")
  check_count(x, "secondary", 0)
  if (length(x) < 2 || sum(x) == 0) {
    cli::cli_abort("{.arg secondary} needs at least two cases and one transmission.")
  }
  nll <- function(th) {
    -sum(stats::dnbinom(x, size = exp(th[2]), mu = exp(th[1]), log = TRUE))
  }
  v <- stats::var(x)
  m <- mean(x)
  k0 <- if (v > m) m^2 / (v - m) else 10
  opt <- stats::optim(c(log(m), log(k0)), nll, method = "BFGS", hessian = TRUE,
    control = list(reltol = 1e-12, maxit = 500))
  ll_pois <- sum(stats::dpois(x, m, log = TRUE))
  out <- offspring_summary(opt, length(x), conf_level)
  out$aic_poisson <- -2 * ll_pois + 2
  out$aic_negbin <- 2 * opt$value + 4
  out
  })
}

#' @rdname epi_offspring
#' @export
epi_chain_size <- function(.data, size, conf_level = 0.95) {
  tep_tag("offspring", {
  check_data(.data)
  y <- column(.data, rlang::enquo(size), "size")
  check_count(y, "size", 1)
  if (length(y) < 2 || all(y == 1)) {
    cli::cli_abort("{.arg size} needs at least two chains and one transmission.")
  }
  nll <- function(th) {
    r <- exp(th[1])
    k <- exp(th[2])
    if (r >= 1) return(1e100)
    lp <- lgamma(k * y + y - 1) - lgamma(k * y) - lgamma(y + 1) +
      (y - 1) * log(r / k) - (k * y + y - 1) * log1p(r / k)
    -sum(lp)
  }
  r0 <- min(1 - 1 / mean(y), 0.95)
  starts <- expand.grid(r = log(c(r0, 0.3, 0.7)), k = log(c(0.1, 0.5, 2)))
  best <- NULL
  for (i in seq_len(nrow(starts))) {
    o <- tryCatch(
      stats::optim(unlist(starts[i, ]), nll, method = "Nelder-Mead",
        control = list(reltol = 1e-12, maxit = 2000)),
      error = function(e) NULL
    )
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o
  }
  best$hessian <- stats::optimHess(best$par, nll)
  offspring_summary(best, length(y), conf_level)
  })
}

check_count <- function(x, name, min) {
  if (!is.numeric(x) || anyNA(x) || any(!is.finite(x)) || any(x < min) ||
    any(abs(x - round(x)) > 1e-8)) {
    cli::cli_abort("{.arg {name}} must contain whole numbers of {min} or more.")
  }
  invisible(x)
}

offspring_summary <- function(opt, n, conf_level) {
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  se <- tryCatch(sqrt(pmax(diag(solve(opt$hessian)), 0)),
    error = function(e) c(NA_real_, NA_real_))
  r <- exp(opt$par[[1]])
  k <- exp(opt$par[[2]])
  tibble::tibble(
    n = n,
    r = r, r_lower = r * exp(-z * se[[1]]), r_upper = r * exp(z * se[[1]]),
    k = k, k_lower = k * exp(-z * se[[2]]), k_upper = k * exp(z * se[[2]]),
    prop_80 = offspring_prop(r, k, 0.8),
    p_zero = (1 + r / k)^(-k),
    loglik = -opt$value
  )
}

# Proportion of cases (those with the highest individual reproduction
# numbers, gamma distributed with mean r and shape k) that cause the share
# `share` of transmission.
offspring_prop <- function(r, k, share) {
  x <- stats::qgamma(1 - share, shape = k + 1, scale = r / k)
  1 - stats::pgamma(x, shape = k, scale = r / k)
}

#' Naive and delay-adjusted case fatality ratio
#'
#' @description
#' During an outbreak, dividing deaths by cases underestimates the case
#' fatality ratio (CFR), because many recent cases have not yet had time
#' to die. The delay-adjusted estimator of Nishiura et al. (2009) divides
#' deaths by the expected number of cases with a known outcome, given the
#' distribution of the delay from onset (or report) to death, as in the
#' cfr package. Intervals are likelihood-ratio intervals from a binomial
#' likelihood in which the cases with known outcomes are the trials.
#'
#' @param .data A data frame in date order with equally spaced rows (days).
#' @param cases Daily cases.
#' @param deaths Daily deaths.
#' @param delay Probabilities of the delay from case to death, starting at
#'   a delay of 0 days, such as the `probability` column of
#'   [epi_delay_pmf()]. `NULL` gives only the naive estimate.
#' @param conf_level Confidence level.
#' @param cumulative If `TRUE`, returns the estimate using the data up to
#'   each row (to watch the estimate settle), added to `.data`.
#' @return A tibble with `method` (`"naive"` and `"delay_adjusted"`),
#'   `deaths`, `cases`, `known_outcomes`, `cfr`, `lower` and `upper`; with
#'   `cumulative = TRUE`, `.data` with `cfr_naive`, `cfr_adjusted`,
#'   `cfr_lower` and `cfr_upper` (for the adjusted estimate).
#' @references Nishiura, H., Klinkenberg, D., Roberts, M. and Heesterbeek,
#'   J. A. P. (2009). Early epidemiological assessment of the virulence of
#'   emerging infectious diseases: a case study of an influenza pandemic.
#'   PLOS ONE, 4, e6852. \doi{10.1371/journal.pone.0006852}
#'
#'   Linton, N. M., Kobayashi, T., Yang, Y., Hayashi, K., Akhmetzhanov,
#'   A. R., Jung, S., Yuan, B., Kinoshita, R. and Nishiura, H. (2020).
#'   Incubation period and other epidemiological characteristics of 2019
#'   novel coronavirus infections with right truncation. Journal of
#'   Clinical Medicine, 9, 538. \doi{10.3390/jcm9020538}
#' @examples
#' # Onset-to-death delay for COVID-19: lognormal, mean 20.2 days, SD 11.6
#' # (Linton et al. 2020)
#' sdlog <- sqrt(log(1 + (11.6 / 20.2)^2))
#' meanlog <- log(20.2) - sdlog^2 / 2
#' pmf <- diff(plnorm(0:61, meanlog, sdlog))
#' epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = pmf / sum(pmf))
#'
#' early <- nz_covid_outcomes_2020[1:50, ]
#' epi_cfr(early, cases, deaths, delay = pmf / sum(pmf))
#' @export
epi_cfr <- function(.data, cases, deaths, delay = NULL, conf_level = 0.95,
                    cumulative = FALSE) {
  tep_tag("cfr", {
  check_data(.data)
  cs <- column(.data, rlang::enquo(cases), "cases")
  ds <- column(.data, rlang::enquo(deaths), "deaths")
  check_nonnegative(cs, "cases")
  check_nonnegative(ds, "deaths")
  check_scalar(conf_level, "conf_level")
  if (conf_level >= 1) cli::cli_abort("{.arg conf_level} must be below 1.")
  if (!is.null(delay)) {
    check_nonnegative(delay, "delay")
    if (!length(delay) || abs(sum(delay) - 1) > 1e-6) {
      cli::cli_abort("{.arg delay} must be a probability distribution summing to one.")
    }
  }
  known <- if (is.null(delay)) cumsum(cs) else cumsum(cfr_known(cs, delay))
  if (cumulative) {
    est <- lapply(seq_along(cs), function(i) {
      cfr_interval(sum(ds[seq_len(i)]), known[i], conf_level)
    })
    .data$cfr_naive <- ifelse(cumsum(cs) > 0, cumsum(ds) / cumsum(cs), NA_real_)
    .data$cfr_adjusted <- vapply(est, `[[`, 1, "cfr")
    .data$cfr_lower <- vapply(est, `[[`, 1, "lower")
    .data$cfr_upper <- vapply(est, `[[`, 1, "upper")
    return(tibble::as_tibble(.data))
  }
  out <- tibble::tibble(
    method = "naive", deaths = sum(ds), cases = sum(cs), known_outcomes = sum(cs),
    !!!cfr_interval(sum(ds), sum(cs), conf_level)
  )
  if (!is.null(delay)) {
    adj <- tibble::tibble(
      method = "delay_adjusted", deaths = sum(ds), cases = sum(cs),
      known_outcomes = known[length(known)],
      !!!cfr_interval(sum(ds), known[length(known)], conf_level)
    )
    out <- dplyr::bind_rows(out, adj)
  }
  out
  })
}

# Expected number of cases from each day whose outcome is known by the end
# of the series: c_i * P(delay <= T - i), summed by day of outcome.
cfr_known <- function(cs, delay) {
  vapply(seq_along(cs), function(t) {
    i <- seq_len(t)
    lag <- t - i
    w <- ifelse(lag < length(delay), delay[pmin(lag + 1, length(delay))], 0)
    sum(cs[i] * w)
  }, 1)
}

cfr_interval <- function(d, u, conf_level) {
  if (u <= 0) return(list(cfr = NA_real_, lower = NA_real_, upper = NA_real_))
  u <- max(u, d)
  p <- d / u
  crit <- stats::qchisq(conf_level, 1) / 2
  ll <- function(q) {
    (if (d > 0) d * log(q) else 0) + (if (u > d) (u - d) * log1p(-q) else 0)
  }
  top <- ll(p)
  f <- function(q) top - ll(q) - crit
  eps <- 1e-12
  lower <- if (d == 0 || f(eps) < 0) 0 else stats::uniroot(f, c(eps, p), tol = 1e-12)$root
  upper <- if (d >= u || f(1 - eps) < 0) {
    1
  } else {
    stats::uniroot(f, c(p, 1 - eps), tol = 1e-12)$root
  }
  list(cfr = p, lower = lower, upper = upper)
}
