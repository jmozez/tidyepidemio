test_that("CUSUM calibration is deterministic with seed and has desired rank", {
 d<-data.frame(base=rep(2,10)); set.seed(12); z<-epi_cusum_calibrate(d,base,alpha=.1,nsim=99)
 set.seed(12); expect_equal(z,epi_cusum_calibrate(d,base,alpha=.1,nsim=99)); expect_equal(z$marginal_bound,.1); expect_gt(z$threshold,0)
 expect_error(epi_cusum_calibrate(d,base,alpha=.01,nsim=10),"Increase")
 expect_error(epi_cusum_calibrate(data.frame(base=0),base),"positive")
})
test_that("threshold works with prospective CUSUM", {
 d<-data.frame(base=rep(2,6)); set.seed(3); z<-epi_cusum_calibrate(d,base,alpha=.1,nsim=99)
 series<-data.frame(base=rep(2,6),cases=c(1,1,1,30,1,1)); out<-epi_cusum(series,cases,base,threshold=z$threshold)
 expect_true(any(out$alert)); expect_false(out$alert[1])
})
