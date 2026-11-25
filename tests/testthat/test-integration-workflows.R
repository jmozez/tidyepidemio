test_that("cohort data flow consistently from follow-up to survival and effects", {
  d <- data.frame(
    start = as.Date("2024-01-01") + rep(0, 8), end = as.Date("2024-01-01") + 1:8,
    event = c(1, 0, 1, 0, 1, 1, 0, 1), exposed = rep(0:1, each = 4)
  )
  cohort <- epi_cohort(d, metadata = list(source = "integration"))
  follow <- epi_follow_up(cohort, start, end, event, censor_at = as.Date("2024-01-07"))
  expect_equal(follow$event_observed, c(1, 0, 1, 0, 1, 1, 0, 0))
  expect_equal(epi_person_time(follow, event_observed, follow_up)$person_time, 33)
  expect_equal(epi_incidence(follow, event_observed)$events, 4)
  risk <- epi_survival_risk(follow, follow_up, event_observed, horizons = c(2, 5))
  km <- epi_kaplan_meier(follow, follow_up, event_observed)
  expect_equal(risk$risk, 1 - km$estimate[match(c(2, 5), km$time)])
  expect_equal(generics::tidy(epi_risk_ratio(follow, exposed, event_observed))$measure, "risk_ratio")
})
test_that("rolling splits connect recipe history, parsnip and forecast metrics", {
  d <- data.frame(time = 1:8, cases = c(1, 2, 4, 8, 16, 32, 64, 128))
  split <- epi_rolling_origin(d, initial = 6, assess = 2)$splits[[1]]
  train <- rsample::analysis(split)
  test <- rsample::assessment(split)
  expect_equal(train$time, 1:6)
  expect_equal(test$time, 7:8)
  rec <- recipes::recipe(~., data = train) |>
    step_epi_lags(cases, lag = 1) |>
    recipes::prep()
  # Only the first assessment lag uses training history; the second requires
  # observing the first assessment outcome and is not a two-step forecast.
  baked <- epi_bake_history(test, rec, history = train, time = time)
  expect_equal(baked$lag1_cases, c(32, 64))
  spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights = 1)
  fit <- parsnip::fit(spec, cases ~ time, data = train)
  point <- predict(fit, new_data = test)$.pred
  expect_equal(point, c(64, 128))
  expect_equal(generics::glance(fit$fit)$nobs, 6)
  set.seed(13)
  simulated <- epi_renewal_forecast(train, cases, weights = 1, horizon = 2, rt = fit$fit$estimate, nsim = 200, conf_level = .9)
  evaluated <- data.frame(observed = test$cases, median = simulated$median, low = simulated$lower, high = simulated$upper)
  m <- wis_metric(evaluated, low, high, alpha = .1)
  result <- yardstick::metric_set(yardstick::rmse, m)(evaluated, truth = observed, estimate = median)
  expect_equal(result$.metric, c("rmse", "wis"))
  expect_true(all(is.finite(result$.estimate)))
})
test_that("case aggregation, reproduction and plotting work end to end", {
  dates <- rep(as.Date("2024-01-01") + 0:3, times = c(1, 2, 4, 8))
  cases <- epi_linelist(data.frame(onset = dates), metadata = list(source = "integration"))
  curve <- epi_epicurve(cases, onset)
  expect_equal(curve$cases, c(1L, 2L, 4L, 8L))
  rt <- epi_rt(curve, cases, weights = 1)
  expect_equal(rt$rt, c(NA, 2, 2, 2))
  graph <- ggplot2::autoplot(epi_ts(data.frame(time = curve$date, rt = rt$rt)), type = "rt")
  expect_s3_class(graph, "ggplot")
})
