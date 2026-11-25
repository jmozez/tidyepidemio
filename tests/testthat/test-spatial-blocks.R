test_that("square blocks have stable boundaries and negative indices", {
  d <- data.frame(x = c(-1, 0, 9, 10), y = c(0, 0, 11, 11))
  z <- epi_spatial_blocks(d, x, y, size = 10)
  expect_equal(z$block_x, c(-1L, 0L, 0L, 1L))
  expect_equal(z$block_y, c(0L, 0L, 1L, 1L))
  expect_equal(z$block_id, c("-1:0", "0:0", "0:1", "1:1"))
  expect_equal(epi_spatial_blocks(d, x, y, size = 10, origin_x = -10)$block_x, c(0L, 1L, 1L, 2L))
  expect_error(epi_spatial_blocks(d, x, y, size = 0), "size")
  expect_error(epi_spatial_blocks(z, x, y, size = 10), "already exist")
})
test_that("grid blocks can be used for spatial resampling", {
  d <- data.frame(x = seq(0, 50, by = 10), y = 0)
  z <- epi_spatial_blocks(d, x, y, size = 10)
  set.seed(1)
  cv <- epi_spatial_cv(z, block_id, v = 3, x = x, y = y, buffer = 5)
  expect_equal(nrow(cv), 3L)
  for (sp in cv$splits) {
    expect_true(all(abs(outer(rsample::analysis(sp)$x, rsample::assessment(sp)$x, `-`)) > 5))
  }
})
