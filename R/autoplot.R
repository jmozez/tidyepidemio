#' Plot epidemiological data and results
#'
#' `epi_ts` plots pre-aggregated `time` and `cases` columns, or `time` and `rt`
#' for `type = "rt"`. The Rt plot also accepts `rt_mean`, `rt_low`, and
#' `rt_high` as produced by `epi_rt_gamma()`. `epi_linelist` bins a Date
#' column named `onset` by day.
#' `epi_cohort` draws Lexis line segments from numeric `start_time`, `end_time`,
#' and `start_age` in the same units. Association results use forest plots.
#' Data are not completed for missing dates. Confidence intervals, when present,
#' are shown on a linear scale. See method documentation for object schemas.
#' @param object An epidemiological tibble or association result.
#' @param type For `epi_ts`, either `"cases"` or `"rt"`.
#' @param ... Unused.
#' @return A ggplot object.
#' @examples
#' x <- epi_ts(data.frame(time=1:4, cases=c(2,4,3,1)))
#' ggplot2::autoplot(x)
#' ggplot2::autoplot(epi_linelist(data.frame(onset=as.Date("2024-01-01")+0:2)))
#' @export
#' @method autoplot epi_ts
autoplot.epi_ts <- function(object, type=c("cases","rt"), ...) {
  type<-match.arg(type)
  if (!"time" %in% names(object)) cli::cli_abort("An {.cls epi_ts} plot requires a {.field time} column.")
  if (type=="cases") {
    if (!"cases" %in% names(object)) cli::cli_abort("An {.cls epi_ts} plot requires a {.field cases} column.")
    check_nonnegative(object$cases,"cases"); ggplot2::ggplot(object, ggplot2::aes(x=.data$time,y=.data$cases)) + ggplot2::geom_col() + ggplot2::labs(x="Time",y="Cases")
  } else {
    col<-if ("rt" %in% names(object)) "rt" else if ("rt_mean" %in% names(object)) "rt_mean" else cli::cli_abort("An Rt plot requires {.field rt} or {.field rt_mean}.")
    val<-object[[col]]; if (!is.numeric(val) || any(!is.na(val) & (!is.finite(val) | val<0))) cli::cli_abort("Rt must be non-negative, finite or missing.")
    data<-tibble::as_tibble(object); data$.epi_rt_plot<-val
    p<-ggplot2::ggplot(data,ggplot2::aes(x=.data$time,y=.data$.epi_rt_plot))+ggplot2::geom_hline(yintercept=1,linetype=2)
    if (col=="rt_mean" && all(c("rt_low","rt_high") %in% names(data))) {
      l<-data$rt_low; h<-data$rt_high
      if (!is.numeric(l) || !is.numeric(h) || any(!is.na(l) & (!is.finite(l) | l<0)) || any(!is.na(h) & (!is.finite(h) | h<0)) || any(l>h,na.rm=TRUE)) cli::cli_abort("Rt limits must be non-negative, ordered, finite or missing.")
      p<-p+ggplot2::geom_ribbon(ggplot2::aes(ymin=.data$rt_low,ymax=.data$rt_high),alpha=.2,na.rm=TRUE)
    }
    p+ggplot2::geom_line(na.rm=TRUE)+ggplot2::geom_point(na.rm=TRUE)+ggplot2::labs(x="Time",y="Effective reproduction number")
  }
}
#' @rdname autoplot.epi_ts
#' @export
#' @method autoplot epi_linelist
autoplot.epi_linelist <- function(object, ...) {
  if (!"onset" %in% names(object) || !inherits(object$onset,"Date") || anyNA(object$onset)) cli::cli_abort("An {.cls epi_linelist} plot requires a non-missing Date column named {.field onset}.")
  ggplot2::ggplot(object,ggplot2::aes(x=.data$onset)) + ggplot2::geom_bar() + ggplot2::labs(x="Onset date",y="Cases")
}
#' @rdname autoplot.epi_ts
#' @export
#' @method autoplot epi_cohort
autoplot.epi_cohort <- function(object, ...) {
  cols<-c("start_time","end_time","start_age"); if (!all(cols %in% names(object))) cli::cli_abort("Lexis plot requires start_time, end_time, and start_age columns.")
  if (any(!vapply(object[cols],is.numeric,logical(1))) || any(!is.finite(as.matrix(object[cols]))) || any(object$start_age<0) || any(object$end_time<object$start_time)) cli::cli_abort("Lexis coordinates must be finite numeric values with non-negative age and end time at or after start time.")
  ggplot2::ggplot(object,ggplot2::aes(x=.data$start_time,xend=.data$end_time,y=.data$start_age,yend=.data$start_age+.data$end_time-.data$start_time))+ggplot2::geom_segment()+ggplot2::labs(x="Time",y="Age")
}
#' @rdname autoplot.epi_ts
#' @export
#' @method autoplot epi_result
autoplot.epi_result <- function(object, ...) {
  ggplot2::ggplot(object,ggplot2::aes(x=.data$estimate,y=.data$measure)) + ggplot2::geom_point(na.rm=TRUE) + ggplot2::geom_errorbar(ggplot2::aes(xmin=.data$conf_low,xmax=.data$conf_high),orientation="y",width=.15,na.rm=TRUE) + ggplot2::labs(x="Estimate",y=NULL)
}
