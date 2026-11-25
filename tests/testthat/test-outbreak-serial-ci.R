test_that("serial interval t confidence limits match t.test", {
 d<-data.frame(a=as.Date("2024-01-01")+0:3,b=as.Date("2024-01-01")+c(2,4,5,7)); z<-epi_serial_interval_ci(d,a,b); ref<-t.test(as.numeric(d$b-d$a))
 expect_equal(z$mean_days,unname(ref$estimate)); expect_equal(c(z$conf_low,z$conf_high),as.numeric(ref$conf.int)); expect_equal(z$n,4L)
 expect_error(epi_serial_interval_ci(d[1,],a,b),"two pairs")
})
