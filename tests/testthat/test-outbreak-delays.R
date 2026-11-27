test_that("double-censored delay probabilities are exact", {
  for (f in c("lognormal", "gamma", "weibull")) {
    p <- switch(f,
      lognormal = c(meanlog = 1.5, sdlog = 0.5),
      gamma = c(shape = 3, scale = 2),
      weibull = c(shape = 1.8, scale = 6)
    )
    pm <- delay_pmf_double(0:400, p, f)
    expect_equal(sum(pm), 1, tolerance = 1e-8)
    # Direct numerical integration of P(d) = int_0^1 F(d + 1 - u) - F(d - u) du
    direct <- vapply(0:10, function(d) {
      stats::integrate(function(u) {
        delay_cdf(pmax(d + 1 - u, 0), p, f) - delay_cdf(pmax(d - u, 0), p, f)
      }, 0, 1, rel.tol = 1e-10)$value
    }, 1)
    expect_equal(pm[1:11], direct, tolerance = 1e-7)
  }
})

test_that("epi_delay_dist() recovers parameters and corrects truncation", {
  set.seed(1)
  n <- 3000
  onset <- stats::runif(n, 0, 40)
  report <- onset + stats::rlnorm(n, 1.5, 0.5)
  d <- data.frame(delay = floor(report) - floor(onset), max_delay = 40 - floor(onset))
  seen <- d[d$delay <= d$max_delay, ]
  true_mean <- exp(1.5 + 0.5^2 / 2)
  fixed <- epi_delay_dist(seen, delay, max_delay = max_delay, family = "lognormal")
  naive <- epi_delay_dist(seen, delay, family = "lognormal")
  expect_s3_class(fixed, "tep_delay")
  expect_true(fixed$mean_lower < true_mean && fixed$mean_upper > true_mean)
  expect_lt(naive$mean, fixed$mean)
  all3 <- epi_delay_dist(d, delay)
  expect_equal(all3$family[1], "lognormal")
  expect_equal(all3$delta_aic[1], 0)
  expect_error(epi_delay_dist(data.frame(x = c(1.5, 2)), x), "whole days")
  expect_error(epi_delay_dist(d, delay, family = "beta"), "family")
})

test_that("exact delays match MASS::fitdistr()", {
  set.seed(2)
  x <- stats::rgamma(400, 3, scale = 2)
  fit <- epi_delay_dist(data.frame(x = x), x, family = "gamma", censoring = "none")
  ref <- MASS::fitdistr(x, "gamma")$estimate
  expect_equal(fit$parameters[[1]][["shape"]], unname(ref[["shape"]]), tolerance = 1e-4)
  expect_equal(fit$parameters[[1]][["scale"]], 1 / unname(ref[["rate"]]), tolerance = 1e-4)
  pmf <- epi_delay_pmf(fit, 30)
  expect_equal(sum(pmf$probability), 1)
  expect_equal(pmf$delay, 0:30)
  expect_error(epi_delay_pmf(data.frame(), 5), "epi_delay_dist")
})

test_that("epi_offspring() matches the negative binomial MLE", {
  set.seed(3)
  y <- stats::rnbinom(500, size = 0.3, mu = 1.2)
  o <- epi_offspring(data.frame(y = y), y)
  ref <- suppressWarnings(MASS::fitdistr(y, "negative binomial"))$estimate
  expect_equal(o$r, unname(ref[["mu"]]), tolerance = 1e-4)
  expect_equal(o$k, unname(ref[["size"]]), tolerance = 1e-3)
  expect_lt(o$aic_negbin, o$aic_poisson)
  # 20/80 rule: with k small, a minority of cases causes 80% of spread
  expect_lt(o$prop_80, 0.3)
  expect_equal(offspring_prop(2, 1e6, 0.8), 0.8, tolerance = 1e-3)
  expect_error(epi_offspring(data.frame(y = c(0.5, 1)), y), "whole")
})

test_that("epi_chain_size() recovers R and k from simulated chains", {
  set.seed(2)
  sim_chain <- function(r, k) {
    total <- 1
    current <- 1
    while (current > 0) {
      new <- sum(stats::rnbinom(current, size = k, mu = r))
      total <- total + new
      current <- new
    }
    total
  }
  chains <- replicate(1500, sim_chain(0.6, 0.4))
  fit <- epi_chain_size(data.frame(size = chains), size)
  expect_true(fit$r_lower < 0.6 && fit$r_upper > 0.6)
  expect_true(fit$k_lower < 0.4 && fit$k_upper > 0.4)
  # The maximum likelihood R equals 1 - 1 / mean chain size
  expect_equal(fit$r, 1 - 1 / mean(chains), tolerance = 1e-5)
})

test_that("epi_cfr() gives naive and delay-adjusted estimates", {
  sdlog <- sqrt(log(1 + (11.6 / 20.2)^2))
  meanlog <- log(20.2) - sdlog^2 / 2
  pmf <- diff(stats::plnorm(0:61, meanlog, sdlog))
  pmf <- pmf / sum(pmf)
  full <- epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = pmf)
  expect_equal(full$method, c("naive", "delay_adjusted"))
  expect_equal(full$cfr[1], 23 / 1530)
  early <- epi_cfr(nz_covid_outcomes_2020[1:50, ], cases, deaths, delay = pmf)
  expect_gt(early$cfr[2], 2 * early$cfr[1])
  same <- epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = 1)
  expect_equal(same$cfr[1], same$cfr[2])
  # Likelihood-ratio interval close to the exact binomial interval
  ci <- stats::binom.test(23, 1530)$conf.int
  expect_equal(c(full$lower[1], full$upper[1]), as.numeric(ci), tolerance = 0.05)
  cum <- epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = pmf, cumulative = TRUE)
  expect_equal(nrow(cum), nrow(nz_covid_outcomes_2020))
  expect_equal(cum$cfr_adjusted[nrow(cum)], full$cfr[2])
  expect_error(epi_cfr(nz_covid_outcomes_2020, cases, deaths, delay = c(0.5, 0.2)), "summing")
})
