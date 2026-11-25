# Synthetic predictions only. Independent validation and clinical assessment are
# essential before use. AUC bootstrap holds the model and scores fixed.
library(tidyepidemio)
d <- data.frame(
  y = rep(0:1, each = 8),
  risk = c(
    .05, .15, .20, .25, .35, .45, .60, .75,
    .20, .30, .40, .50, .60, .70, .80, .95
  )
)
print(epi_diagnostic(d, risk >= .5, y))
print(epi_roc_curve(d, y, risk))
set.seed(42)
print(epi_auc_ci(d, y, risk, bootstrap = 200))
print(epi_decision_curve(d, y, risk, thresholds = c(.25, .5, .75)))
