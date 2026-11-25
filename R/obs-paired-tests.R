#' Compare paired diagnostic test sensitivity and specificity
#'
#' Compares two binary tests applied to the same individuals, separately among
#' reference-positive and reference-negative individuals. The differences are
#' test 1 minus test 2 in sensitivity and specificity. An exact two-sided
#' McNemar p-value is computed using a binomial test on discordant pairs; if no
#' pairs are discordant its p-value is one. Each p-value addresses equality of
#' marginal test accuracy for its reference subgroup, not equivalence or
#' non-inferiority. No multiplicity adjustment is applied to the two tests.
#'
#' The reference standard is assumed accurate, subjects are independent and
#' both tests are observed on the same subjects without verification bias. Case
#' and control recruitment, missingness and sample size affect interpretation.
#' This is not a comparison of predictive values or ROC AUCs, and it does not
#' provide confidence intervals or address clustered observations.
#' @param .data An ungrouped data frame with one row per subject.
#' @param test1,test2 Binary paired test results, 1 for positive.
#' @param truth Binary reference status, 1 for disease.
#' @return Two rows, sensitivity and specificity, with paired proportions,
#'   differences, discordant counts and unadjusted exact two-sided p-values.
#'   Discordant counts correspond to test 1 only versus test 2 only being
#'   correct for the relevant subgroup.
#' @examples
#' d<-data.frame(y=rep(0:1,each=5),a=c(0,0,1,0,1,1,1,1,0,0),
#'               b=c(0,1,0,0,1,1,0,1,1,0))
#' epi_paired_diagnostic(d,a,b,y)
#' @export
epi_paired_diagnostic <- function(.data,test1,test2,truth) {
  check_data(.data); a<-check_binary(column(.data,rlang::enquo(test1),"test1"),"test1"); b<-check_binary(column(.data,rlang::enquo(test2),"test2"),"test2"); y<-check_binary(column(.data,rlang::enquo(truth),"truth"),"truth")
  if (!length(y) || length(unique(y))!=2L) cli::cli_abort("Both reference outcome levels must be present.")
  one<-function(group,metric) {
    x<-if (group==1) a[y==group] else 1-a[y==group]; z<-if (group==1) b[y==group] else 1-b[y==group]
    only1<-sum(x==1 & z==0); only2<-sum(x==0 & z==1); discordant<-only1+only2
    p<-if (discordant==0) 1 else stats::binom.test(only1,discordant,p=.5,alternative="two.sided")$p.value
    tibble::tibble(metric=metric,n=length(x),test1=mean(x),test2=mean(z),difference=mean(x)-mean(z),test1_only_correct=only1,test2_only_correct=only2,p_value=p)
  }
  dplyr::bind_rows(one(1,"sensitivity"),one(0,"specificity"))
}
