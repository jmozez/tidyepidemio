# British Doctors Study: coronary heart disease deaths and person-years by
# age group and smoking status, 10 years of follow-up of male doctors.
# Source: Doll R, Hill AB (1966). Mortality of British doctors in relation to
# smoking: observations on coronary thrombosis. Natl Cancer Inst Monogr
# 19:205-268; tabulated in Breslow NE, Day NE (1987). Statistical Methods in
# Cancer Research Vol. II, IARC Sci Publ 82. Published counts (facts).
british_doctors <- tibble::tibble(
  age_group = factor(rep(c("35-44", "45-54", "55-64", "65-74", "75-84"), each = 2),
                     levels = c("35-44", "45-54", "55-64", "65-74", "75-84")),
  smoker = rep(c(1L, 0L), 5),
  deaths = c(32L, 2L, 104L, 12L, 206L, 28L, 186L, 28L, 102L, 31L),
  person_years = c(52407, 18790, 43248, 10673, 28612, 5710, 12663, 2585, 5317, 1462)
)
usethis::use_data(british_doctors, overwrite = TRUE)
