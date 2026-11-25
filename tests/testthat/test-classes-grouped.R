test_that("grouped row operations preserve classes, grouping and provenance", {
 for (make in list(epi_linelist,epi_cohort,epi_ts)) {
  x<-make(data.frame(id=1:4,g=c("a","a","b","b"),h=c(1,2,1,2)),list(source="clinic"))
  g<-dplyr::group_by(x,g); cls<-class(x)[1]
  expect_s3_class(g,cls); expect_s3_class(g,"grouped_df")
  results<-list(dplyr::filter(g,id>1),dplyr::slice(g,1),vctrs::vec_slice(g,c(2,4)),
                dplyr::mutate(g,z=id+1),dplyr::mutate(g,g=toupper(g)),
                suppressMessages(dplyr::select(g,id)),dplyr::arrange(g,dplyr::desc(id)),
                dplyr::left_join(g,data.frame(id=1:4,v=1),by="id"),
                dplyr::rename(g,group=g),dplyr::rename_with(g,toupper,g),dplyr::relocate(g,id,.after=g))
  for (z in results) {
   expect_s3_class(z,cls); expect_s3_class(z,"grouped_df"); expect_identical(attr(z,"epi_metadata"),list(source="clinic"))
   expect_equal(sum(lengths(dplyr::group_rows(z))),nrow(z))
  }
  out<-dplyr::ungroup(dplyr::mutate(g,z=id+1)); expect_s3_class(out,cls); expect_false(inherits(out,"grouped_df")); expect_identical(attr(out,"epi_metadata"),list(source="clinic"))
  g2<-dplyr::group_by(g,h,.add=TRUE); g2<-dplyr::ungroup(g2,g); expect_equal(dplyr::group_vars(g2),"h"); expect_s3_class(g2,cls)
  expect_equal(dplyr::ungroup(g2)$id,1:4)
 }
})
test_that("grouped binding refuses incompatible provenance and grouping", {
 x<-epi_linelist(data.frame(id=1:4,g=c("a","a","b","b"),h=c(1,2,1,2)),list(source="a"))
 a<-dplyr::group_by(x,g); b<-dplyr::group_by(epi_linelist(tibble::as_tibble(x),list(source="b")),g)
 different<-dplyr::group_by(epi_cohort(tibble::as_tibble(x),list(source="a")),g)
 other_groups<-dplyr::group_by(x,h)
 expect_error(dplyr::bind_rows(a,b),"different classes, metadata or grouping")
 expect_error(dplyr::bind_rows(a,different),"different classes, metadata or grouping")
 expect_error(dplyr::bind_rows(a,other_groups),"different classes, metadata or grouping")
 expect_error(dplyr::bind_rows(a,x),"grouped epidemiological")
 expect_error(dplyr::bind_rows(a,tibble::as_tibble(x)),"grouped epidemiological")
 plain_grouped<-dplyr::group_by(tibble::as_tibble(x),g)
 expect_error(vctrs::vec_cast(plain_grouped,a),"grouped epidemiological")
 expect_error(vctrs::vec_cast(a,plain_grouped),"grouped epidemiological")
 good<-dplyr::bind_rows(a,a); expect_equal(nrow(good),8); expect_s3_class(good,"epi_linelist")
 expect_equal(vapply(dplyr::group_rows(good),length,integer(1)),c(4L,4L))
})
test_that("grouped analysis is explicitly split and arbitrary outputs are not mislabeled", {
 x<-epi_cohort(data.frame(g=c("a","a","b","b"),e=c(1,0,1,1)),list(source="x")); g<-dplyr::group_by(x,g)
 expect_error(epi_incidence(g,e),"Grouped data")
 out<-dplyr::group_modify(g,~epi_incidence(.x,e)); expect_equal(out$events,c(1,2)); expect_false(inherits(out,"epi_cohort"))
 summary<-dplyr::summarise(g,n=dplyr::n()); expect_false(inherits(summary,"epi_cohort"))
})
test_that("empty factor levels and group membership are handled", {
 x<-epi_ts(data.frame(g=factor(c("a","a","b"),levels=c("a","b","c")),v=1:3),list(source="x"))
 g<-dplyr::group_by(x,g,.drop=FALSE); z<-dplyr::filter(g,v==1)
 expect_identical(dplyr::group_by_drop_default(z),FALSE); expect_equal(length(dplyr::group_rows(z)),3L)
 expect_equal(sum(lengths(dplyr::group_rows(z))),1L); expect_s3_class(z,"epi_ts")
})
test_that("renaming and regrouping keep group keys aligned", {
 x<-epi_ts(data.frame(g=c("a","a","b"),v=1:3),list(source="x"))
 g<-dplyr::group_by(x,g); z<-dplyr::mutate(g,g=toupper(g))
 expect_equal(dplyr::group_keys(z)$g,c("A","B")); expect_equal(dplyr::group_indices(z),c(1L,1L,2L))
 renamed<-dplyr::rename(g,group=g); expect_equal(dplyr::group_vars(renamed),"group")
 changed<-dplyr::rename_with(g,toupper,g); expect_equal(dplyr::group_vars(changed),"G")
 computed<-dplyr::group_by(g,bucket=v%%2,.add=TRUE); expect_equal(dplyr::group_vars(computed),c("g","bucket"))
 expect_equal(dplyr::group_size(computed),c(1L,1L,1L))
})
