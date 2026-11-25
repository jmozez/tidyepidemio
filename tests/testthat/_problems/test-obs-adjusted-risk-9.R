# Extracted from test-obs-adjusted-risk.R:9

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "tidyepidemio", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
d<-expand.grid(e=0:1,age=20:24,rep=1:12)
d$y<-as.integer(d$rep<=2+d$e+(d$age%%2))
d$cluster<-rep(1:60,each=2)
z<-epi_adjusted_risk_ratio(d,e,y,adjust=age,cluster=cluster)
fit<-glm(y~e+age,data=d,family=poisson())
X<-model.matrix(fit)
mu<-fitted(fit)
B<-solve(crossprod(X,X*mu))
U<-rowsum(X*(d$y-mu),d$cluster,reorder=FALSE)
V<-B%*%crossprod(U)%*%B
b<-coef(fit)["e"]
se<-sqrt(V["e","e"])
expect_equal(z$estimate,unname(exp(b)))
expect_equal(z$conf_low,unname(exp(b-qnorm(.975)*se)))
expect_equal(z$clusters,60L)
