#' Covariate-adjusted odds ratio
#'
#' Fits a binomial logistic regression with a binary exposure and selected
#' covariates using maximum likelihood, reporting the exponentiated exposure
#' coefficient with a normal-Wald confidence interval. Categorical covariates
#' must be factors or logicals; continuous covariates enter linearly unless
#' listed in `nonlinear`, in which case they enter as natural cubic splines with
#' three degrees of freedom. This is a conditional odds ratio, not a risk ratio,
#' and can differ from a marginal odds ratio even without confounding. It is not
#' automatically a causal effect.
#'
#' Standard errors are model-based by default. `robust = "HC0"` or `"HC1"`
#' requests sandwich standard errors (HC1 adds the `n / (n - p)` small-sample
#' factor); supplying `cluster` sums scores within clusters and implies a
#' sandwich estimator. Sandwich errors are recommended with `weights`, which are
#' treated as sampling or analytic weights rather than frequency counts.
#'
#' With `modifier`, the model includes an exposure-by-modifier interaction and
#' one row is returned per modifier level, giving the exposure effect within that
#' level, together with a joint Wald p-value for the interaction terms.
#'
#' Complete data, independent observations (or independent clusters), a
#' correctly specified model, adequate overlap and no serious separation are
#' required; sparse data can render estimates and Wald intervals unreliable.
#' Missing data are not handled.
#' @param .data A data frame with one row per individual.
#' @param exposure Binary exposure column, coded 0/1.
#' @param outcome Binary outcome column, coded 0/1.
#' @param adjust Tidy selection of covariate columns, such as `c(age, sex)`;
#'   defaults to none. Each must be numeric, factor, or logical and complete.
#' @param conf_level Confidence level strictly between zero and one.
#' @param weights Optional column of finite, non-negative observation weights.
#' @param cluster Optional complete cluster identifier column. Observations
#'   within a cluster may be dependent; distinct clusters are assumed independent.
#' @param robust Standard-error type: `"model"`, `"HC0"` or `"HC1"`.
#' @param modifier Optional effect-modifier column with 2 to 10 levels; every
#'   level must contain both exposure groups.
#' @param nonlinear Tidy selection of numeric `adjust` columns to model with
#'   natural splines (3 degrees of freedom) instead of linearly.
#' @return An `epi_result` tibble with the exposure odds ratio, confidence
#'   limits, sample size, standard-error type and adjusted covariate names. With
#'   `modifier`, one row per modifier level plus `interaction_p_value`.
#' @examples
#' d <- data.frame(e=rep(0:1,each=20), y=rep(c(0,1,0,0,1),8),
#'                 age=rep(20:29,4), sex=rep(c("f","m"),20))
#' epi_adjusted_odds_ratio(d, e, y, adjust=age)
#' epi_adjusted_odds_ratio(d, e, y, adjust=age, robust="HC1")
#' epi_adjusted_odds_ratio(d, e, y, adjust=age, modifier=sex)
#' @export
epi_adjusted_odds_ratio <- function(.data, exposure, outcome, adjust=c(), conf_level=0.95,
                                    weights=NULL, cluster=NULL, robust=c("model","HC0","HC1"),
                                    modifier=NULL, nonlinear=c()) {
  check_data(.data); check_probability(conf_level,"conf_level"); robust<-match.arg(robust)
  eq<-rlang::enquo(exposure); oq<-rlang::enquo(outcome); aq<-rlang::enquo(adjust)
  ename<-names(tidyselect::eval_select(eq,.data,allow_rename=FALSE)); oname<-names(tidyselect::eval_select(oq,.data,allow_rename=FALSE))
  if (length(ename)!=1 || length(oname)!=1 || identical(ename,oname)) cli::cli_abort("Select distinct single exposure and outcome columns.")
  e<-check_binary(.data[[ename]],"exposure"); y<-check_binary(.data[[oname]],"outcome")
  if (length(e)<4 || length(unique(e))<2 || length(unique(y))<2) cli::cli_abort("Both exposure and outcome levels and at least four records are required.")
  selected<-names(tidyselect::eval_select(aq,.data,allow_rename=FALSE)); if (any(selected %in% c(ename,oname))) cli::cli_abort("Adjustment columns must exclude exposure and outcome.")
  separation<-function(fit,mu) if (any(mu<1e-8 | mu>1-1e-8)) cli::cli_warn("Possible separation or sparse data; Wald estimates and intervals may be unreliable.")
  adjusted_glm(.data,y,e,selected,c(ename,oname),stats::binomial(),"adjusted_odds_ratio",conf_level,
               rlang::enquo(weights),rlang::enquo(cluster),rlang::enquo(modifier),rlang::enquo(nonlinear),robust,
               extra=list(n=length(y)),check_fit=separation)
}
