test_that("diagnostic measures and zero denominators", {
 d<-data.frame(t=c(1,1,0,0),y=c(1,0,1,0)); z<-epi_diagnostic(d,t,y)
 expect_equal(z$sensitivity,.5); expect_equal(z$specificity,.5); expect_equal(z$youden,0); expect_equal(z$lr_positive,1)
 expect_true(is.na(epi_diagnostic(data.frame(t=0,y=0),t,y)$sensitivity))
})
