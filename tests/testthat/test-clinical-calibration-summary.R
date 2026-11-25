test_that("calibration summary matches regression, brier and rank AUC", {
  d <- data.frame(y = c(0, 0, 1, 0, 1, 0, 1, 1), p = c(.1, .2, .3, .4, .5, .6, .7, .8))
  z <- epi_calibration_summary(d, y, p)
  d$lp <- qlogis(d$p)
  large <- glm(y ~ offset(lp), data = d, family = binomial())
  joint <- glm(y ~ lp, data = d, family = binomial())
  expect_equal(z$brier, mean((d$y - d$p)^2))
  expect_equal(z$calibration_in_large, unname(coef(large)[1]))
  expect_equal(z$calibration_intercept, unname(coef(joint)[1]))
  expect_equal(z$calibration_slope, unname(coef(joint)[2]))
  pos <- d$p[d$y == 1]
  neg <- d$p[d$y == 0]
  manual <- mean(outer(pos, neg, `>`) + .5 * outer(pos, neg, `==`))
  expect_equal(z$roc_auc, manual)
  expect_error(epi_calibration_summary(transform(d, p = 1), y, p), "strictly")
})
test_that("AUC denominator does not overflow with large outcome groups", {
  d <- data.frame(y = rep(0:1, each = 50000), p = rep(c(.3, .7), 50000))
  z <- epi_calibration_summary(d, y, p)
  expect_equal(z$roc_auc, .5)
  expect_equal(z$n, 100000L)
})
