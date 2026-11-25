test_that("empirical AUC matches independent pairwise concordance with ties", {
  set.seed(7301)
  for (i in seq_len(40)) {
    n0 <- sample(2:12, 1)
    n1 <- sample(2:12, 1)
    controls <- sample(0:5, n0, replace = TRUE)
    cases <- sample(0:5, n1, replace = TRUE)
    d <- data.frame(y = c(rep(0, n0), rep(1, n1)), score = c(controls, cases))
    pair <- outer(cases, controls, "-")
    truth <- mean((pair > 0) + .5 * (pair == 0))
    expect_equal(epi_roc_curve(d, y, score)$auc[1], truth, tolerance = 1e-12)
    expect_equal(epi_roc_curve(d, y, score, direction = "lower")$auc[1], 1 - truth, tolerance = 1e-12)
  }
})
test_that("survival RMST agrees with survival package over varied tied data", {
  set.seed(7302)
  for (i in seq_len(30)) {
    d <- data.frame(t = c(sample(1:10, 19, replace = TRUE), 10), e = sample(0:1, 20, replace = TRUE))
    reference <- summary(survival::survfit(survival::Surv(t, e) ~ 1, data = d), rmean = 10)$table
    result <- epi_rmst(d, t, e, tau = 10)
    expect_equal(result$estimate, unname(reference["rmean"]), tolerance = 1e-10)
    expect_equal(result$std_error, unname(reference["se(rmean)"]), tolerance = 1e-10)
  }
})
test_that("compartment simulations preserve population and seeded reproducibility", {
  initial <- data.frame(S = 975, E = 10, I = 10, R = 5)
  for (model in c("sir", "seir")) {
    for (stochastic in c(FALSE, TRUE)) {
      pars <- list(.data = initial, beta = .4, gamma = .1, steps = 20, model = model, stochastic = stochastic)
      if (model == "seir") pars$sigma <- .2
      set.seed(7303)
      x <- do.call(epi_simulate, pars)
      set.seed(7303)
      y <- do.call(epi_simulate, pars)
      comp <- if (model == "seir") c("S", "E", "I", "R") else c("S", "I", "R")
      expect_equal(x, y)
      expect_equal(rowSums(x[comp]), rep(sum(initial[1, comp]), 21), tolerance = 1e-10)
      expect_true(all(as.matrix(x[comp]) >= 0))
      if (stochastic) expect_true(all(as.matrix(x[comp]) == floor(as.matrix(x[comp]))))
    }
  }
})
