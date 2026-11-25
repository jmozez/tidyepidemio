## Submission

This is a new submission.

tidyepidemio provides tidy, data-frame-in, tibble-out tools for descriptive,
analytic and infectious-disease epidemiology. Monte Carlo scan statistics use
small Rcpp kernels; random numbers are drawn in R, so results are reproducible
with `set.seed()`.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments

* Local: Windows 11, R 4.6.2 (`R CMD check --as-cran`, with remote checks)
* GitHub Actions: ubuntu-latest (R release and oldrel-1), macOS-latest
  (R release), windows-latest (R release)

## Data

The bundled datasets are real, published data with redistributable terms;
sources and licenses are documented in each help page and the build scripts
in `data-raw/` (excluded from the build):

* `nz_covid_2020`, `ny_covid_counties_2020`: Johns Hopkins CSSE COVID-19 Data
  Repository (CC BY 4.0).
* `nc_sids`: spData (CC0).
* `flu_boarding_school_1978`, `british_doctors`: published counts from BMJ
  (1978) and Doll and Hill (1966).
