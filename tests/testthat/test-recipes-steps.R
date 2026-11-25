test_that("recipe steps train and bake", {
 d<-data.frame(x=1:5,pop=rep(10,5),exposure=c(0,1,1,0,1))
 rec<-recipes::recipe(~.,data=d) |> step_epi_lags(x,lag=1) |> step_epi_rolling(x,window=2) |> step_epi_rates(x,denominator=pop,multiplier=100) |> step_epi_exposure_window(exposure,window=2)
 prep<-recipes::prep(rec); z<-recipes::bake(prep,new_data=d)
 expect_equal(z$lag1_x,c(NA,1:4)); expect_equal(z$roll2_x,c(NA,1.5,2.5,3.5,4.5)); expect_equal(z$rate_x,10*(1:5)); expect_equal(z$exposure2_exposure,c(NA,1,2,1,1))
 expect_s3_class(generics::tidy(prep$steps[[1]]),"data.frame")
 expect_true("tidyepidemio" %in% recipes::required_pkgs(prep$steps[[1]]))
 expect_error(step_epi_lags(rec,x,lag=0),"positive integer")
})
