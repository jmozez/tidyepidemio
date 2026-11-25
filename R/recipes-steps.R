#' Epidemiological recipe steps
#'
#' All steps operate in the current row order, without grouping or sorting, and
#' compute features using only rows supplied to `bake()`. They do not carry
#' history across training and assessment sets; baking a single new row will
#' therefore produce missing lag and rolling features. [epi_bake_history()] can
#' supply explicit prior rows for supported steps. Sort and split data beforehand
#' to avoid future leakage. Existing output names are rejected.
#' @param .data A recipes recipe.
#' @param ... Tidy-selected numeric columns.
#' @param lag Positive integer row lag.
#' @param window Positive integer window size, including the current row.
#' @param denominator A single numeric denominator column, for rates.
#' @param multiplier Positive scaling factor for rates.
#' @param skip Whether to skip the step when baking new data.
#' @param id Unique step identifier.
#' @return An updated recipe. The steps retain their selected original columns.
#' @examples
#' d <- data.frame(cases = 1:5, population = rep(100, 5))
#' rec <- recipes::recipe(~., data = d) |>
#'   step_epi_lags(cases, lag = 1)
#' recipes::bake(recipes::prep(rec), new_data = d)
#' rec2 <- recipes::recipe(~., data = d) |>
#'   step_epi_rolling(cases, window = 2) |>
#'   step_epi_rates(cases, denominator = population)
#' recipes::bake(recipes::prep(rec2), new_data = d)
#' ex <- data.frame(exposure = c(0, 1, 1, 0))
#' rec3 <- recipes::recipe(~., data = ex) |>
#'   step_epi_exposure_window(exposure, window = 2)
#' recipes::bake(recipes::prep(rec3), new_data = ex)
#' @export
step_epi_lags <- function(.data, ..., lag = 1L, skip = FALSE, id = recipes::rand_id("epi_lags")) {
  check_window(lag, "lag")
  add_epi_step(.data, rlang::enquos(...), "lag", lag, NULL, 1, skip, id)
}
#' @rdname step_epi_lags
#' @export
step_epi_rolling <- function(.data, ..., window = 7L, skip = FALSE, id = recipes::rand_id("epi_rolling")) {
  check_window(window, "window")
  add_epi_step(.data, rlang::enquos(...), "rolling", window, NULL, 1, skip, id)
}
#' @rdname step_epi_lags
#' @export
step_epi_rates <- function(.data, ..., denominator, multiplier = 1000, skip = FALSE, id = recipes::rand_id("epi_rates")) {
  check_scalar(multiplier, "multiplier")
  add_epi_step(.data, rlang::enquos(...), "rates", 1L, list(rlang::enquo(denominator)), multiplier, skip, id)
}
#' @rdname step_epi_lags
#' @export
step_epi_exposure_window <- function(.data, ..., window = 7L, skip = FALSE, id = recipes::rand_id("epi_exposure")) {
  check_window(window, "window")
  add_epi_step(.data, rlang::enquos(...), "exposure", window, NULL, 1, skip, id)
}
check_window <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) || x < 1 || x != floor(x) || x > .Machine$integer.max) cli::cli_abort("{.arg {name}} must be a positive integer.")
}
add_epi_step <- function(recipe, terms, kind, window, denominator, multiplier, skip, id) {
  if (!inherits(recipe, "recipe")) cli::cli_abort("{.arg .data} must be a recipes recipe.")
  recipes::add_step(recipe, epi_step_new(terms = terms, kind = kind, window = window, denominator = denominator, multiplier = multiplier, skip = skip, id = id))
}
epi_step_new <- function(terms, kind, window, denominator, multiplier, skip, id, trained = FALSE, columns = NULL, denom_name = NULL) {
  recipes::step(subclass = "epi_features", terms = terms, role = "predictor", trained = trained, kind = kind, window = window, denominator = denominator, multiplier = multiplier, columns = columns, denom_name = denom_name, skip = skip, id = id)
}
#' @export
prep.step_epi_features <- function(x, training, info = NULL, ...) {
  cols <- names(recipes::recipes_eval_select(x$terms, training, info))
  if (!length(cols)) cli::cli_abort("Select at least one column for the epidemiological step.")
  if (any(!vapply(training[cols], is.numeric, logical(1)))) cli::cli_abort("Selected columns must be numeric.")
  den <- NULL
  if (x$kind == "rates") {
    den <- names(recipes::recipes_eval_select(x$denominator, training, info))
    if (length(den) != 1L || !is.numeric(training[[den]])) cli::cli_abort("Select exactly one numeric denominator column.")
  }
  epi_step_new(x$terms, x$kind, x$window, x$denominator, x$multiplier, x$skip, x$id, TRUE, cols, den)
}
#' @export
bake.step_epi_features <- function(object, new_data, ...) {
  need <- unique(c(object$columns, object$denom_name))
  if (!all(need %in% names(new_data))) cli::cli_abort("New data are missing required columns: {paste(setdiff(need,names(new_data)), collapse=', ')}.")
  prefix <- switch(object$kind,
    lag = paste0("lag", object$window, "_"),
    rolling = paste0("roll", object$window, "_"),
    rates = "rate_",
    exposure = paste0("exposure", object$window, "_")
  )
  out_names <- paste0(prefix, object$columns)
  if (any(out_names %in% names(new_data))) cli::cli_abort("Step output column already exists: {paste(intersect(out_names,names(new_data)),collapse=', ')}.")
  for (j in seq_along(object$columns)) {
    v <- new_data[[object$columns[j]]]
    if (!is.numeric(v)) cli::cli_abort("Selected columns must be numeric at bake time.")
    if (object$kind == "lag") result <- dplyr::lag(v, n = object$window)
    if (object$kind %in% c("rolling", "exposure")) {
      if (object$kind == "exposure" && any(!is.na(v) & !v %in% c(0, 1))) cli::cli_abort("Exposure columns must contain 0 or 1.")
      result <- rep(NA_real_, length(v))
      w <- object$window
      if (length(v) >= w) {
        for (i in seq.int(w, length(v))) {
          z <- v[seq.int(i - w + 1, i)]
          result[i] <- if (object$kind == "rolling") mean(z) else sum(z)
        }
      }
    }
    if (object$kind == "rates") {
      den <- new_data[[object$denom_name]]
      if (!is.numeric(den) || any(!is.na(den) & (!is.finite(den) | den <= 0))) cli::cli_abort("Denominators must be positive and finite (or missing).")
      result <- v / den * object$multiplier
    }
    new_data[[out_names[j]]] <- result
  }
  new_data
}
#' @export
print.step_epi_features <- function(x, width = max(20, getOption("width") - 30), ...) {
  cat("Epidemiological ", x$kind, " features", if (x$trained) paste0(" for ", paste(x$columns, collapse = ", ")) else " (untrained)", "\n", sep = "")
  invisible(x)
}
#' @export
tidy.step_epi_features <- function(x, ...) {
  tibble::tibble(terms = if (x$trained) x$columns else vapply(x$terms, rlang::as_label, character(1)), id = x$id)
}
#' @export
required_pkgs.step_epi_features <- function(x, ...) c("recipes", "tidyepidemio")
