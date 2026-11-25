#' Rolling-origin resampling
#'
#' Builds non-overlapping rolling splits. The data must already be ordered
#' by time; rows are not sorted and the optional lag introduces a gap between
#' analysis and assessment sets.
#' @param .data A chronologically sorted data frame.
#' @param initial Number of rows in the initial analysis set.
#' @param assess Number of rows in each assessment set.
#' @param cumulative Whether to use an expanding analysis window.
#' @param skip Number of resamples to skip between retained resamples.
#' @param lag Number of gap rows before each assessment set.
#' @return An `rset` of rolling splits.
#' @examples
#' epi_rolling_origin(data.frame(day = 1:10), initial = 5, assess = 2)
#' @export
epi_rolling_origin <- function(.data, initial = 5, assess = 1, cumulative = TRUE, skip = 0, lag = 0) {
  check_data(.data)
  check_window(initial, "initial")
  check_window(assess, "assess")
  if (!is.logical(cumulative) || length(cumulative) != 1L || is.na(cumulative)) cli::cli_abort("{.arg cumulative} must be TRUE or FALSE.")
  for (x in list(skip = skip, lag = lag)) if (length(x) != 1L || !is.numeric(x) || is.na(x) || !is.finite(x) || x < 0 || x != floor(x)) cli::cli_abort("{.arg skip} and {.arg lag} must be non-negative integers.")
  n <- nrow(.data)
  if (initial + lag + assess > n) cli::cli_abort("Not enough rows for the initial window, lag and assessment window.")
  stops <- seq.int(initial, n - lag - assess, by = skip + 1)
  splits <- lapply(stops, function(stop) {
    start <- if (cumulative) 1 else stop - initial + 1
    rsample::make_splits(list(analysis = seq.int(start, stop), assessment = seq.int(stop + lag + 1, stop + lag + assess)), data = .data)
  })
  rsample::manual_rset(splits, ids = paste0("Slice", seq_along(splits)))
}
#' Group-blocked cross-validation
#'
#' Assigns precomputed spatial block labels to folds. All rows in a block stay
#' together. Optionally exclude analysis observations within a Euclidean
#' distance of any assessment observation; this uses planar coordinates and
#' does not buffer polygon boundaries. Supply projected coordinates, not
#' longitude/latitude. Random block assignment is reproducible with `set.seed()`.
#' Block sizes may differ, and buffering can substantially reduce analysis data.
#' @param .data A data frame.
#' @param block A non-missing column of spatial block labels.
#' @param v Number of folds, at least 2 and no larger than the number of blocks.
#' @param x,y Optional projected coordinate columns, both required for buffering.
#' @param buffer Non-negative distance in coordinate units. A positive value
#'   excludes analysis rows at or within that distance of assessment rows.
#' @return An rsample `rset` with analysis and assessment splits.
#' @examples
#' d <- data.frame(block = rep(1:4, each = 2), value = 1:8)
#' set.seed(1)
#' epi_spatial_cv(d, block, v = 2)
#' @export
epi_spatial_cv <- function(.data, block, v = 5L, x = NULL, y = NULL, buffer = 0) {
  check_data(.data)
  b <- column(.data, rlang::enquo(block), "block")
  if (anyNA(b)) cli::cli_abort("{.arg block} must not contain missing values.")
  ids <- unique(b)
  if (length(v) != 1 || !is.numeric(v) || is.na(v) || !is.finite(v) || v < 2 || v != floor(v) || v > length(ids)) cli::cli_abort("{.arg v} must be an integer between 2 and the number of blocks.")
  assignment <- sample(rep(seq_len(v), length.out = length(ids)))
  f <- assignment[match(b, ids)]
  check_scalar(buffer, "buffer", inclusive = TRUE)
  xq <- rlang::enquo(x)
  yq <- rlang::enquo(y)
  xnull <- rlang::quo_is_null(xq)
  ynull <- rlang::quo_is_null(yq)
  if (xor(xnull, ynull) || (buffer > 0 && (xnull || ynull))) cli::cli_abort("Both {.arg x} and {.arg y} are required for spatial buffering.")
  if (!xnull) {
    xx <- column(.data, xq, "x")
    yy <- column(.data, yq, "y")
    if (!is.numeric(xx) || !is.numeric(yy) || anyNA(xx) || anyNA(yy) || any(!is.finite(xx)) || any(!is.finite(yy))) cli::cli_abort("Coordinates must be finite numeric projected coordinates.")
  }
  splits <- lapply(seq_len(v), function(i) {
    assessment <- which(f == i)
    analysis <- which(f != i)
    if (buffer > 0) {
      keep <- vapply(analysis, function(j) all(sqrt((xx[j] - xx[assessment])^2 + (yy[j] - yy[assessment])^2) > buffer), logical(1))
      analysis <- analysis[keep]
      if (!length(analysis)) cli::cli_abort("Buffer removed every analysis row in fold {i}; reduce {.arg buffer} or change the blocks.")
    }
    rsample::make_splits(list(analysis = analysis, assessment = assessment), data = .data)
  })
  rsample::manual_rset(splits, ids = paste0("Fold", seq_len(v)))
}
