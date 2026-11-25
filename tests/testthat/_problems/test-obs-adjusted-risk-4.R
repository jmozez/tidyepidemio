# Extracted from test-obs-adjusted-risk.R:4

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "tidyepidemio", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
d<-expand.grid(e=0:1,age=20:24,rep=1:6)
d$y<-as.integer(d$rep<=1+d$e+(d$age%%2))
z<-epi_adjusted_risk_ratio(d,e,y,adjust=age)
fit<-glm(y~e+age,data=d,family=poisson())
X<-model.matrix(fit)
mu<-fitted(fit)
B<-solve(crossprod(X,X*mu))
scores<-X*(d$y-mu)
V<-B%*%crossprod(scores)%*%B
b<-coef(fit)["e"]
se<-sqrt(V["e","e"])
expect_equal(z$estimate,unname(exp(b)))
expect_equal(z$conf_low,unname(exp(b-qnorm(.975)*se)))
expect_equal(z$conf_high,unname(exp(b+qnorm(.975)*se)))
expect_equal(z$se_type,"HC0")
