# Benchmarks of the compiled (Rcpp) kernels against the original pure-R
# implementations kept in tests/testthat/helper-reference-scans.R.
# Run from the package root; writes inst/benchmarks/benchmarks.csv.
# Benchmark the installed, optimised build (load_all() compiles with -O0).
library(tidyepidemio)
# The reference R implementations use package internals, so evaluate them there.
ref <- new.env(parent = asNamespace("tidyepidemio"))
sys.source("tests/testthat/helper-reference-scans.R", envir = ref)
reference_spatial_scan <- ref$reference_spatial_scan
reference_spacetime_scan <- ref$reference_spacetime_scan

reference_surveillance <- function(y, window) {
  n <- length(y)
  mu <- cut <- rep(NA_real_, n)
  for (i in seq.int(window + 1, n)) {
    mu[i] <- mean(y[seq.int(i - window, i - 1)])
    cut[i] <- stats::qpois(0.05, mu[i], lower.tail = FALSE)
  }
  y > cut
}

set.seed(1)
loc <- data.frame(x = runif(400), y = runif(400), pop = rpois(400, 500) + 1)
loc$cases <- rpois(400, loc$pop * 0.01)
st <- data.frame(x = runif(60), y = runif(60), pop = rpois(60, 1000) + 1)
for (t in 1:12) st[[paste0("w", t)]] <- rpois(60, 5)
big <- data.frame(x = runif(400), y = runif(400), pop = rpois(400, 1000) + 1)
for (t in 1:52) big[[paste0("w", t)]] <- rpois(400, 5)
cs <- data.frame(cases = rpois(20000, 50))

cases <- list(
  list(
    task = "Spatial scan (400 locations, 3 radii, 999 simulations)",
    r = quote(reference_spatial_scan(loc, x, y, cases, pop, radii = c(.05, .1, .2), nsim = 999)),
    cpp = quote(epi_spatial_scan(loc, x, y, cases, pop, radii = c(.05, .1, .2), nsim = 999))
  ),
  list(
    task = "Space-time scan (60 locations x 12 weeks, 199 simulations)",
    r = quote(reference_spacetime_scan(st, x, y, w1:w12, pop, radii = c(.15), nsim = 199)),
    cpp = quote(epi_spacetime_scan(st, x, y, w1:w12, pop, radii = c(.15), nsim = 199))
  ),
  list(
    task = "Moving-window screen (20,000 days)",
    r = quote(reference_surveillance(cs$cases, 7L)),
    cpp = quote(epi_surveillance(cs, cases, window = 7))
  )
)

# eval() only runs the benchmark expressions quoted in this script.
time_it <- function(expr, reps = 3) {
  median(vapply(seq_len(reps), function(i) system.time(eval(expr))[["elapsed"]], numeric(1)))
}
res <- do.call(rbind, lapply(cases, function(k) {
  r <- time_it(k$r)
  cpp <- time_it(k$cpp)
  data.frame(task = k$task, r_seconds = r, cpp_seconds = cpp, speedup = round(r / cpp, 1))
}))
print(res)
dir.create("inst/benchmarks", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(res, "inst/benchmarks/benchmarks.csv", row.names = FALSE)

# Beyond the old limits: the R version refused this size outright.
big_time <- time_it(quote(epi_spacetime_scan(big, x, y, w1:w52, pop, radii = c(.05, .1), nsim = 999)), reps = 1)
cat(sprintf("C++ only: space-time scan, 400 locations x 52 weeks, 999 simulations: %.1f s\n", big_time))
