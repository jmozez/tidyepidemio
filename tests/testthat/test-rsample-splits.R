test_that("rolling and blocked resampling produce valid splits", {
  d <- data.frame(t = 1:20, block = rep(1:4, each = 5))
  r <- epi_rolling_origin(d, initial = 10, assess = 3, lag = 1)
  expect_gt(nrow(r), 0)
  expect_lt(max(rsample::analysis(r$splits[[1]])$t), min(rsample::assessment(r$splits[[1]])$t))
  set.seed(1)
  s <- epi_spatial_cv(d, block, v = 2)
  expect_equal(nrow(s), 2)
  for (sp in s$splits) {
    expect_length(intersect(rsample::analysis(sp)$block, rsample::assessment(sp)$block), 0)
  }
  expect_error(epi_spatial_cv(d, block, v = 5), "number of blocks")
})
test_that("spatial buffer excludes nearby training observations", {
  d <- data.frame(block = rep(1:6, each = 2), x = rep(seq(0, 50, 10), each = 2) + rep(c(0, 1), 6), y = 0)
  set.seed(3)
  cv <- epi_spatial_cv(d, block, v = 3, x = x, y = y, buffer = 9)
  for (sp in cv$splits) {
    a <- rsample::analysis(sp)
    b <- rsample::assessment(sp)
    expect_true(all(abs(outer(a$x, b$x, `-`)) > 9))
    expect_length(intersect(a$block, b$block), 0)
  }
  expect_error(epi_spatial_cv(d, block, v = 2, buffer = 1), "required")
  expect_error(epi_spatial_cv(d, block, v = 2, x = x, y = y, buffer = 1000), "every analysis row")
})
