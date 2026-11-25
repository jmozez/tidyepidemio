test_that("Aalen-Johansen estimator includes competing events and tied censoring", {
 d<-data.frame(t=c(1,2,3,4),status=c(1,2,0,1)); z<-epi_cumulative_incidence(d,t,status)
 expect_equal(z$n_risk,c(4,3,2,1)); expect_equal(z$event_free_survival,c(.75,.5,.5,0))
 expect_equal(z$cumulative_incidence,c(.25,.25,.25,.75))
 ties<-data.frame(t=c(1,1,2),status=c(1,0,2)); z<-epi_cumulative_incidence(ties,t,status)
 expect_equal(z$cumulative_incidence,c(1/3,1/3)); expect_equal(z$event_free_survival,c(2/3,0))
 expect_error(epi_cumulative_incidence(data.frame(t=1,status=-1),t,status),"non-negative")
})
test_that("cumulative incidence supports delayed entry and matches survfit", {
 set.seed(4); n <- 300
 d <- data.frame(entry = runif(n, 0, 2), id = seq_len(n)); d$time <- d$entry + rexp(n, .3)
 d$status <- sample(0:2, n, TRUE, prob = c(.3, .4, .3))
 ci <- epi_cumulative_incidence(d, time, status, cause = 1, entry = entry)
 f <- survival::survfit(survival::Surv(entry, time, factor(status, 0:2)) ~ 1, data = d, id = id)
 m <- match(ci$time, f$time)
 expect_equal(ci$cumulative_incidence, f$pstate[m, 2])
 expect_equal(ci$n_risk, f$n.risk[m, 1])
 expect_equal(ci$conf_low, f$lower[m, 2]); expect_equal(ci$conf_high, f$upper[m, 2])
 expect_error(epi_cumulative_incidence(transform(d, entry = time), time, status, entry = entry), "strictly less")
})
test_that("cumulative incidence limits are NA when the cause never occurs", {
 z <- epi_cumulative_incidence(data.frame(time = 1:3, status = c(0, 2, 0)), time, status, cause = 1)
 expect_true(all(is.na(z$conf_low)))
})
