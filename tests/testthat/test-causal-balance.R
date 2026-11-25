test_that("balance uses a fixed unweighted reference denominator", {
 d<-data.frame(e=c(0,0,1,1),age=c(20,30,30,40),w=c(1,2,2,1),sex=factor(c("f","m","f","m")))
 z<-epi_balance(d,e,c(age,sex),weights=w); a<-z[z$covariate=="age",]
 expect_equal(a$reference_sd,sqrt((var(c(20,30))+var(c(30,40)))/2)); expect_equal(a$smd_unweighted,10/a$reference_sd)
 expect_equal(a$weighted_mean_unexposed,80/3); expect_equal(a$weighted_mean_exposed,100/3); expect_equal(a$smd_weighted,(20/3)/a$reference_sd)
 expect_equal(nrow(z),3); expect_equal(z$smd_unweighted[z$covariate=="sex"],c(0,0))
 expect_error(epi_balance(d,e,e),"excluding exposure")
})
test_that("zero reference variance produces undefined SMD", {
 d<-data.frame(e=c(0,0,1,1),x=c(0,0,1,1)); expect_warning(z<-epi_balance(d,e,x),"undefined"); expect_true(is.na(z$smd_unweighted))
})
