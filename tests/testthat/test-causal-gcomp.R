test_that("g-computation agrees with manual standardization", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:8); d$y<-as.integer(d$rep<=1+d$e+(d$age%%2)); fit<-glm(y~e+age,data=d,family=binomial())
 d0<-d;d1<-d;d0$e<-0;d1$e<-1; p0<-mean(predict(fit,newdata=d0,type="response"));p1<-mean(predict(fit,newdata=d1,type="response"))
 z<-epi_gcomp(d,e,y,adjust=age); expect_equal(z$estimate,c(p0,p1,p1-p0,p1/p0)); expect_true(all(is.na(z$conf_low)))
 z0<-epi_gcomp(d,e,y); expect_equal(z0$estimate[1],mean(d$y[d$e==0])); expect_equal(z0$estimate[2],mean(d$y[d$e==1]))
 expect_error(epi_gcomp(d,e,y,adjust=e),"exclude"); expect_error(epi_gcomp(d,e,y,bootstrap=10),"100 to 2000")
})
test_that("bootstrap standardization is reproducible", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:12); d$y<-as.integer(d$rep<=2+d$e+(d$age%%2))
 set.seed(2); a<-epi_gcomp(d,e,y,adjust=age,bootstrap=100); set.seed(2); b<-epi_gcomp(d,e,y,adjust=age,bootstrap=100)
 expect_equal(a,b); expect_true(all(a$conf_low<=a$conf_high)); expect_equal(a$bootstrap_success,rep(100L,4))
})
test_that("unstable bootstrap fits are not silently used", {
 d<-data.frame(e=c(0,0,1,1),y=c(0,1,0,1)); set.seed(1)
 expect_error(epi_gcomp(d,e,y,bootstrap=100),"intervals are not reported")
})
