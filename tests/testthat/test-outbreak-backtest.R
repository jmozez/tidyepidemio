test_that("backtesting is rolling, reproducible and uses only prior history", {
  d <- data.frame(day = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
  set.seed(7)
  a <- epi_renewal_backtest(
    d,
    day,
    cases,
    weights = 1,
    initial = 3,
    horizon = 2,
    stride = 2,
    mode = "fixed",
    nsim = 1000
  )
  set.seed(7)
  b <- epi_renewal_backtest(
    d,
    day,
    cases,
    weights = 1,
    initial = 3,
    horizon = 2,
    stride = 2,
    mode = "fixed",
    nsim = 1000
  )
  expect_equal(a, b)
  expect_equal(a$origin, c(3L, 3L, 5L, 5L))
  expect_equal(a$target_time, c(4L, 5L, 6L, 7L))
  expect_equal(a$observed, c(8, 16, 32, 64))
  expect_equal(a$posterior_mean_rt[1], 7 / 4)
  d$cases[7:8] <- c(1000, 2000)
  set.seed(7)
  c <- epi_renewal_backtest(
    d,
    day,
    cases,
    weights = 1,
    initial = 3,
    horizon = 2,
    stride = 2,
    mode = "fixed",
    nsim = 1000
  )
  expect_equal(a$forecast_mean[1:2], c$forecast_mean[1:2])
  expect_equal(a$forecast_low[1:2], c$forecast_low[1:2])
  expect_equal(a$forecast_mean[1], 4 * 7 / 4, tolerance = .4)
})
test_that("backtesting validates series and supports Date time", {
  d <- data.frame(day = as.Date("2024-01-01") + 0:5, cases = c(1, 2, 4, 8, 16, 32))
  set.seed(1)
  z <- epi_renewal_backtest(d, day, cases, 1, initial = 3, horizon = 2, nsim = 100)
  expect_s3_class(z$target_time, "Date")
  expect_equal(nrow(z), 4L)
  expect_error(
    epi_renewal_backtest(transform(d, day = day + c(0, 0, 0, 0, 1, 1)), day, cases, 1, initial = 3),
    "regularly spaced"
  )
  expect_error(
    epi_renewal_backtest(d, day, cases, weights = c(0.2, 0.2), initial = 3),
    "weights must sum"
  )
})
