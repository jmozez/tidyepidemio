test_that("standardization and Mantel-Haenszel are correct", {
 d <- data.frame(a=c(10,20),n=c(100,100),s=c(150,50))
 expect_equal(epi_standardize(d,a,n,s)$estimate,0.125)
 expect_equal(epi_standardize(data.frame(a=c(10,20),n=c(100,100),s=c(.1,.1)),a,n,s,method="indirect")$estimate,1.5)
 x <- data.frame(e=rep(c(0,0,1,1),2),y=rep(c(0,1,0,1),2),s=rep(1:2,each=4))
 expect_equal(epi_mantel_haenszel(x,e,y,s)$estimate,1)
 expect_error(epi_standardize(d,a,n,s,method="direct",multiplier=0),"multiplier")
})
test_that("Mantel-Haenszel cell products do not overflow", {
 d<-data.frame(e=rep(0:1,each=100000),y=c(rep(1,60000),rep(0,40000),rep(1,40000),rep(0,60000)),stratum=1)
 expect_equal(epi_mantel_haenszel(d,e,y,stratum)$estimate,4/9)
})
