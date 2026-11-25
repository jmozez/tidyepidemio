test_that("Poisson CUSUM updates prospectively and resets below zero", {
 d<-data.frame(cases=c(0,3,3),base=c(1,1,1)); z<-epi_cusum(d,cases,base,relative_risk=2,threshold=1)
 expect_equal(z$cusum,c(0,3*log(2)-1,2*(3*log(2)-1)))
 expect_equal(z$alert,c(FALSE,TRUE,TRUE)); d$cases[3]<-100
 expect_equal(epi_cusum(d,cases,base,relative_risk=2,threshold=1)$cusum[1:2],z$cusum[1:2])
 expect_error(epi_cusum(d,cases,base,relative_risk=1),"greater than")
 expect_error(epi_cusum(data.frame(cases=1,base=0),cases,base),"positive")
})
