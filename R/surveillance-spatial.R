#' Prospective Poisson surveillance threshold
#'
#' Uses a trailing window of preceding counts to estimate a constant Poisson
#' mean and flags the current count if it exceeds the `(1-alpha)` Poisson
#' quantile. This is a simple screening rule, not a validated outbreak detection
#' system: it ignores seasonality, trends, overdispersion, reporting delays,
#' changes in population, and multiple testing. Flags are not outbreak diagnoses.
#' @param .data An ungrouped data frame in chronological order at regular intervals.
#' @param cases Non-negative integer counts.
#' @param window Number of preceding observations in the baseline.
#' @param alpha Nominal upper-tail probability, strictly between zero and one.
#' @return Input tibble with baseline mean, threshold, and logical alert columns.
#'   These are `NA` for the first `window` rows.
#' @examples
#' d <- data.frame(day=1:6, cases=c(1,2,1,2,1,10))
#' epi_surveillance(d, cases, window=3, alpha=0.05)
#' @export
epi_surveillance <- function(.data, cases, window=4L, alpha=0.05) {
  check_data(.data); check_window(window,"window"); check_scalar(alpha,"alpha"); if (alpha>=1) cli::cli_abort("{.arg alpha} must be less than one.")
  y<-column(.data,rlang::enquo(cases),"cases"); check_nonnegative(y,"cases"); if (any(y!=floor(y))) cli::cli_abort("Counts must be integers.")
  cols<-c("baseline_mean","threshold","alert"); if (any(cols %in% names(.data))) cli::cli_abort("Output columns already exist; rename them before analysis.")
  n<-length(y); mu<-cut<-rep(NA_real_,n); alert<-rep(NA,n)
  if (n>window) for (i in seq.int(window+1,n)) {mu[i]<-mean(y[seq.int(i-window,i-1)]); cut[i]<-stats::qpois(alpha,mu[i],lower.tail=FALSE); alert[i]<-y[i]>cut[i]}
  out<-tibble::as_tibble(.data); out$baseline_mean<-mu; out$threshold<-cut; out$alert<-alert; out
}
#' Count neighboring locations within a distance
#'
#' Computes pairwise Euclidean distances for projected planar coordinates; it
#' does not handle longitude/latitude, edge correction, statistical inference,
#' clustering, or area-level disease risk. Distances and radius must share units.
#' Self-neighbors are excluded, but distinct rows at the same coordinates count
#' as neighbors. Runtime and memory scale quadratically with row count.
#' @param .data A data frame of locations.
#' @param x,y Numeric projected coordinates, without missing values.
#' @param radius Non-negative distance threshold in coordinate units.
#' @return Input tibble with an integer `neighbors` column.
#' @examples
#' epi_spatial_neighbors(data.frame(x=c(0,1,5),y=c(0,0,0)), x, y, radius=1)
#' @export
epi_spatial_neighbors <- function(.data, x, y, radius) {
  check_data(.data); check_scalar(radius,"radius",inclusive=TRUE); a<-column(.data,rlang::enquo(x),"x"); b<-column(.data,rlang::enquo(y),"y")
  if (!is.numeric(a) || !is.numeric(b) || anyNA(a) || anyNA(b) || any(!is.finite(a)) || any(!is.finite(b))) cli::cli_abort("Coordinates must be finite numeric vectors without missing values.")
  if ("neighbors" %in% names(.data)) cli::cli_abort("The {.field neighbors} column already exists.")
  n<-length(a); if (n>10000) cli::cli_abort("At most 10000 locations are supported by the quadratic algorithm.")
  counts<-integer(n); if (n>1) for (i in seq_len(n)) counts[i]<-sum(sqrt((a-a[i])^2+(b-b[i])^2)<=radius)-1L
  out<-tibble::as_tibble(.data); out$neighbors<-counts; out
}
