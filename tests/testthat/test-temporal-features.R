test_that("temporal features use explicit earlier context and exclude current values", {
 h<-data.frame(day=1:3,cases=1:3); d<-data.frame(day=4:5,cases=4:5)
 z<-epi_temporal_features(d,cases,time=day,history=h,lag=1,window=2)
 expect_equal(z$lag1_cases,c(3,4)); expect_equal(z$past_mean2_cases,c(2.5,3.5))
 d$cases[2]<-1000; expect_equal(epi_temporal_features(d,cases,time=day,history=h,lag=1,window=2)$past_mean2_cases,z$past_mean2_cases)
 z<-epi_temporal_features(data.frame(day=1:2,cases=1:2),cases,time=day,lag=1,window=2)
 expect_equal(z$lag1_cases,c(NA,1)); expect_true(all(is.na(z$past_mean2_cases)))
})
test_that("history is group-specific and preserves interleaved output", {
 h<-data.frame(g=c("a","b","a","b"),day=c(1,1,2,2),x=c(1,10,2,20)); d<-data.frame(g=c("b","a","b","a"),day=c(3,3,4,4),x=c(30,3,40,4))
 z<-epi_temporal_features(d,x,time=day,group=g,history=h,window=2)
 expect_equal(z$lag1_x,c(20,2,30,3)); expect_equal(z$past_mean2_x,c(15,1.5,25,2.5)); expect_equal(z$g,d$g)
 expect_error(epi_temporal_features(d,x,time=day,group=g,history=transform(h,day=day+3)),"must precede")
 expect_error(epi_temporal_features(d[c(3,2,1,4),],x,time=day,group=g,history=h),"strictly increasing")
})
test_that("missing values propagate and Date time is supported", {
 h<-data.frame(day=as.Date("2024-01-01")+0:1,x=c(NA,2)); d<-data.frame(day=as.Date("2024-01-01")+2:3,x=c(3,4))
 z<-epi_temporal_features(d,x,time=day,history=h,window=2); expect_true(is.na(z$past_mean2_x[1])); expect_equal(z$past_mean2_x[2],2.5)
 expect_error(epi_temporal_features(d,x,time=day,history=transform(h,day=1:2)),"both be numeric")
})
test_that("multiple tidy-selected features are independently transformed", {
 h<-data.frame(day=1:2,a=1:2,b=3:4); d<-data.frame(day=3:4,a=3:4,b=5:6)
 z<-epi_temporal_features(d,c(a,b),time=day,history=h,window=2)
 expect_equal(z$lag1_a,c(2,3)); expect_equal(z$lag1_b,c(4,5)); expect_equal(z$past_mean2_a,c(1.5,2.5)); expect_equal(z$past_mean2_b,c(3.5,4.5))
 expect_error(epi_temporal_features(d,a,time=day,history=h,lag=0),"positive integer")
})
test_that("temporal features match a direct past-only calculation", {
 set.seed(9); h<-data.frame(g=rep(c("a","b"),each=5),day=rep(1:5,2),x=rnorm(10)); d<-data.frame(g=rep(c("a","b"),each=5),day=rep(6:10,2),x=rnorm(10))
 z<-epi_temporal_features(d,x,time=day,group=g,history=h,lag=2,window=3)
 for (j in seq_len(nrow(d))) {
  g<-d$g[j]; past<-c(h$x[h$g==g],d$x[d$g==g & d$day<d$day[j]])
  expect_equal(z$lag2_x[j],tail(past,2)[1]); expect_equal(z$past_mean3_x[j],mean(tail(past,3)))
 }
})
