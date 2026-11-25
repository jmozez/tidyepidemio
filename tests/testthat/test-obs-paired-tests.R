test_that("paired tests use correct reference subgroups and exact discordance", {
  d <- data.frame(
    y = rep(0:1, each = 5),
    a = c(0, 0, 1, 0, 1, 1, 1, 1, 0, 0),
    b = c(0, 1, 0, 0, 1, 1, 0, 1, 1, 0)
  )
  z <- epi_paired_diagnostic(d, a, b, y)
  expect_equal(z$test1, c(3 / 5, 3 / 5))
  expect_equal(z$test2, c(3 / 5, 3 / 5))
  expect_equal(z$difference, c(0, 0))
  expect_equal(z$test1_only_correct, c(1, 1))
  expect_equal(z$test2_only_correct, c(1, 1))
  expect_equal(z$p_value, c(1, 1))
})
test_that("exact paired p-values match binomial test and no discordance is defined", {
  d <- data.frame(
    y = c(rep(1, 8), rep(0, 8)),
    a = c(rep(1, 8), rep(0, 8)),
    b = c(rep(0, 6), 1, 1, rep(0, 8))
  )
  z <- epi_paired_diagnostic(d, a, b, y)
  expect_equal(z$p_value[1], binom.test(6, 6)$p.value)
  expect_equal(z$p_value[2], 1)
  expect_error(epi_paired_diagnostic(d[1:8, ], a, b, y), "Both")
})
test_that("paired differences carry Tango score intervals", {
  # PropCIs::scoreci.mp(b, c, n) reports (c - b) / n; ours is (b - c) / n, so limits mirror.
  expect_equal(tango_paired_ci(5, 2, 40, .95), c(-0.065685, 0.223396), tolerance = 1e-5)
  expect_equal(tango_paired_ci(0, 0, 20, .95), c(-0.161125, 0.161125), tolerance = 1e-5)
  expect_equal(tango_paired_ci(7, 0, 30, .95), c(0.093333, 0.409283), tolerance = 1e-5)
  d <- data.frame(
    y = rep(0:1, each = 5),
    a = c(0, 0, 1, 0, 1, 1, 1, 1, 0, 0),
    b = c(0, 1, 0, 0, 1, 1, 0, 1, 1, 0)
  )
  z <- epi_paired_diagnostic(d, a, b, y)
  expect_true(all(z$conf_low <= z$difference & z$difference <= z$conf_high))
})
