test_that("direct gamma limits reduce to exact Poisson for equal weights", {
 d<-data.frame(e=c(2,3),n=c(10,10),s=c(10,10)); z<-epi_standardize_ci(d,e,n,s,multiplier=100)
 ref<-stats::poisson.test(5,T=20); expect_equal(z$estimate,unname(ref$estimate)*100)
 expect_equal(c(z$conf_low,z$conf_high),as.numeric(ref$conf.int)*100,tolerance=1e-10)
 zero<-epi_standardize_ci(data.frame(e=c(0,0),n=c(10,10),s=c(10,10)),e,n,s)
 expect_equal(zero$conf_low,0); expect_gt(zero$conf_high,0)
})
test_that("indirect intervals use exact Poisson limits on observed/expected", {
 d<-data.frame(e=c(1,2),n=c(100,100),s=c(.01,.01)); z<-epi_standardize_ci(d,e,n,s,method="indirect",multiplier=100)
 ref<-stats::poisson.test(3,T=2); expect_equal(z$estimate,1.5); expect_equal(c(z$conf_low,z$conf_high),as.numeric(ref$conf.int))
 expect_error(epi_standardize_ci(data.frame(e=1,n=100,s=0),e,n,s,method="indirect"),"Expected")
})
