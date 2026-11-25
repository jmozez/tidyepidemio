test_that("renewal parsnip engine fits and forecasts", {
  d <- data.frame(time = 1:6, cases = c(1, 2, 4, 8, 16, 32))
  spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights = 1)
  fit <- parsnip::fit(spec, cases ~ time, data = d)
  expect_equal(fit$fit$estimate, 2)
  expect_equal(predict(fit, new_data = data.frame(time = 7:8))$.pred, c(64, 128))
  expect_equal(generics::tidy(fit$fit)$estimate, 2)
  expect_equal(generics::glance(fit$fit)$nobs, 6)
  expect_equal(generics::augment(fit$fit)$.fitted, c(NA, 2, 4, 8, 16, 32))
  expect_equal(generics::augment(fit$fit, data = data.frame(time = 7, cases = 70))$.resid, 6)
  expect_error(
    fit_epi_renewal(cases ~ time, data.frame(time = c(1, 3), cases = c(1, 2))),
    "consecutive"
  )
})
test_that("compartmental parsnip engine fits and predicts", {
  obs <- epi_simulate(data.frame(S = 990, I = 10, R = 0), beta = .3, gamma = .1, steps = 8)
  d <- data.frame(time = obs$time, infectious = obs$I)
  spec <- epi_compartmental() |> parsnip::set_engine("tidyepidemio", population = 1000, gamma = .1)
  fit <- parsnip::fit(spec, infectious ~ time, data = d)
  expect_equal(fit$fit$estimate, .3, tolerance = .0001)
  expect_equal(
    predict(fit, new_data = data.frame(time = 0:8))$.pred,
    d$infectious,
    tolerance = 0.001
  )
  expect_equal(generics::tidy(fit$fit)$term, c("beta", "gamma"))
  expect_error(predict(fit$fit, data.frame(time = -1)), "at or after")
})
test_that("SEIR parsnip model estimates beta with fixed progression and initial E and R", {
  obs <- epi_simulate(
    data.frame(S = 975, E = 10, I = 10, R = 5),
    beta = 0.3,
    gamma = 0.1,
    sigma = 0.2,
    steps = 12,
    model = "seir"
  )
  d <- data.frame(time = obs$time, infectious = obs$I)
  spec <- parsnip::set_engine(
    epi_compartmental(),
    "tidyepidemio",
    population = 1000,
    gamma = 0.1,
    model = "seir",
    sigma = 0.2,
    initial_exposed = 10,
    initial_recovered = 5
  )
  fit <- parsnip::fit(spec, infectious ~ time, data = d)
  expect_equal(fit$fit$estimate, .3, tolerance = .0001)
  expect_equal(
    predict(fit, new_data = data.frame(time = 0:12))$.pred,
    d$infectious,
    tolerance = 0.001
  )
  expect_equal(generics::tidy(fit$fit)$term, c("beta", "gamma", "sigma"))
  expect_error(
    fit_epi_compartmental(infectious ~ time, d[1:2, ], 1000, 0.1, model = "seir", sigma = 0.2),
    "three observations"
  )
  expect_error(
    fit_epi_compartmental(infectious ~ time, d, 1000, 0.1, model = "sir", sigma = 0.2),
    "must be NULL"
  )
})

test_that("low-level model engines reject grouped data", {
  d <- dplyr::group_by(data.frame(t = 1:4, y = c(1, 2, 3, 4)), y)
  expect_error(fit_epi_renewal(y ~ t, d), "Grouped")
  expect_error(fit_epi_compartmental(y ~ t, d, population = 100, gamma = .1), "Grouped")
})
