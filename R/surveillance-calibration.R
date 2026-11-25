#' Monte Carlo calibration of a finite-horizon Poisson CUSUM
#'
#' Simulates independent Poisson counts under externally supplied baseline means
#' and calculates the maximum one-sided CUSUM over the entire monitoring horizon
#' using the same recursion as [epi_cusum()]. The threshold is slightly greater
#' than the `k`th ordered simulated maximum, where
#' `k = ceiling((nsim + 1) * (1 - alpha))`. Under exchangeability of the null
#' simulations and a future null sequence, this strict rank construction controls
#' the marginal probability that its maximum crosses the threshold at at most
#' `(nsim + 1 - k) / (nsim + 1)`, including simulation randomness; ties only make
#' it more conservative. This is not a confidence guarantee conditional on the
#' particular simulated calibration set and is not average run length control.
#'
#' Calibration is valid only if the assumed independent Poisson baseline is a
#' suitable null for the entire horizon. Estimated baselines, serial dependence,
#' overdispersion, multiple series and reporting changes can invalidate it.
#' It does not account for later restarting, changing horizon, or retuning the
#' threshold. Set a seed to reproduce the Monte Carlo result.
#' @param .data A non-empty data frame containing the baseline sequence, one row
#'   per monitoring time step.
#' @param baseline Positive expected count at each monitoring step.
#' @param relative_risk Alternative-to-baseline rate ratio, strictly above one.
#' @param alpha Desired maximum false-alarm probability, strictly in (0,1).
#' @param nsim Number of null trajectories; must be large enough for the rank.
#' @param initial Non-negative CUSUM statistic at the start of each trajectory.
#' @return One-row tibble with `threshold`, `alpha`, `marginal_bound`,
#'   `simulations`, and the number of monitoring `steps`.
#' @examples
#' d<-data.frame(base=rep(2,10))
#' set.seed(1)
#' epi_cusum_calibrate(d,base,relative_risk=2,alpha=.1,nsim=99)
#' @export
epi_cusum_calibrate <- function(.data, baseline, relative_risk=2, alpha=0.05, nsim=999L, initial=0) {
  check_data(.data); mu<-column(.data,rlang::enquo(baseline),"baseline"); check_nonnegative(mu,"baseline",positive=TRUE); check_scalar(relative_risk,"relative_risk",min=1); check_probability(alpha,"alpha"); check_window(nsim,"nsim"); check_scalar(initial,"initial",inclusive=TRUE)
  if (!length(mu)) cli::cli_abort("At least one baseline period is required.")
  if (as.double(nsim)*length(mu)>10000000) cli::cli_abort("At most 10 million simulation steps are supported.")
  k<-ceiling((as.double(nsim)+1)*(1-alpha))
  if (k>nsim) cli::cli_abort("Increase {.arg nsim} so that it is at least 1 / alpha - 1.")
  current<-rep(initial,nsim); maximum<-rep(0,nsim)
  for (m in mu) {current<-pmax(0,current+stats::rpois(nsim,m)*log(relative_risk)-(relative_risk-1)*m); maximum<-pmax(maximum,current)}
  q<-sort(maximum,partial=k)[k]; threshold<-q+1e-12*max(1,abs(q))
  if (!is.finite(threshold)) cli::cli_abort("Calibration produced a non-finite threshold.")
  tibble::tibble(threshold=threshold,alpha=alpha,marginal_bound=(nsim+1-k)/(nsim+1),simulations=as.integer(nsim),steps=length(mu))
}
