test_that("decision curve matches hand-computed net benefit", {
  d <- data.frame(y = c(1, 1, 0, 0), p = c(.9, .6, .4, .1), w = c(1, 2, 3, 4))
  z <- epi_decision_curve(d, y, p, thresholds = c(.5, .75))
  expect_equal(z$net_benefit, c(.5, 0, 0, .25, -1, 0))
  expect_equal(z$strategy, rep(c("model", "treat_all", "treat_none"), 2))
  z <- epi_decision_curve(d, y, p, thresholds = .5, case_weights = w)
  expect_equal(z$net_benefit, c(.3, -.4, 0))
  expect_error(epi_decision_curve(d, y, p, thresholds = c(0, .5)), "strictly")
  expect_error(epi_decision_curve(transform(d, w = 0), y, p, case_weights = w), "positive total")
})
test_that("decision curve agrees with weighted yardstick net benefit", {
  d <- data.frame(y = c(0, 1, 1, 0, 0, 1), p = c(.2, .8, .3, .6, .1, .7), w = c(1, 2, 3, 1, 2, 4))
  factor_y <- factor(ifelse(d$y == 1, "case", "control"), levels = c("case", "control"))
  thresholds <- c(.25, .5, .75)
  z <- epi_decision_curve(d, y, p, thresholds = thresholds, case_weights = w)
  ref <- vapply(
    thresholds,
    function(x) net_benefit_vec(factor_y, d$p, threshold = x, case_weights = d$w),
    numeric(1)
  )
  expect_equal(z$net_benefit[z$strategy == "model"], ref)
})
