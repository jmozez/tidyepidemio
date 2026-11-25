test_that("IPW estimates match independent weight and risk calculations", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:10); d$y<-as.integer(d$rep<=2+d$e+(d$age%%2))
 z<-epi_ipw(d,e,y,adjust=age); weighted<-epi_propensity_weights(d,e,adjust=age); ref<-epi_weighted_effect(weighted,e,y,ipw)
 expect_equal(z$estimate,c(ref$risk_unexposed,ref$risk_exposed,ref$risk_difference,ref$risk_ratio)); expect_equal(z$ess_exposed[1],ref$ess_exposed); expect_true(all(is.na(z$conf_low)))
 z2<-epi_ipw(d,e,y,adjust=age,stabilized=FALSE); expect_equal(z2$estimate,z$estimate); expect_equal(z2$max_weight[1],2*z$max_weight[1],tolerance=1e-6)
 expect_error(epi_ipw(d,e,y,adjust=e),"exclude"); expect_error(epi_ipw(d,e,y,bootstrap=10),"100 to 2000")
})
test_that("IPW bootstrap refits and is reproducible", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:12); d$y<-as.integer(d$rep<=2+d$e+(d$age%%2))
 set.seed(7); a<-epi_ipw(d,e,y,adjust=age,bootstrap=100); set.seed(7); b<-epi_ipw(d,e,y,adjust=age,bootstrap=100)
 expect_equal(a,b); expect_equal(a$bootstrap_success,rep(100L,4)); expect_true(all(a$conf_low<=a$conf_high))
})
test_that("excess bootstrap failures stop inference", {
 d<-data.frame(e=c(0,0,1,1),y=c(0,1,0,1)); set.seed(3); expect_error(epi_ipw(d,e,y,bootstrap=100),"intervals are not reported")
})
