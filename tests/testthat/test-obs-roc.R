test_that("empirical ROC has correct tied threshold groups and AUC", {
  d <- data.frame(y = c(0, 1, 0, 1), s = c(.1, .6, .6, .9))
  z <- epi_roc_curve(d, y, s)
  expect_equal(z$threshold, c(Inf, .9, .6, .1))
  expect_equal(z$tp, c(0, 1, 2, 2))
  expect_equal(z$fp, c(0, 0, 1, 2))
  expect_equal(z$auc, rep(.875, 4))
  expect_true(is.na(z$ppv[1]))
  expect_true(is.na(z$npv[4]))
  ref <- yardstick::roc_auc_vec(
    factor(ifelse(d$y == 1, "case", "control"), levels = c("case", "control")),
    d$s
  )
  expect_equal(z$auc[1], ref)
  expect_s3_class(epi_plot_roc(z), "ggplot")
  expect_no_error(ggplot2::ggplot_build(epi_plot_roc(z)))
})
test_that("lower scores can indicate positive and bad inputs are rejected", {
  d <- data.frame(y = c(0, 1, 0, 1), s = c(.1, .6, .6, .9))
  z <- epi_roc_curve(d, y, s, direction = "lower")
  expect_equal(z$auc[1], .125)
  expect_equal(z$threshold, c(-Inf, .1, .6, .9))
  expect_error(epi_roc_curve(transform(d, y = 0), y, s), "Both outcome levels")
  expect_error(epi_plot_roc(z[nrow(z):1, ]), "ordered")
})
