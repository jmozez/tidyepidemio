test_that("Kaplan-Meier survival matches risk sets and confidence bounds", {
 d<-data.frame(t=c(1,2,3,4),event=c(1,0,1,0),group=c("a","a","b","b"))
 z<-epi_kaplan_meier(d,t,event); expect_equal(z$n_risk,c(4,3,2,1)); expect_equal(z$n_event,c(1,0,1,0)); expect_equal(z$n_censor,c(0,1,0,1)); expect_equal(z$estimate,c(.75,.75,.375,.375))
 ref<-survival::survfit(survival::Surv(t,event)~1,data=d,conf.type="log-log"); expect_equal(z$conf_low,ref$lower); expect_equal(z$conf_high,ref$upper)
 groups<-epi_kaplan_meier(d,t,event,strata=group); expect_equal(unique(groups$strata),c("a","b")); expect_equal(groups$estimate,c(.5,.5,.5,.5))
 expect_error(epi_kaplan_meier(data.frame(t=1,event=2),t,event),"0/1")
})
