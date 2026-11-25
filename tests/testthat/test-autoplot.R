test_that("time series autoplot returns ggplot", {
 x<-epi_ts(data.frame(time=1:3,cases=1:3))
 expect_s3_class(ggplot2::autoplot(x),"ggplot")
 expect_error(ggplot2::autoplot(epi_ts(data.frame(x=1))),"requires")
})
test_that("epicurves Lexis Rt and forest plots build", {
 x<-epi_linelist(data.frame(onset=as.Date("2020-01-01")+0:2)); expect_s3_class(ggplot2::autoplot(x),"ggplot")
 x<-epi_cohort(data.frame(start_time=1:2,end_time=2:3,start_age=c(10,20))); expect_s3_class(ggplot2::autoplot(x),"ggplot")
 x<-epi_ts(data.frame(time=1:4,rt=c(NA,1,2,1))); expect_s3_class(ggplot2::autoplot(x,type="rt"),"ggplot")
 d<-data.frame(e=rep(0:1,each=4),y=c(0,0,0,1,0,1,1,1)); r<-epi_risk_ratio(d,e,y)
 expect_s3_class(ggplot2::autoplot(r),"ggplot"); expect_equal(generics::tidy(r)$estimate,3); expect_equal(generics::glance(r)$estimate,3)
 expect_no_error(ggplot2::ggplot_build(ggplot2::autoplot(r)))
})
test_that("Rt posterior uncertainty is plotted", {
 d<-data.frame(time=1:6,cases=c(1,2,4,8,16,32)); z<-epi_rt_gamma(d,cases,weights=1,window=2)
 p<-ggplot2::autoplot(epi_ts(z),type="rt"); expect_s3_class(p,"ggplot"); expect_no_error(ggplot2::ggplot_build(p)); expect_equal(length(p$layers),4)
})
