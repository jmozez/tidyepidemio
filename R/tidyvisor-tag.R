# Results that tidyvisor can explain carry a class naming what they are
# ("tep_rt", "tep_survival", ...), added in front of their tibble classes, so
# that tidyvisor() and tep_interpret() know which estimator produced them.
tep_tag <- function(kind, x) {
  if (is.data.frame(x) && !inherits(x, "grouped_df")) {
    class(x) <- unique(c(paste0("tep_", kind), class(x)))
  }
  x
}
