#' Confidence interval for a mean serial interval
#'
#' Computes the sample mean and an ordinary Student t confidence interval for
#' paired onset-date differences, in days. Intervals can be negative. The method
#' assumes independent transmission pairs and approximate normality of the
#' sample mean; it does not account for right truncation, interval censoring,
#' epidemic-phase bias, uncertainty in transmission links, or repeated infectors.
#' These limitations can be severe during an ongoing outbreak.
#' @param .data A data frame of transmission pairs.
#' @param infector Non-missing infector onset Date column.
#' @param infectee Non-missing infectee onset Date column.
#' @param conf_level Confidence level strictly between zero and one.
#' @return A one-row tibble with number of pairs, mean and sample standard
#'   deviation in days, confidence limits, and confidence level.
#' @examples
#' d<-data.frame(a=as.Date("2024-01-01")+0:3,b=as.Date("2024-01-01")+c(2,4,5,7))
#' epi_serial_interval_ci(d,a,b)
#' @export
epi_serial_interval_ci <- function(.data, infector, infectee, conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level"); a<-column(.data,rlang::enquo(infector),"infector"); b<-column(.data,rlang::enquo(infectee),"infectee")
  if (!inherits(a,"Date") || !inherits(b,"Date") || length(a)<2 || anyNA(a) || anyNA(b) || any(!is.finite(as.numeric(a))) || any(!is.finite(as.numeric(b))) || any(as.numeric(a)!=floor(as.numeric(a))) || any(as.numeric(b)!=floor(as.numeric(b)))) cli::cli_abort("At least two pairs of finite, non-missing, whole-day Date values are required.")
  d<-as.numeric(b-a); n<-length(d); mn<-mean(d); sd<-stats::sd(d); half<-stats::qt((1+conf_level)/2,df=n-1)*sd/sqrt(n)
  tibble::tibble(n=n,mean_days=mn,sd_days=sd,conf_low=mn-half,conf_high=mn+half,conf_level=conf_level)
}
