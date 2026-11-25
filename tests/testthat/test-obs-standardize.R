test_that("standardization and Mantel-Haenszel are correct", {
  d <- data.frame(a = c(10, 20), n = c(100, 100), s = c(150, 50))
  expect_equal(epi_standardize(d, a, n, s)$estimate, 0.125)
  expect_equal(
    epi_standardize(data.frame(a = c(10, 20), n = c(100, 100), s = c(0.1, 0.1)), a, n, s, method = "indirect")$estimate,
    1.5
  )
  x <- data.frame(e = rep(c(0, 0, 1, 1), 2), y = rep(c(0, 1, 0, 1), 2), s = rep(1:2, each = 4))
  expect_equal(epi_mantel_haenszel(x, e, y, s)$estimate, 1)
  expect_error(epi_standardize(d, a, n, s, method = "direct", multiplier = 0), "multiplier")
})
test_that("Mantel-Haenszel cell products do not overflow", {
  d <- data.frame(
    e = rep(0:1, each = 1e+05),
    y = c(rep(1, 60000), rep(0, 40000), rep(1, 40000), rep(0, 60000)),
    stratum = 1
  )
  expect_equal(epi_mantel_haenszel(d, e, y, stratum)$estimate, 4 / 9)
})
test_that("Mantel-Haenszel interval and Breslow-Day test match references", {
  set.seed(1)
  d <- data.frame(s = rep(1:4, each = 200), e = rbinom(800, 1, .5))
  d$y <- rbinom(800, 1, plogis(-1 + c(.2, .9, 1.5, .1)[d$s] * d$e))
  z <- epi_mantel_haenszel(d, e, y, s)
  ref <- stats::mantelhaen.test(table(factor(d$e, 1:0), factor(d$y, 1:0), d$s))
  expect_equal(z$estimate, unname(ref$estimate))
  expect_equal(c(z$conf_low, z$conf_high), as.numeric(ref$conf.int))
  # DescTools::BreslowDayTest(correct = TRUE) on the same table
  expect_equal(z$heterogeneity_statistic, 6.8553614224, tolerance = 1e-8)
  expect_equal(z$heterogeneity_p_value, 0.0766536070, tolerance = 1e-8)
  expect_equal(z$heterogeneity_df, 3L)
})
test_that("Breslow-Day is zero for identical stratum odds ratios and NA with one stratum", {
  one <- data.frame(e = c(0, 0, 0, 1, 1, 1), y = c(0, 0, 1, 0, 1, 1))
  d <- rbind(cbind(one, s = 1), cbind(one, s = 2))
  z <- epi_mantel_haenszel(d, e, y, s)
  expect_equal(z$heterogeneity_statistic, 0, tolerance = 1e-8)
  expect_true(is.na(epi_mantel_haenszel(cbind(one, s = 1), e, y, s)$heterogeneity_p_value))
})
