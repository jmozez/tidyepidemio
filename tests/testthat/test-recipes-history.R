test_that("explicit history supplies recipe lag and rolling context", {
 d<-data.frame(day=1:7,cases=1:7); train<-d[1:4,]; new<-d[5:7,]
 rec<-recipes::recipe(~.,data=train) |> step_epi_lags(cases,lag=1) |> step_epi_rolling(cases,window=2)
 prep<-recipes::prep(rec); without<-recipes::bake(prep,new_data=new)
 expect_true(is.na(without$lag1_cases[1])); z<-epi_bake_history(new,prep,history=train,time=day)
 expect_equal(z$day,5:7); expect_equal(z$lag1_cases,c(4,5,6)); expect_equal(z$roll2_cases,c(4.5,5.5,6.5))
 expect_error(epi_bake_history(new,rec,history=train,time=day),"prepped")
 expect_error(epi_bake_history(new,prep,history=transform(train,day=day+5),time=day),"preceding")
})
test_that("history bake rejects unsupported or skipped recipe steps", {
 d<-data.frame(day=1:6,x=1:6); train<-d[1:4,]; new<-d[5:6,]
 unsupported<-recipes::recipe(~.,data=train) |> recipes::step_center(x) |> recipes::prep()
 expect_error(epi_bake_history(new,unsupported,train,time=day),"Only trained")
 skipped<-recipes::recipe(~.,data=train) |> step_epi_lags(x,skip=TRUE) |> recipes::prep()
 expect_error(epi_bake_history(new,skipped,train,time=day),"skip = FALSE")
 expect_error(epi_bake_history(new["x"],recipes::prep(recipes::recipe(~.,data=train)),train,time=x),"same unique")
})
