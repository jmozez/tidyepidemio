test_that("adjusted odds ratio agrees with glm", {
  d <- expand.grid(e = 0:1, age = 20:24, sex = factor(c("f", "m")), rep = 1:6)
  d$y <- as.integer(d$rep <= 2 + d$e + (d$age %% 2))
  z <- epi_adjusted_odds_ratio(d, e, y, adjust = c(age, sex))
  m <- stats::glm(y ~ e + age + sex, data = d, family = stats::binomial())
  beta <- stats::coef(m)["e"]
  se <- summary(m)$coefficients["e", "Std. Error"]
  expect_equal(z$estimate, unname(exp(beta)))
  expect_equal(z$conf_low, unname(exp(beta - qnorm(.975) * se)))
  expect_equal(z$conf_high, unname(exp(beta + qnorm(.975) * se)))
  expect_s3_class(ggplot2::autoplot(z), "ggplot")
  expect_equal(
    epi_adjusted_odds_ratio(d, e, y)$estimate,
    unname(exp(coef(glm(y ~ e, data = d, family = binomial()))["e"]))
  )
  expect_error(epi_adjusted_odds_ratio(d, e, y, adjust = e), "exclude")
  expect_error(epi_adjusted_odds_ratio(transform(d, age = NA), e, y, adjust = age), "complete")
})
