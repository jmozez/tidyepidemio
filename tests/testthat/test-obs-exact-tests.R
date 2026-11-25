test_that("Fisher test agrees with stats conditional odds ratio and confidence interval", {
  d <- data.frame(e = c(rep(1, 10), rep(0, 10)), y = c(rep(1, 7), rep(0, 3), rep(1, 2), rep(0, 8)))
  z <- epi_fisher_test(d, e, y)
  ref <- fisher.test(matrix(c(7, 3, 2, 8), nrow = 2, byrow = TRUE))
  expect_equal(z$estimate, unname(ref$estimate))
  expect_equal(c(z$conf_low, z$conf_high), as.numeric(ref$conf.int))
  expect_equal(z$p_value, ref$p.value)
  expect_error(epi_fisher_test(transform(d, y = 0), e, y), "outcome levels")
})
test_that("Mantel-Haenszel inference matches reference test", {
  d <- data.frame(e = rep(c(0, 0, 1, 1), 2), y = rep(c(0, 1, 0, 1), 2), s = rep(1:2, each = 4))
  z <- epi_mantel_haenszel_test(d, e, y, s)
  ref <- mantelhaen.test(
    factor(d$e, levels = c(1, 0)),
    factor(d$y, levels = c(1, 0)),
    factor(d$s),
    correct = FALSE
  )
  expect_equal(z$estimate, unname(ref$estimate))
  expect_equal(c(z$conf_low, z$conf_high), as.numeric(ref$conf.int))
  expect_equal(z$p_value, ref$p.value)
  expect_equal(z$estimate, epi_mantel_haenszel(d, e, y, s)$estimate)
  expect_error(epi_mantel_haenszel_test(transform(d, s = NA), e, y, s), "strata")
})
test_that("uninformative strata do not silently return NaN inference", {
  d <- data.frame(e = c(0, 0, 1, 1), y = c(0, 1, 0, 1), s = c(0, 0, 1, 1))
  expect_error(epi_mantel_haenszel_test(d, e, y, s), "not estimable")
})
