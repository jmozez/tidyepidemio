test_that("compiled spatial scan matches the original R implementation", {
  set.seed(21)
  loc <- data.frame(x = runif(60), y = runif(60), pop = rpois(60, 300) + 1)
  loc$cases <- rpois(60, loc$pop * 0.02)
  loc$cases[1:5] <- loc$cases[1:5] + 15
  set.seed(5); new <- epi_spatial_scan(loc, x, y, cases, pop, radii = c(.1, .2), nsim = 99)
  set.seed(5); old <- reference_spatial_scan(loc, x, y, cases, pop, radii = c(.1, .2), nsim = 99)
  expect_equal(new, old)
})

test_that("compiled space-time scan matches the original R implementation", {
  set.seed(22)
  d <- data.frame(x = runif(30), y = runif(30), pop = rpois(30, 500) + 1)
  for (t in 1:6) d[[paste0("w", t)]] <- rpois(30, 2)
  d$w6[1:4] <- d$w6[1:4] + 8
  set.seed(6); new <- epi_spacetime_scan(d, x, y, w1:w6, pop, radii = c(.15, .3), nsim = 49)
  set.seed(6); old <- reference_spacetime_scan(d, x, y, w1:w6, pop, radii = c(.15, .3), nsim = 49)
  expect_equal(new, old)
})

test_that("compiled moving window matches mean() and var()", {
  set.seed(23)
  y <- rpois(200, 20)
  mw <- moving_window_cpp(as.double(y), 7L)
  i <- 50
  expect_identical(mw$mean[i], mean(y[(i - 7):(i - 1)]))
  expect_equal(mw$var[i], stats::var(y[(i - 7):(i - 1)]))
  expect_true(all(is.na(mw$mean[1:7])))
})
