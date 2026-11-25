test_that("follow-up handles administrative censoring and event boundary", {
  d <- data.frame(
    start = as.Date("2024-01-01") + c(0, 1, 1),
    end = as.Date("2024-01-01") + c(5, 7, 10),
    event = c(1, 1, 1)
  )
  z <- epi_follow_up(d, start, end, event, censor_at = as.Date("2024-01-08"))
  expect_equal(z$follow_up, c(5, 6, 6))
  expect_equal(z$event_observed, c(1, 1, 0))
  expect_equal(z$followup_end, as.Date("2024-01-01") + c(5, 7, 7))
  years <- epi_follow_up(d, start, end, event, unit = "years")
  expect_equal(years$follow_up, c(5, 6, 9) / 365.25)
  expect_error(epi_follow_up(d, start, end, event, censor_at = as.Date("2023-12-31")), "after")
  expect_error(epi_follow_up(transform(d, end = start - 1), start, end, event), "precede")
})
