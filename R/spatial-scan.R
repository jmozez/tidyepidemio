#' Circular Poisson spatial scan statistic
#'
#' Scans circles centered on observed locations over user-specified radii. Under
#' the null, cases are conditionally multinomial with probabilities proportional
#' to population (a homogeneous Poisson risk). Candidate zones with population
#' fraction exceeding `max_fraction` or containing no population outside are
#' excluded. Only elevated-risk zones are considered. Reports the maximum
#' conditional log likelihood ratio and a global Monte Carlo p-value based on
#' the maximum over the same candidates in each null replicate, using
#' `(1 + number >= observed) / (nsim + 1)`. `nsim=0` omits the p-value.
#'
#' Coordinates must be projected planar coordinates, not longitude/latitude.
#' This basic spatial-only scan assumes cases and population belong to the same
#' period and independent counts, with no confounder adjustment, temporal scan,
#' age standardization, reporting bias correction or edge correction. Population
#' is allocated to point locations, not polygons. Results depend on the candidate
#' radii and centers; cluster selection and reported relative risk are subject
#' to selection bias. A significant p-value is not proof of causation. Run
#' `set.seed()` for reproducible simulation.
#' @param .data Data frame of point locations or area centroids.
#' @param x,y Numeric projected coordinates in the same units as radii.
#' @param cases Non-negative integer case counts per location.
#' @param population Positive population (or exposure) per location.
#' @param radii Positive candidate radii in coordinate units.
#' @param max_fraction Maximum fraction of population inside a candidate circle,
#'   strictly between zero and one.
#' @param nsim Number of conditional Monte Carlo replicates; 0 omits testing.
#' @return One-row tibble with the winning center, radius, inside counts and
#'   exposure, expected count, inside/outside relative risk, log likelihood
#'   ratio and global p-value. If all scores are zero the first candidate wins
#'   arbitrarily. Relative risk is infinite when outside cases are zero.
#' @examples
#' d <- data.frame(x=c(0,1,10,11), y=0, cases=c(8,7,1,1), pop=100)
#' set.seed(1)
#' epi_spatial_scan(d, x, y, cases, pop, radii=c(0.1,1), nsim=19)
#' @export
epi_spatial_scan <- function(.data, x, y, cases, population, radii, max_fraction=0.5, nsim=199L) {
  check_data(.data); a<-column(.data,rlang::enquo(x),"x"); b<-column(.data,rlang::enquo(y),"y"); count<-column(.data,rlang::enquo(cases),"cases"); pop<-column(.data,rlang::enquo(population),"population")
  if (!is.numeric(a) || !is.numeric(b) || anyNA(a) || anyNA(b) || any(!is.finite(a)) || any(!is.finite(b))) cli::cli_abort("Coordinates must be finite numeric projected coordinates.")
  check_nonnegative(count,"cases"); check_nonnegative(pop,"population",positive=TRUE); check_nonnegative(radii,"radii",positive=TRUE); check_probability(max_fraction,"max_fraction")
  if (length(count)<2 || any(count!=floor(count)) || sum(count)==0) cli::cli_abort("At least two locations and a positive total of integer cases are required.")
  if (!is.finite(sum(pop)) || !is.finite(sum(count)) || sum(count) > .Machine$integer.max) cli::cli_abort("Total population must be finite and total cases must not exceed the integer limit.")
  if (!length(radii) || anyDuplicated(radii)) cli::cli_abort("{.arg radii} must be a non-empty vector of distinct radii.")
  if (length(nsim)!=1 || !is.numeric(nsim) || is.na(nsim) || !is.finite(nsim) || nsim<0 || nsim!=floor(nsim) || nsim>100000) cli::cli_abort("{.arg nsim} must be an integer between 0 and 100000.")
  n<-length(count); if (n>1000 || n*length(radii)>20000) cli::cli_abort("At most 1000 locations and 20000 candidate circles are supported.")
  radii<-sort(radii); memberships<-list(); centers<-integer(); candidate_radii<-numeric(); fractions<-numeric(); total_pop<-sum(pop)
  for (i in seq_len(n)) {
    distance<-sqrt((a-a[i])^2+(b-b[i])^2)
    for (r in radii) {
      inside<-distance<=r; fraction<-sum(pop[inside])/total_pop
      if (fraction>0 && fraction<=max_fraction && fraction<1) {memberships[[length(memberships)+1L]]<-inside; centers<-c(centers,i); candidate_radii<-c(candidate_radii,r); fractions<-c(fractions,fraction)}
    }
  }
  if (!length(memberships)) cli::cli_abort("No eligible circles. Adjust {.arg radii} or {.arg max_fraction}.")
  M<-do.call(cbind,memberships); total<-sum(count); expected<-total*fractions
  scan_scores<-function(z) {
    inside<-as.numeric(crossprod(M,z)); outside<-total-inside; scores<-numeric(length(inside)); ok<-inside>expected
    scores[ok]<-inside[ok]*log(inside[ok]/expected[ok]); valid<-ok & outside>0
    scores[valid]<-scores[valid]+outside[valid]*log(outside[valid]/(total-expected[valid])); scores
  }
  scores<-scan_scores(count); best<-which.max(scores); obs<-as.numeric(crossprod(M[,best],count)); outside<-total-obs; inside_pop<-total_pop*fractions[best]
  rr<-if (outside==0) Inf else (obs/inside_pop)/(outside/(total_pop-inside_pop))
  p<-NA_real_; if (nsim>0) {more<-0; for (j in seq_len(nsim)) {sim<-as.numeric(stats::rmultinom(1,size=total,prob=pop)); if (max(scan_scores(sim))>=scores[best]-1e-12) more<-more+1L}; p<-(more+1)/(nsim+1)}
  tibble::tibble(center_x=a[centers[best]], center_y=b[centers[best]], radius=candidate_radii[best], observed=obs, expected=expected[best], population=inside_pop, relative_risk=rr, log_likelihood_ratio=scores[best], p_value=p, simulations=as.integer(nsim), candidates=ncol(M))
}
