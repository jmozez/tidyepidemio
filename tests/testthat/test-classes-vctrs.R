test_that("epi tibble metadata survive operations", {
  x <- epi_linelist(data.frame(id = 1:3), metadata = list(source = "test"))
  expect_s3_class(x, "epi_linelist")
  expect_equal(attr(x[1:2, ], "epi_metadata"), list(source = "test"))
  expect_equal(attr(dplyr::mutate(x, z = id + 1), "epi_metadata"), list(source = "test"))
  expect_s3_class(epi_cohort(data.frame(x = 1)), "epi_cohort")
  expect_s3_class(epi_ts(data.frame(x = 1)), "epi_ts")
  expect_error(epi_linelist(1), "data frame")
})
test_that("combining incompatible metadata is rejected", {
  a <- epi_linelist(data.frame(x = 1), metadata = list(source = "a"))
  b <- epi_linelist(data.frame(x = 2), metadata = list(source = "b"))
  expect_error(vctrs::vec_rbind(a, b), "different classes or metadata")
  expect_error(dplyr::bind_rows(a, b), "different classes or metadata")
  expect_s3_class(vctrs::vec_rbind(a, a), "epi_linelist")
  expect_error(
    vctrs::vec_rbind(a, epi_cohort(data.frame(x = 1), metadata = list(source = "a"))),
    "different classes or metadata"
  )
})

test_that("plain data cannot silently inherit epidemiological provenance", {
  x <- epi_linelist(tibble::tibble(id = 1:2), metadata = list(source = "A"))
  raw <- tibble::tibble(id = 3)
  expect_error(dplyr::bind_rows(x, raw), "plain data frames")
  expect_error(dplyr::bind_rows(raw, x), "plain data frames")
  expect_error(vctrs::vec_rbind(x, as.data.frame(raw)), "plain data frames")
  expect_error(vctrs::vec_cast(raw, x), "plain data frames")
  same <- epi_linelist(raw, metadata = list(source = "A"))
  result <- dplyr::bind_rows(x, same)
  expect_equal(result$id, 1:3)
  expect_identical(attr(result, "epi_metadata"), list(source = "A"))
})
test_that("metadata and common dplyr operations follow their contract", {
  x <- epi_cohort(data.frame(id = 1:3, grp = c(1, 1, 2)), metadata = list(source = "A"))
  for (z in list(dplyr::filter(x, id > 1), dplyr::select(x, id), dplyr::arrange(x, dplyr::desc(id)), dplyr::left_join(x, data.frame(id = 1:3, w = 1), by = "id"))) { # nolint: line_length_linter.
    expect_s3_class(z, "epi_cohort")
    expect_identical(attr(z, "epi_metadata"), list(source = "A"))
  }
  expect_error(
    epi_cohort(data.frame(id = 1), metadata = structure(list(1), names = NA_character_)),
    "metadata"
  )
  expect_error(epi_cohort(data.frame(id = 1), metadata = list(a = 1, a = 2)), "metadata")
})
