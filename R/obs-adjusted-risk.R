#' Adjusted risk ratio using modified Poisson regression
#'
#' Fits a Poisson log-link model to a binary outcome and reports an exponentiated
#' exposure coefficient with a sandwich-based normal-Wald interval. The sandwich
#' estimator uses uncorrected HC0 independent-observation scores by default, or
#' cluster-summed scores when `cluster` is supplied. There is no small-sample
#' correction and normal inference can be inaccurate with few clusters. Unlike a
#' Poisson mean model for counts, this method uses a robust variance estimator
#' because the outcome is binary. Fitted means can exceed one; a warning is
#' issued and the working model should then be scrutinized.
#'
#' Requires complete data, a correctly specified log risk model, appropriate
#' independence or independent clusters, sufficient overlap and large-sample
#' inference. The result is a covariate-conditional risk ratio, not automatically
#' a causal effect. There is no weighting, imputation, interaction, nonlinear
#' term, small-sample correction, or assessment of confounding assumptions.
#' @param .data An ungrouped data frame, one row per individual.
#' @param exposure Binary 0/1 exposure column.
#' @param outcome Binary 0/1 outcome column.
#' @param adjust Tidy selection of complete numeric, factor or logical covariates.
#' @param cluster Optional complete cluster identifier column. If supplied, all
#'   observations within a cluster may be dependent; distinct clusters are
#'   assumed independent.
#' @param conf_level Confidence level strictly between zero and one.
#' @return An `epi_result` tibble with risk ratio, confidence limits, number of
#'   observations, standard-error type, cluster count and covariate names.
#' @examples
#' d<-expand.grid(e=0:1,age=20:24,rep=1:6)
#' d$y<-as.integer(d$rep <= 1+d$e+(d$age %% 2))
#' epi_adjusted_risk_ratio(d,e,y,adjust=age)
#' @export
epi_adjusted_risk_ratio <- function(.data, exposure, outcome, adjust=c(), cluster=NULL, conf_level=0.95) {
  check_data(.data); check_probability(conf_level,"conf_level")
  eq<-rlang::enquo(exposure); oq<-rlang::enquo(outcome); aq<-rlang::enquo(adjust); cq<-rlang::enquo(cluster)
  one_name<-function(q,what) {n<-names(tidyselect::eval_select(q,.data,allow_rename=FALSE)); if (length(n)!=1L) cli::cli_abort("Select exactly one column for {.arg {what}}."); n}
  en<-one_name(eq,"exposure"); yn<-one_name(oq,"outcome"); if (identical(en,yn)) cli::cli_abort("Exposure and outcome must be distinct columns.")
  e<-check_binary(.data[[en]],"exposure"); y<-check_binary(.data[[yn]],"outcome"); if (length(y)<4 || length(unique(e))<2 || length(unique(y))<2) cli::cli_abort("Both exposure and outcome levels and at least four records are required.")
  selected<-names(tidyselect::eval_select(aq,.data,allow_rename=FALSE)); if (any(selected %in% c(en,yn))) cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  for (nm in selected) {z<-.data[[nm]]; if (anyNA(z) || !(is.numeric(z) || is.factor(z) || is.logical(z)) || (is.numeric(z) && any(!is.finite(z))) || length(unique(z))<2) cli::cli_abort("Adjustment column {.field {nm}} must be complete, numeric, factor, or logical, and have at least two observed values.")}
  group<-NULL; ng<-NA_integer_
  if (!rlang::quo_is_null(cq)) {
    cn<-one_name(cq,"cluster"); group<-.data[[cn]]
    if (anyNA(group) || !(is.character(group) || is.factor(group) || is.numeric(group) || is.logical(group)) || (is.numeric(group) && any(!is.finite(group)))) cli::cli_abort("{.arg cluster} must be a complete character, factor, logical or finite numeric identifier.")
    ng<-length(unique(group)); if (ng<2) cli::cli_abort("At least two independent clusters are required.")
    if (ng<30) cli::cli_warn("Only {ng} clusters are present; uncorrected normal sandwich intervals may be unreliable.")
  }
  frame<-data.frame(.outcome=y,.exposure=e); for (i in seq_along(selected)) frame[[paste0(".cov",i)]]<-.data[[selected[i]]]
  covs<-if (length(selected)) paste0(".cov",seq_along(selected)) else character(); form<-stats::reformulate(c(".exposure",covs),response=".outcome")
  fit<-withCallingHandlers(stats::glm(form,data=frame,family=stats::poisson(link="log")),warning=function(w) {cli::cli_warn("Modified Poisson fitting warning: {conditionMessage(w)}"); invokeRestart("muffleWarning")})
  if (!fit$converged || fit$rank<length(stats::coef(fit)) || anyNA(stats::coef(fit))) cli::cli_abort("The risk model did not converge or is rank-deficient; revise covariates and inspect overlap.")
  X<-stats::model.matrix(fit); mu<-stats::fitted(fit); score<-X*(y-mu)
  if (!is.null(group)) score<-rowsum(score,group=group,reorder=FALSE)
  info<-crossprod(X,X*mu); bread<-tryCatch(solve(info),error=function(e) NULL)
  if (is.null(bread) || any(!is.finite(bread))) cli::cli_abort("The model information matrix is singular; inspect overlap and covariates.")
  variance<-bread %*% crossprod(score) %*% bread; se2<-variance[".exposure",".exposure"]
  if (!is.finite(se2) || se2<0) cli::cli_abort("The sandwich standard error is not estimable.")
  se<-sqrt(se2); beta<-stats::coef(fit)[".exposure"]; z<-stats::qnorm((1+conf_level)/2)
  if (any(mu>1+1e-8)) cli::cli_warn("Some fitted risks exceed one; inspect the log risk model and its predictions.")
  if (se==0 || se>10 || abs(beta)>15) cli::cli_warn("Possible sparse data or separation; Wald inference may be unreliable.")
  new_epi_result(tibble::tibble(measure="adjusted_risk_ratio",estimate=unname(exp(beta)),conf_low=unname(exp(beta-z*se)),conf_high=unname(exp(beta+z*se)),n=length(y),se_type=if (is.null(group)) "HC0" else "cluster_HC0",clusters=ng,adjusted_for=paste(selected,collapse=", ")))
}
