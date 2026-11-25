test_that("predictive values use Bayes rule at target prevalences", {
  d <- data.frame(test = c(1, 1, 0, 0), truth = c(1, 0, 1, 0))
  z <- epi_predictive_values(d, test, truth, prevalence = c(.01, .1, .5))
  expect_equal(z$ppv, c(.01, .1, .5))
  expect_equal(z$npv, c(.99, .9, .5))
  expect_equal(z$sensitivity, rep(.5, 3))
  expect_error(
    epi_predictive_values(d, test, truth, prevalence = c(-0.1, 0.5)),
    "between zero and one"
  )
  d <- data.frame(test = c(1, 0), truth = c(1, 0))
  expect_warning(z <- epi_predictive_values(d, test, truth, prevalence = c(0, 1)), "undefined")
  expect_true(is.na(z$ppv[1]))
  expect_true(is.na(z$npv[2]))
})
