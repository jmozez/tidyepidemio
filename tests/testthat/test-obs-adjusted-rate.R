test_that("adjusted rate ratio agrees with Poisson offset regression", {
  d <- data.frame(e = rep(0:1, each = 6), y = c(1, 2, 1, 2, 3, 1, 3, 4, 2, 4, 5, 3), t = rep(10, 12), age = rep(1:3, 4))
  z <- epi_adjusted_rate_ratio(d, y, t, e, adjust = age)
  fit <- glm(y ~ e + age + offset(log(t)), data = d, family = poisson())
  b <- coef(fit)["e"]
  se <- summary(fit)$coefficients["e", "Std. Error"]
  expect_equal(z$estimate, unname(exp(b)))
  expect_equal(z$conf_low, unname(exp(b - qnorm(.975) * se)))
  expect_equal(z$conf_high, unname(exp(b + qnorm(.975) * se)))
  expect_equal(epi_adjusted_rate_ratio(d, y, t, e)$estimate, unname(exp(coef(glm(y ~ e + offset(log(t)), data = d, family = poisson()))["e"])))
  expect_error(epi_adjusted_rate_ratio(transform(d, t = 0), y, t, e), "positive")
  expect_error(epi_adjusted_rate_ratio(d, y, t, e, adjust = e), "exclude")
})
