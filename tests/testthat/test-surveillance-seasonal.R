test_that("seasonal baseline matches training-only Poisson fit", {
 train<-data.frame(t=1:40,cases=rep(c(4,6,8,6),10)); new<-data.frame(t=41:42,cases=c(20,5))
 z<-epi_seasonal_surveillance(new,t,cases,training=train,period=4)
 fit<-glm(cases~sin(2*pi*t/4)+cos(2*pi*t/4),data=train,family=poisson())
 expect_equal(z$baseline_expected,unname(predict(fit,newdata=new,type="response"))); expect_true(z$alert[1]); expect_false(z$alert[2])
 changed<-transform(new,cases=c(1,100)); expect_equal(epi_seasonal_surveillance(changed,t,cases,training=train,period=4)$baseline_expected,z$baseline_expected)
 expect_error(epi_seasonal_surveillance(new,t,cases,training=transform(train,t=t+10),period=4),"before")
 expect_error(epi_seasonal_surveillance(new,t,cases,training=transform(train,cases=0),period=4),"at least one event")
})
test_that("very small alpha uses stable Poisson upper-tail quantiles", {
 train<-data.frame(t=1:40,cases=rep(c(4,6,8,6),10)); new<-data.frame(t=41:42,cases=c(20,5))
 z<-epi_seasonal_surveillance(new,t,cases,training=train,period=4,alpha=1e-20)
 expect_true(all(is.finite(z$threshold))); expect_equal(z$threshold,qpois(1e-20,z$baseline_expected,lower.tail=FALSE))
})
