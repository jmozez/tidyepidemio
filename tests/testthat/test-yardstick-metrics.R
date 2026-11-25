test_that("single interval WIS is computed", {
  d <- data.frame(y = c(1, 2), m = c(1, 3), l = c(0, 1), u = c(2, 4))
  expect_equal(wis(d, y, m, l, u, alpha = .1)$.estimate, mean(c(.1 / 1.5, .65 / 1.5)))
  expect_error(wis_vec(1, 2, 3, 4), "lower <= estimate")
  expect_true(is.na(wis_vec(NA_real_, 1, 0, 2, na_rm = FALSE)))
})
test_that("net benefit matches decision curve formula", {
  d <- data.frame(y = factor(c("case", "control"), levels = c("case", "control")), p = c(.8, .6))
  expect_equal(net_benefit(d, y, p, threshold = .5)$.estimate, 0)
  expect_error(net_benefit_vec(d$y, c(-1, 1)), "Probabilities")
})
test_that("net benefit supports metric sets, groups, and weights", {
  d <- data.frame(y = factor(c("case", "control", "case", "control"), levels = c("case", "control")), p = c(.8, .6, .9, .1), g = c(1, 1, 2, 2), w = c(2, 1, 1, 1))
  expect_equal(yardstick::metric_set(net_benefit)(d, truth = y, p)$.estimate, .25)
  z <- net_benefit(dplyr::group_by(d, g), y, p, case_weights = w)
  expect_equal(z$.estimate, c(1 / 3, .5))
  expect_equal(net_benefit_vec(d$y, d$p, case_weights = d$w), .4)
})
test_that("WIS handles multiple intervals, groups and weights", {
  d <- data.frame(y = c(0, 4), m = c(1, 3), l1 = c(0, 1), u1 = c(2, 5), l2 = c(-1, 0), u2 = c(3, 6), g = c(1, 2), w = c(2, 1))
  z <- wis(d, y, m, c(l1, l2), c(u1, u2), alpha = c(.5, .1), case_weights = w)
  # Scores: (0.5 + 0.5 + 0.2) / 2.5 = 0.48; (0.5 + 1 + 0.3) / 2.5 = 0.72.
  expect_equal(z$.estimate, .56)
  expect_equal(wis(dplyr::group_by(d, g), y, m, c(l1, l2), c(u1, u2), alpha = c(.5, .1))$.estimate, c(.48, .72))
  expect_error(wis_vec(1, 1, matrix(c(0, 0), nrow = 1), matrix(c(2, 2), nrow = 1), alpha = .1), "one distinct alpha")
})
