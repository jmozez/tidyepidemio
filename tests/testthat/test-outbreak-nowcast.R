test_that("nowcast predictive negative-binomial distribution matches formula", {
  d <- data.frame(onset = as.Date("2024-01-01") + 0:2, reported = c(10, 8, 3))
  z <- epi_nowcast(d, onset, reported, as_of = as.Date("2024-01-03"), delay_prob = c(.5, .3, .2), prior_shape = 2, prior_rate = 1)
  expect_equal(z$reporting_fraction, c(1, .8, .5))
  expect_equal(z$nowcast_mean, c(10, 8 + .2 * 10 / 1.8, 3 + .5 * 5 / 1.5))
  expect_equal(z$nowcast_low[3], 3 + qnbinom(.025, size = 5, prob = 1.5 / 2))
  expect_equal(z$nowcast_high[3], 3 + qnbinom(.975, size = 5, prob = 1.5 / 2))
  expect_equal(z$nowcast_low[1], 10)
  expect_equal(z$nowcast_high[1], 10)
})
test_that("nowcasting validates time, delay and zero reporting probability", {
  d <- data.frame(onset = as.Date("2024-01-01"), reported = 1)
  expect_error(epi_nowcast(d, onset, reported, as.Date("2023-12-31"), 1), "not later")
  expect_error(epi_nowcast(d, onset, reported, as.Date("2024-01-01"), c(0, 1)), "zero reporting")
  expect_error(epi_nowcast(d, onset, reported, as.Date("2024-01-01"), c(.2, .2)), "summing")
  expect_error(epi_nowcast(rbind(d, d), onset, reported, as.Date("2024-01-01"), 1), "unique")
  d$reported <- 0
  z <- epi_nowcast(d, onset, reported, as.Date("2024-01-01"), c(0, 1), prior_shape = 2, prior_rate = 1)
  expect_equal(z$nowcast_mean, 2)
})
test_that("nowcast rejects fractional Date indices", {
  d <- data.frame(onset = structure(1.5, class = "Date"), reported = 0)
  expect_error(epi_nowcast(d, onset, reported, as.Date("2024-01-01"), 1), "whole days")
})
