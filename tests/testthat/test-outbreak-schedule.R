test_that("scheduled SIR/SEIR matches constant-rate simulator", {
  for (model in c("sir", "seir")) {
    for (stochastic in c(FALSE, TRUE)) {
      d <- data.frame(S = 990, E = 5, I = 5, R = 0)
      rates <- data.frame(beta = rep(.3, 8), gamma = rep(.1, 8), sigma = rep(.2, 8))
      set.seed(10)
      a <- epi_simulate(d, .3, .1, sigma = .2, steps = 8, model = model, stochastic = stochastic)
      set.seed(10)
      b <- epi_simulate_schedule(rates, d, model = model, stochastic = stochastic)
      expect_equal(a, b[names(a)])
      expect_equal(
        rowSums(b[intersect(names(b), c("S", "E", "I", "R"))]),
        rep(sum(unlist(d[intersect(names(b), names(d))])), 9),
        tolerance = 1e-10
      )
      expect_equal(-diff(b$S), b$new_infections[-1])
      expect_equal(diff(b$R), b$new_recoveries[-1])
    }
  }
})
test_that("zero transmission stops new infections", {
  z <- epi_simulate_schedule(
    data.frame(beta = c(0.4, 0, 0), gamma = 0.1),
    data.frame(S = 99, I = 1, R = 0)
  )
  expect_equal(z$new_infections[3:4], c(0, 0))
  expect_error(
    epi_simulate_schedule(data.frame(beta = -1, gamma = 0.1), data.frame(S = 99, I = 1, R = 0)),
    "non-negative"
  )
})
