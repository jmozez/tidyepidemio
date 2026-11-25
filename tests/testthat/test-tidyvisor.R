test_that("tep_advise() recommends the estimator for the question", {
  d <- data.frame(exposure = rep(0:1, each = 40), outcome = rep(c(0, 1, 0, 1), c(30, 10, 18, 22)))
  a <- tep_advise(d, exposure = "exposure", outcome = "outcome")
  expect_s3_class(a, "tep_advice")
  expect_identical(a$question, "association")
  expect_true(any(grepl("common outcome", a$checks$meaning)))
  expect_true(any(grepl("epi_risk_ratio(data, exposure, outcome)", a$advice$code, fixed = TRUE)))
  expect_identical(tep_advise(d, cases = "outcome")$question, "outbreak")
  expect_error(tep_advise(d), "question")
})

test_that("results are explained, with advice after the test and for the paper", {
  d <- data.frame(exposure = rep(0:1, each = 40), outcome = rep(c(0, 1, 0, 1), c(30, 10, 18, 22)))
  rr <- tep_interpret(epi_risk_ratio(d, exposure, outcome))
  expect_s3_class(rr, "tep_interpretation")
  expect_match(rr$sections$Result[1], "risk of the outcome is 120% higher")
  expect_match(rr$sections$`After the overall test`[1], "confounding")
  expect_match(rr$sections$`For the paper`[1], "^Results:")
  or <- tep_interpret(epi_odds_ratio(d, exposure, outcome))
  expect_match(or$sections$Result[1], "odds of the outcome are")

  g <- data.frame(day = 1:10, cases = round(exp(0.2 * (1:10))))
  expect_s3_class(epi_doubling_time(g, day, cases), "tep_growth")
  expect_match(tep_interpret(epi_doubling_time(g, day, cases))$sections$`For the paper`[1], "doubling every")

  rt <- epi_rt(data.frame(cases = c(1, 2, 4, 8, 12, 20)), cases, weights = c(0.3, 0.5, 0.2))
  expect_match(tep_interpret(rt)$sections[[1]][2], "Rt above 1")

  dx <- epi_diagnostic(data.frame(test = c(1, 1, 1, 0, 0, 0, 1, 0), truth = c(1, 1, 0, 0, 1, 0, 1, 0)), test, truth)
  expect_true(any(grepl("STARD", tep_interpret(dx)$sections$`For the paper`)))

  sv <- epi_surveillance(data.frame(day = 1:12, cases = c(3, 2, 4, 3, 2, 3, 4, 2, 3, 15, 3, 2)), cases, window = 4)
  expect_match(tep_interpret(sv)$sections$Alerts[1], "of 12 time points")

  dd <- expand.grid(e = 0:1, age = 20:24, rep = 1:6)
  dd$y <- as.integer(dd$rep <= 1 + dd$e + (dd$age %% 2))
  gc <- tep_interpret(epi_gcomp(dd, e, y, adjust = age))
  expect_match(gc$sections$`For the paper`[1], "risk difference was 0.167")

  expect_error(tep_interpret(1:3), "cannot explain")
})
