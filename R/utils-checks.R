check_data <- function(x) {
  if (!is.data.frame(x)) cli::cli_abort("{.arg .data} must be a data frame.")
  if (inherits(x, "grouped_df")) {
    cli::cli_abort(
      "Grouped data are not supported. Split groups explicitly or use {.fn dplyr::group_modify}."
    )
  }
  invisible(x)
}
check_binary <- function(x, name) {
  if (!(is.logical(x) || is.numeric(x)) || anyNA(x) || any(!x %in% c(0, 1))) {
    cli::cli_abort("{.arg {name}} must contain only non-missing 0/1 or FALSE/TRUE values.")
  }
  as.numeric(x)
}
check_nonnegative <- function(x, name, positive = FALSE) {
  if (!is.numeric(x) || anyNA(x) || any(!is.finite(x)) || any(x < 0) || (positive && any(x <= 0))) {
    cli::cli_abort(
      "{.arg {name}} must contain finite {if (positive) 'positive' else 'non-negative'} numbers without missing values."
    )
  }
  invisible(x)
}
check_scalar <- function(x, name, min = 0, inclusive = FALSE) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || !is.finite(x) || if (inclusive) x < min else x <= min) {
    cli::cli_abort(
      "{.arg {name}} must be a finite number {if (inclusive) 'at least' else 'greater than'} {min}."
    )
  }
  invisible(x)
}
column <- function(data, q, name) {
  x <- rlang::eval_tidy(q, data = data)
  if (length(x) != nrow(data)) cli::cli_abort("{.arg {name}} must have one value per row.")
  x
}
ratio_safe <- function(a, b) if (is.na(a) || is.na(b) || b == 0) NA_real_ else a / b
