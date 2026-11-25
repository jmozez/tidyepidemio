test_that("Cox exposure effect and limits agree with survival", {
  d <- data.frame(t = 1:20, event = c(1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1), e = rep(0:1, 10), age = rep(30:34, 4), entry = rep(0:1, 10))
  z <- epi_cox_hazard_ratio(d, t, event, e, adjust = age, entry = entry)
  ref <- survival::coxph(survival::Surv(entry, t, event) ~ e + age, data = d)
  beta <- coef(ref)["e"]
  se <- sqrt(diag(vcov(ref)))["e"]
  expect_equal(z$estimate, unname(exp(beta)))
  expect_equal(z$conf_low, unname(exp(beta - qnorm(.975) * se)))
  expect_equal(z$conf_high, unname(exp(beta + qnorm(.975) * se)))
  z2 <- epi_cox_hazard_ratio(d, t, event, e)
  ref2 <- survival::coxph(survival::Surv(t, event) ~ e, data = d)
  expect_equal(z2$estimate, unname(exp(coef(ref2)["e"])))
  expect_error(epi_cox_hazard_ratio(transform(d, entry = t), t, event, e, entry = entry), "strictly less")
})
