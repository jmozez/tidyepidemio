#' Daily COVID-19 cases in New Zealand, first wave 2020
#'
#' Daily confirmed COVID-19 cases in New Zealand from 26 February to 30 June
#' 2020, covering the first wave and its elimination after a national
#' lockdown from 26 March. Daily counts are differences of the cumulative
#' series (negative corrections set to zero).
#'
#' @format A tibble with 126 rows and 2 columns:
#' \describe{
#'   \item{date}{Report date.}
#'   \item{cases}{Newly confirmed cases.}
#' }
#' @source COVID-19 Data Repository by the Center for Systems Science and
#'   Engineering (CSSE) at Johns Hopkins University,
#'   <https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0. Dong E, Du H,
#'   Gardner L (2020). An interactive web-based dashboard to track COVID-19 in
#'   real time. *Lancet Infectious Diseases* 20(5):533-534.
#'   Build script: `data-raw/nz_covid_2020.R`.
#' @examples
#' pre <- subset(nz_covid_2020, cases > 0 &
#'   date >= as.Date("2020-03-15") & date <= as.Date("2020-03-28"))
#' pre$day <- as.numeric(pre$date - min(pre$date))
#' epi_doubling_time(pre, day, cases)
"nz_covid_2020"

#' Weekly COVID-19 cases in New York State counties, spring 2020
#'
#' Weekly confirmed COVID-19 cases for the 62 counties of New York State over
#' the 13 weeks ending 8 March to 31 May 2020, with 2019 population and
#' county centroids. `x_km` and `y_km` are centroids on a local
#' equirectangular projection in kilometers, suitable for the planar scan
#' statistics at state scale.
#'
#' @format A tibble with 62 rows and 20 columns: `county`, `fips`,
#'   `population`, `lon`, `lat`, `x_km`, `y_km`, and weekly case counts
#'   `week_0308` to `week_0531` (named by the week's last day, month and day).
#' @source COVID-19 Data Repository by the Center for Systems Science and
#'   Engineering (CSSE) at Johns Hopkins University,
#'   <https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0.
#'   Build script: `data-raw/ny_covid_counties_2020.R`.
#' @examples
#' head(ny_covid_counties_2020[, c("county", "population", "week_0405")])
"ny_covid_counties_2020"

#' Influenza outbreak in an English boarding school, 1978
#'
#' Number of the 763 boys at a boarding school in northern England who were
#' confined to bed on each day of an influenza A (H1N1) outbreak in January
#' 1978. A classic dataset for fitting the SIR model.
#'
#' @format A tibble with 14 rows and 3 columns:
#' \describe{
#'   \item{date}{Calendar date.}
#'   \item{in_bed}{Pupils confined to bed.}
#'   \item{population}{School population (763).}
#' }
#' @source Anonymous (1978). Influenza in a boarding school. *British Medical
#'   Journal* 1(6112):587. Build script: `data-raw/flu_boarding_school_1978.R`.
"flu_boarding_school_1978"

#' British Doctors Study: smoking and coronary deaths
#'
#' Coronary heart disease deaths and person-years among male British doctors
#' by age group and smoking status over ten years of follow-up, the classic
#' dataset for Poisson rate-ratio regression.
#'
#' @format A tibble with 10 rows and 4 columns:
#' \describe{
#'   \item{age_group}{Age group in years (factor).}
#'   \item{smoker}{1 for smokers, 0 for non-smokers.}
#'   \item{deaths}{Coronary heart disease deaths.}
#'   \item{person_years}{Person-years of follow-up.}
#' }
#' @source Doll R, Hill AB (1966). Mortality of British doctors in relation to
#'   smoking: observations on coronary thrombosis. *National Cancer Institute
#'   Monograph* 19:205-268, as tabulated in Breslow NE, Day NE (1987).
#'   *Statistical Methods in Cancer Research, Volume II*. IARC.
#'   Build script: `data-raw/british_doctors.R`.
#' @examples
#' epi_adjusted_rate_ratio(british_doctors, deaths, person_years, smoker, adjust = age_group)
"british_doctors"

#' Sudden infant death syndrome in North Carolina counties
#'
#' SIDS deaths and live births in the 100 counties of North Carolina for
#' 1974-78 and 1979-84, with county centroids in projected UTM (zone 17)
#' kilometers. The standard benchmark for disease-cluster detection.
#'
#' @format A tibble with 100 rows and 10 columns: `county`, `x_km`, `y_km`,
#'   `lon`, `lat`, `births_1974`, `sids_1974`, `births_1979`, `sids_1979`,
#'   `nonwhite_births_1974`.
#' @source `spData::nc.sids` (CC0), from Cressie N, Chan NH (1989). Spatial
#'   modeling of regional variables. *Journal of the American Statistical
#'   Association* 84:393-401. Build script: `data-raw/nc_sids.R`.
#' @examples
#' epi_spatial_scan(nc_sids, x_km, y_km, sids_1974, births_1974,
#'   radii = c(30, 60), nsim = 99
#' )
"nc_sids"

#' Daily COVID-19 cases and deaths in New Zealand, first wave 2020
#'
#' Daily confirmed COVID-19 cases and deaths in New Zealand from 26 February
#' to 30 June 2020, the same period as [nz_covid_2020], for case fatality
#' analyses with [epi_cfr()]. Daily counts are differences of the cumulative
#' series (negative corrections set to zero). Deaths in this source were
#' mostly added once a week, so use them cumulatively rather than day by day.
#'
#' @format A tibble with 126 rows and 3 columns:
#' \describe{
#'   \item{date}{Report date.}
#'   \item{cases}{Newly confirmed cases.}
#'   \item{deaths}{Newly reported deaths.}
#' }
#' @source COVID-19 Data Repository by the Center for Systems Science and
#'   Engineering (CSSE) at Johns Hopkins University,
#'   <https://github.com/CSSEGISandData/COVID-19>, CC BY 4.0. Dong E, Du H,
#'   Gardner L (2020). An interactive web-based dashboard to track COVID-19 in
#'   real time. *Lancet Infectious Diseases* 20(5):533-534.
#'   Build script: `data-raw/nz_covid_outcomes_2020.R`.
#' @examples
#' colSums(nz_covid_outcomes_2020[c("cases", "deaths")])
"nz_covid_outcomes_2020"
