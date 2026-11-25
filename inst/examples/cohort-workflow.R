# Illustrative synthetic data only: no causal or clinical conclusions.
library(tidyepidemio)

cohort <- data.frame(
  entry = as.Date("2024-01-01") + rep(0, 12),
  exit = as.Date("2024-01-01") + 1:12,
  event = c(1,0,1,0,1,0,1,0,1,0,1,0),
  exposed = rep(0:1, each=6)
)
follow <- cohort |>
  epi_follow_up(entry, exit, event, censor_at=as.Date("2024-01-10"))
print(epi_person_time(follow, event_observed, follow_up, multiplier=100))
print(epi_risk_ratio(follow, exposed, event_observed))
print(epi_kaplan_meier(follow, follow_up, event_observed))
print(epi_survival_risk(follow, follow_up, event_observed, horizons=c(3,6)))
print(epi_rmst(follow, follow_up, event_observed, tau=6))
# Censoring complicates simple risks and risk ratios; these are descriptive.
# Use an appropriate survival or causal analysis for the scientific question.
