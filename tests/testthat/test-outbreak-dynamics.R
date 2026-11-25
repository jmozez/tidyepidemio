test_that("growth, serial interval and renewal ratio work", {
  d <- data.frame(t = 1:6, y = exp(.2 * (1:6)))
  expect_equal(epi_growth_rate(d, t, y)$growth_rate, .2, tolerance = 1e-10)
  expect_equal(epi_doubling_time(d, t, y)$doubling_time, log(2) / .2, tolerance = 1e-10)
  expect_equal(epi_rt(data.frame(y = c(1, 2, 4)), y, 1)$rt, c(NA, 2, 2))
  expect_error(epi_rt(d, y, c(.2, .2)), "summing to one")
  x <- data.frame(a = as.Date("2020-01-01") + 0:1, b = as.Date("2020-01-01") + 2:3)
  expect_equal(epi_serial_interval(x, a, b)$mean_days, 2)
})
test_that("SIR and SEIR simulations conserve population", {
  for (model in c("sir", "seir")) {
    for (stochastic in c(FALSE, TRUE)) {
      set.seed(1)
      d <- data.frame(S = 990, E = 5, I = 5, R = 0)
      z <- epi_simulate(
        d,
        beta = 0.3,
        gamma = 0.1,
        sigma = 0.2,
        steps = 10,
        model = model,
        stochastic = stochastic
      )
      cols <- intersect(c("S", "E", "I", "R"), names(z))
      expect_equal(rowSums(z[cols]), rep(sum(unlist(d[cols])), 11), tolerance = 1e-10)
      expect_true(all(as.matrix(z[cols]) >= 0))
    }
  }
  expect_error(epi_simulate(data.frame(S = 1, I = 1, R = 0), 1, 1, steps = -1), "steps")
})
