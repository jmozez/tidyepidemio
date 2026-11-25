test_that("RMST and Greenwood SE agree with survival reference", {
 d<-data.frame(t=c(1,2,3,4,5,6),e=c(1,0,1,0,1,0)); z<-epi_rmst(d,t,e,tau=5)
 ref<-summary(survival::survfit(survival::Surv(t,e)~1,data=d),rmean=5)$table
 expect_equal(z$estimate,unname(ref["rmean"])); expect_equal(z$std_error,unname(ref["se(rmean)"]))
 expect_equal(z$n_risk,2L); expect_equal(z$events_before_tau,2)
})
test_that("RMST handles time zero, terminal events and censoring", {
 z<-epi_rmst(data.frame(t=c(0,2,3),e=c(1,1,1)),t,e,tau=3)
 expect_equal(z$estimate,5/3); expect_true(is.finite(z$std_error))
 z<-epi_rmst(data.frame(t=c(1,2),e=c(0,0)),t,e,tau=2)
 expect_equal(z$estimate,2); expect_equal(z$std_error,0)
 z<-epi_rmst(data.frame(t=c(0,0,2),e=c(1,1,0)),t,e,tau=2)
 expect_equal(z$estimate,2/3)
 expect_error(epi_rmst(data.frame(t=1,e=1),t,e,tau=2),"maximum")
 expect_error(epi_rmst(data.frame(t=1,e=1),t,e,tau=0),"tau")
})

test_that("RMST handles confidence levels close to one", {
 z<-epi_rmst(data.frame(t=c(1,2),e=c(0,0)),t,e,tau=2,conf_level=1-.Machine$double.eps/2)
 expect_true(is.finite(z$conf_low)); expect_true(is.finite(z$conf_high))
})
test_that("RMST Greenwood matches reference with tied events and censoring", {
 d<-data.frame(t=c(0,1,1,2,2,3,5,5),e=c(1,1,0,1,0,1,0,1))
 for (tau in c(1,2.5,5)) {
  ref<-summary(survival::survfit(survival::Surv(t,e)~1,data=d),rmean=tau)$table
  z<-epi_rmst(d,t,e,tau=tau)
  expect_equal(z$estimate,unname(ref["rmean"])); expect_equal(z$std_error,unname(ref["se(rmean)"]))
 }
})
