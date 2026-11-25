# Illustrative synthetic data only. Assumes observed counts are final, that rows
# are equally spaced, and that the generation interval is known and fixed.
library(tidyepidemio)
cases <- data.frame(onset = rep(as.Date("2024-01-01") + 0:7,
  times = c(1, 2, 3, 5, 8, 12, 17, 24)
))
curve <- epi_epicurve(cases, onset)
series <- data.frame(time = seq_len(nrow(curve)), cases = curve$cases)
split <- epi_rolling_origin(series, initial = 6, assess = 2)$splits[[1]]
train <- rsample::analysis(split)
test <- rsample::assessment(split)
spec <- epi_renewal() |> parsnip::set_engine("tidyepidemio", weights = 1)
fit <- parsnip::fit(spec, cases ~ time, data = train)
print(generics::tidy(fit$fit))
print(predict(fit, new_data = test))
set.seed(42)
forecast <- epi_renewal_forecast(train, cases,
  weights = 1, horizon = nrow(test),
  rt = fit$fit$estimate, nsim = 1000, conf_level = .9
)
validation <- data.frame(
  observed = test$cases, med = forecast$median,
  low = forecast$lower, high = forecast$upper
)
print(wis(validation, observed, med, low, high, alpha = .1))
# Do not use revised counts as if they were available at the historical origin.
