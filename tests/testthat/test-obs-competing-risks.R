test_that("Aalen-Johansen estimator includes competing events and tied censoring", {
 d<-data.frame(t=c(1,2,3,4),status=c(1,2,0,1)); z<-epi_cumulative_incidence(d,t,status)
 expect_equal(z$n_risk,c(4,3,2,1)); expect_equal(z$event_free_survival,c(.75,.5,.5,0))
 expect_equal(z$cumulative_incidence,c(.25,.25,.25,.75))
 ties<-data.frame(t=c(1,1,2),status=c(1,0,2)); z<-epi_cumulative_incidence(ties,t,status)
 expect_equal(z$cumulative_incidence,c(1/3,1/3)); expect_equal(z$event_free_survival,c(2/3,0))
 expect_error(epi_cumulative_incidence(data.frame(t=1,status=-1),t,status),"non-negative")
})
