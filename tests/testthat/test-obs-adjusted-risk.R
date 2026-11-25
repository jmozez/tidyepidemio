test_that("modified Poisson HC0 sandwich matches matrix calculation", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:6); d$y<-as.integer(d$rep<=1+d$e+(d$age%%2))
 z<-epi_adjusted_risk_ratio(d,e,y,adjust=age); fit<-glm(y~e+age,data=d,family=poisson()); X<-model.matrix(fit); mu<-fitted(fit); B<-solve(crossprod(X,X*mu)); scores<-X*(d$y-mu); V<-B%*%crossprod(scores)%*%B; b<-coef(fit)["e"]; se<-sqrt(V["e","e"])
 expect_equal(z$estimate,unname(exp(b))); expect_equal(z$conf_low,unname(exp(b-qnorm(.975)*se))); expect_equal(z$conf_high,unname(exp(b+qnorm(.975)*se))); expect_equal(z$se_type,"HC0")
})
test_that("cluster-summed scores match manual sandwich", {
 d<-expand.grid(e=0:1,age=20:24,rep=1:12); d$y<-as.integer(d$rep<=2+d$e+(d$age%%2)); d$cluster<-rep(1:60,each=2)
 z<-epi_adjusted_risk_ratio(d,e,y,adjust=age,cluster=cluster); fit<-glm(y~e+age,data=d,family=poisson()); X<-model.matrix(fit); mu<-fitted(fit); B<-solve(crossprod(X,X*mu)); U<-rowsum(X*(d$y-mu),d$cluster,reorder=FALSE); V<-B%*%crossprod(U)%*%B; b<-coef(fit)["e"]; se<-sqrt(V["e","e"])
 expect_equal(z$estimate,unname(exp(b))); expect_equal(z$conf_low,unname(exp(b-qnorm(.975)*se))); expect_equal(z$clusters,60L)
 expect_error(epi_adjusted_risk_ratio(transform(d,cluster=1),e,y,cluster=cluster),"two independent clusters")
 expect_error(epi_adjusted_risk_ratio(d,e,y,adjust=e),"exclude")
})
