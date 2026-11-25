test_that("data-first renewal fit agrees with engine and parsnip", {
  d <- data.frame(day = 1:5, cases = c(1, 2, 4, 8, 16))
  fit <- epi_fit_renewal(d, day, cases, weights = 1)
  expect_equal(fit$estimate, fit_epi_renewal(cases ~ day, d)$estimate)
  expect_equal(predict(fit, data.frame(day = 6:7)), c(32, 64))
  expect_equal(generics::tidy(fit)$estimate, 2)
})
test_that("data-first compartmental fit matches low-level engine", {
  sim <- epi_simulate(data.frame(S = 990, I = 10, R = 0), beta = .3, gamma = .1, steps = 7)
  fit <- epi_fit_compartmental(sim, time, I, population = 1000, gamma = .1)
  expect_equal(fit$estimate, .3, tolerance = .0001)
  expect_equal(fit$estimate, fit_epi_compartmental(I ~ time, sim, 1000, .1)$estimate)
})
test_that("non-syntactic names and tidy selection work; bad selections fail", {
  d <- data.frame(`day number` = 1:5, `case count` = c(1, 2, 4, 8, 16), check.names = FALSE)
  a <- epi_fit_renewal(d, `day number`, `case count`)
  b <- epi_fit_renewal(d, tidyselect::all_of("day number"), tidyselect::all_of("case count"))
  expect_equal(a$estimate, 2)
  expect_equal(a$estimate, b$estimate)
  expect_equal(predict(a, data.frame(`day number` = 6, check.names = FALSE)), 32)
  expect_error(epi_fit_renewal(d, tidyselect::everything(), `case count`), "exactly one")
  expect_error(epi_fit_renewal(d, `day number`, `day number`), "distinct")
  expect_error(fit_epi_renewal(`case count` ~ log(`day number`), d), "simple column")
  expect_error(
    epi_fit_renewal(dplyr::group_by(d, `day number`), `day number`, `case count`),
    "Grouped"
  )
})
