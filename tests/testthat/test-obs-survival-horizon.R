test_that("risk at horizons is right-continuous and matches Kaplan-Meier", {
 d<-data.frame(t=c(1,2,3,4),e=c(1,0,1,0)); z<-epi_survival_risk(d,t,e,horizons=c(0,2,3))
 expect_equal(z$risk,c(0,.25,.625)); expect_equal(z$n_risk,c(4L,3L,2L)); expect_equal(z$conf_low[1],0); expect_equal(z$conf_high[1],0)
 km<-epi_kaplan_meier(d,t,e); expect_equal(z$conf_low[2],1-km$conf_high[2]); expect_equal(z$conf_high[3],1-km$conf_low[3])
 expect_error(epi_survival_risk(d,t,e,horizons=5),"maximum observed")
})
test_that("no events produce zero event risk", {
 d<-data.frame(t=1:3,e=0); z<-epi_survival_risk(d,t,e,horizons=c(0,1,3)); expect_equal(z$risk,c(0,0,0))
})
