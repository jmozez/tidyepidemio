#' Prospective Poisson surveillance threshold
#'
#' Uses a trailing window of preceding counts to estimate a constant Poisson
#' mean and flags the current count if it exceeds the `(1-alpha)` Poisson
#' quantile. This is a simple screening rule, not a validated outbreak detection
#' system: it ignores seasonality, trends, reporting delays and changes in
#' population. With `family = "negbin"`, a negative binomial null is used whose
#' dispersion is estimated by moments from the same window (Poisson when the
#' window variance does not exceed its mean); short windows give unstable
#' dispersion. Each screened row gets an upper-tail p-value, and `adjust` applies
#' [stats::p.adjust()] across all screened rows. Flags are not outbreak diagnoses.
#' @param .data An ungrouped data frame in chronological order at regular intervals.
#' @param cases Non-negative integer counts.
#' @param window Number of preceding observations in the baseline.
#' @param alpha Nominal upper-tail probability, strictly between zero and one.
#' @param family Null count model: `"poisson"` or `"negbin"`.
#' @param adjust Multiple-testing adjustment passed to [stats::p.adjust()].
#' @return Input tibble with baseline mean, threshold, p-value, adjusted p-value
#'   and logical alert columns.
#'   These are `NA` for the first `window` rows.
#' @examples
#' d <- data.frame(day = 1:6, cases = c(1, 2, 1, 2, 1, 10))
#' epi_surveillance(d, cases, window = 3, alpha = 0.05)
#' @export
epi_surveillance <- function(
  .data,
  cases,
  window = 4L,
  alpha = 0.05,
  family = c("poisson", "negbin"),
  adjust = "none"
) tep_tag("surveillance", {
  family <- match.arg(family)
  adjust <- match.arg(adjust, stats::p.adjust.methods)
  check_data(.data)
  check_window(window, "window")
  check_scalar(alpha, "alpha")
  if (alpha >= 1) cli::cli_abort("{.arg alpha} must be less than one.")
  y <- column(.data, rlang::enquo(cases), "cases")
  check_nonnegative(y, "cases")
  if (any(y != floor(y))) cli::cli_abort("Counts must be integers.")
  cols <- c("baseline_mean", "threshold", "p_value", "p_adjusted", "alert")
  if (any(cols %in% names(.data))) {
    cli::cli_abort("Output columns already exist; rename them before analysis.")
  }
  n <- length(y)
  size <- rep(Inf, n)
  mw <- moving_window_cpp(as.double(y), as.integer(window))
  mu <- mw$mean
  if (family == "negbin") {
    over <- !is.na(mu) & mu > 0 & mw$var > mu
    size[over] <- mu[over]^2 / (mw$var[over] - mu[over])
  }
  cut <- rep(NA_real_, n)
  ok <- !is.na(mu)
  cut[ok] <- surveillance_quantile(alpha, mu[ok], size[ok])
  tail <- surveillance_tail(y, mu, size, adjust)
  out <- tibble::as_tibble(.data)
  out$baseline_mean <- mu
  out$threshold <- cut
  out$p_value <- tail$p
  out$p_adjusted <- tail$adjusted
  out$alert <- tail$adjusted <= alpha
  out
})
#' Count neighboring locations within a distance
#'
#' Computes pairwise Euclidean distances for projected planar coordinates; it
#' does not handle longitude/latitude, edge correction, statistical inference,
#' clustering, or area-level disease risk. Distances and radius must share units.
#' Self-neighbors are excluded, but distinct rows at the same coordinates count
#' as neighbors. Runtime and memory scale quadratically with row count.
#' @param .data A data frame of locations.
#' @param x,y Numeric projected coordinates, without missing values.
#' @param radius Non-negative distance threshold in coordinate units.
#' @return Input tibble with an integer `neighbors` column.
#' @examples
#' epi_spatial_neighbors(data.frame(x = c(0, 1, 5), y = c(0, 0, 0)), x, y, radius = 1)
#' @export
epi_spatial_neighbors <- function(.data, x, y, radius) {
  check_data(.data)
  check_scalar(radius, "radius", inclusive = TRUE)
  a <- column(.data, rlang::enquo(x), "x")
  b <- column(.data, rlang::enquo(y), "y")
  if (!is.numeric(a) ||
    !is.numeric(b) ||
    anyNA(a) ||
    anyNA(b) ||
    any(!is.finite(a)) ||
    any(!is.finite(b))) {
    cli::cli_abort("Coordinates must be finite numeric vectors without missing values.")
  }
  if ("neighbors" %in% names(.data)) cli::cli_abort("The {.field neighbors} column already exists.")
  n <- length(a)
  if (n > 10000) cli::cli_abort("At most 10000 locations are supported by the quadratic algorithm.")
  counts <- integer(n)
  if (n > 1) {
    for (i in seq_len(n)) counts[i] <- sum(sqrt((a - a[i])^2 + (b - b[i])^2) <= radius) - 1L
  }
  out <- tibble::as_tibble(.data)
  out$neighbors <- counts
  out
}
