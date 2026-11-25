# Input validation and warning paths that the method tests do not exercise.

test_that("parsnip specifications and fitters reject invalid input", {
  expect_error(epi_renewal("not data"), "NULL or a data frame")
  expect_error(epi_renewal(mode = "classification"), "regression")
  expect_error(epi_compartmental("not data"), "NULL or a data frame")
  expect_error(epi_compartmental(mode = "classification"), "regression")
  d <- data.frame(time = 1:6, cases = c(1, 2, 4, 8, 16, 32))
  expect_error(fit_epi_renewal(cases ~ time, transform(d, cases = cases + 0.5)), "integer")
  expect_error(fit_epi_renewal(cases ~ time, d, weights = c(0.3, 0.3)), "sum to one")
  expect_error(fit_epi_renewal(cases ~ time, d[1:2, ], weights = c(0.5, 0.5)), "More observations")
  expect_error(
    fit_epi_renewal(cases ~ time, data.frame(time = 1:4, cases = c(0, 0, 5, 1))),
    "incompatible"
  )
  fit <- fit_epi_renewal(cases ~ time, d)
  expect_error(predict(fit, data.frame(day = 7)), "time column")
  expect_length(predict(fit, d[0, ]), 0)
})

test_that("compartmental fit checks population and boundaries", {
  d <- data.frame(time = 0:5, infectious = c(1, 3, 8, 20, 40, 60))
  expect_error(fit_epi_compartmental(infectious ~ time, d, 30, 0.5), "must not exceed")
  expect_warning(
    fit_epi_compartmental(infectious ~ time, d, 1000, 0.5, beta_max = 0.6),
    "boundary"
  )
})

test_that("propensity weights validate their inputs", {
  d <- data.frame(e = rep(0:1, 10), age = 1:20, flag = TRUE)
  expect_error(epi_propensity_weights(d, e, stabilized = NA), "TRUE or FALSE")
  expect_error(epi_propensity_weights(d, c(e, age)), "exactly one")
  expect_error(epi_propensity_weights(d[1:3, ], e), "four observations")
  expect_error(epi_propensity_weights(transform(d, ipw = 1), e), "already exist")
  expect_error(epi_propensity_weights(d, e, adjust = flag), "at least two observed")
  sep <- data.frame(e = rep(0:1, each = 10), x = c(1:10, 101:110))
  as_warning <- function(expr) tryCatch(expr, error = function(err) warning(conditionMessage(err)))
  expect_warning(as_warning(epi_propensity_weights(sep, e, adjust = x)))
  skew <- data.frame(e = c(rep(0, 40), rep(1, 4)), x = c(rep(0, 38), 5, 5, 5, 5, 5, 5))
  expect_warning(epi_propensity_weights(skew, e, adjust = x), "0.01")
})

test_that("weighted effects report undefined ratios and failed resamples", {
  d <- data.frame(e = c(0, 0, 1, 1), y = c(0, 0, 1, 0), w = 1)
  expect_warning(z <- epi_weighted_effect(d, e, y, w), "undefined")
  expect_true(is.na(z$risk_ratio))
  expect_error(epi_weighted_effect(data.frame(e = c(1, 1), y = 0:1, w = 1), e, y, w), "Both exposure groups")
  set.seed(3)
  rare <- data.frame(e = c(1, rep(0, 29)), y = rbinom(30, 1, .3), w = 1)
  expect_error(epi_weighted_effect(rare, e, y, w, bootstrap = 100), "lacked an exposure group")
})

test_that("adjusted models validate weights, clusters, modifiers and splines", {
  set.seed(9)
  d <- data.frame(e = rbinom(200, 1, .5), age = rnorm(200), g = rep(1:5, 40), sex = rep(c("f", "m"), 100))
  d$y <- rbinom(200, 1, plogis(-1 + .5 * d$e))
  expect_error(epi_adjusted_odds_ratio(d, e, y, adjust = age, weights = age), "separate column")
  expect_error(epi_adjusted_odds_ratio(d, e, c(y, age)), "Select")
  expect_error(epi_adjusted_odds_ratio(transform(d, g = NA), e, y, cluster = g), "complete")
  expect_warning(z <- epi_adjusted_odds_ratio(d, e, y, cluster = g, robust = "HC1"), "Only 5 clusters")
  expect_equal(z$se_type, "cluster_HC1")
  expect_error(epi_adjusted_odds_ratio(transform(d, sex = list(1)[rep(1, 200)]), e, y, modifier = sex))
  expect_error(epi_adjusted_odds_ratio(transform(d, m = "a"), e, y, modifier = m), "between 2 and 10")
  expect_error(epi_adjusted_odds_ratio(transform(d, k = rep(1:2, 100)), e, y, adjust = k, nonlinear = k), "five")
  sep <- data.frame(e = rep(0:1, each = 20), y = rep(0:1, each = 20))
  expect_warning(tryCatch(epi_adjusted_odds_ratio(sep, e, y), error = function(err) warning(conditionMessage(err))))
})
