test_that("gamma Rt uses only complete prior lags and the specified prior", {
 d<-data.frame(cases=c(1,2,4,8,16),imports=c(0,0,0,0,0)); z<-epi_rt_gamma(d,cases,weights=1,window=2,prior_shape=1,prior_rate=1)
 expect_true(all(is.na(z$rt_mean[1:2]))); expect_equal(z$infectiousness,c(NA,1,2,4,8))
 expect_equal(z$rt_mean[3],(1+2+4)/(1+1+2)); expect_equal(z$rt_low[3],qgamma(.025,shape=7,rate=4)); expect_equal(z$rt_high[3],qgamma(.975,shape=7,rate=4))
 d<-data.frame(cases=c(0,1,1),imports=c(2,0,0)); z<-epi_rt_gamma(d,cases,1,window=1,imported=imports); expect_equal(z$infectiousness[2],2); expect_equal(z$rt_mean[2],2/3)
 expect_error(epi_rt_gamma(data.frame(cases=c(0,1)),cases,1,window=1),"infectiousness is zero")
})
