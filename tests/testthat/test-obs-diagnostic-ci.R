test_that("diagnostic intervals match exact binomial calculations", {
 d<-data.frame(t=c(1,1,0,0),y=c(1,0,1,0)); z<-epi_diagnostic_ci(d,t,y,method="exact")
 ref<-binom.test(1,2); expect_equal(z$estimate,rep(.5,4)); expect_equal(z$conf_low,rep(as.numeric(ref$conf.int)[1],4)); expect_equal(z$conf_high,rep(as.numeric(ref$conf.int)[2],4))
 expect_warning(z<-epi_diagnostic_ci(data.frame(t=0,y=0),t,y),"denominators are zero"); expect_true(is.na(z$estimate[1])); expect_equal(z$estimate[2],1)
})
