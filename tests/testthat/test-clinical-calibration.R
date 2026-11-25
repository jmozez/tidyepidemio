test_that("calibration bins handle boundaries and empty bins", {
 d<-data.frame(y=c(0,0,1,1),p=c(0,.25,.75,1)); z<-epi_calibration(d,y,p,bins=4)
 expect_equal(z$n,c(1L,1L,0L,2L)); expect_equal(z$mean_predicted[c(1,2,4)],c(0,.25,.875)); expect_equal(z$observed_risk[c(1,2,4)],c(0,0,1)); expect_true(is.na(z$conf_low[3]))
 ref<-epi_proportion_ci(data.frame(y=c(1,1)),y); expect_equal(z$conf_low[4],ref$conf_low); expect_equal(z$conf_high[4],ref$conf_high)
 expect_error(epi_calibration(transform(d,p=2),y,p),"probabilities")
})
