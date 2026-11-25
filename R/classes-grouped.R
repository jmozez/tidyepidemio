# Grouped epidemiological tables retain the original type and metadata through
# row-preserving dplyr operations. Summaries are not assumed to be line lists,
# cohorts or time series; group_modify delegates to plain grouped data.
epi_group_wrap <- function(x, template) {
  cls <- intersect(class(template), c("epi_linelist", "epi_cohort", "epi_ts"))[1]
  meta <- attr(template, "epi_metadata")
  if (!inherits(x, "grouped_df")) return(new_epi(x, meta, cls))
  attr(x, "epi_metadata") <- meta
  class(x) <- c("grouped_epi_tbl", "grouped_df", cls, "epi_tbl", "tbl_df", "tbl", "data.frame")
  x
}

#' @export
group_by.epi_tbl <- function(.data, ..., .add=FALSE, .drop=dplyr::group_by_drop_default(.data)) epi_group_wrap(NextMethod(), .data)
#' @export
group_by.grouped_epi_tbl <- function(.data, ..., .add=FALSE, .drop=dplyr::group_by_drop_default(.data)) epi_group_wrap(NextMethod(), .data)
#' @export
ungroup.grouped_epi_tbl <- function(x, ...) epi_group_wrap(NextMethod(), x)
#' @export
dplyr_reconstruct.grouped_epi_tbl <- function(data, template) epi_group_wrap(NextMethod(), template)
#' @export
dplyr_row_slice.grouped_epi_tbl <- function(data, i, ..., preserve=FALSE) epi_group_wrap(NextMethod(), data)
#' @export
dplyr_col_modify.grouped_epi_tbl <- function(data, cols) epi_group_wrap(NextMethod(), data)
#' @export
select.grouped_epi_tbl <- function(.data, ...) epi_group_wrap(NextMethod(), .data)
#' @export
`[.grouped_epi_tbl` <- function(x, i, j, ..., drop=FALSE) {
  out <- NextMethod()
  if (is.data.frame(out)) epi_group_wrap(out, x) else out
}
#' @export
vec_restore.grouped_epi_tbl <- function(x, to, ...) {
  vars <- intersect(dplyr::group_vars(to), names(x))
  out <- dplyr::group_by(tibble::as_tibble(x), !!!rlang::syms(vars), .drop=dplyr::group_by_drop_default(to))
  epi_group_wrap(out, to)
}
#' @export
group_modify.grouped_epi_tbl <- function(.data, .f, ..., .keep=FALSE) {
  # A group callback can return arbitrary summaries; its output is not safely
  # asserted to represent the original individual-level epidemiological class.
  plain <- dplyr::group_by(tibble::as_tibble(.data), !!!rlang::syms(dplyr::group_vars(.data)), .drop=dplyr::group_by_drop_default(.data))
  dplyr::group_modify(plain, .f, ..., .keep=.keep)
}

epi_group_compatible <- function(x, y) {
  xclass <- intersect(class(x), c("epi_linelist", "epi_cohort", "epi_ts"))[1]
  yclass <- intersect(class(y), c("epi_linelist", "epi_cohort", "epi_ts"))[1]
  identical(xclass, yclass) && identical(attr(x,"epi_metadata"), attr(y,"epi_metadata")) &&
    identical(dplyr::group_vars(x), dplyr::group_vars(y)) &&
    identical(dplyr::group_by_drop_default(x), dplyr::group_by_drop_default(y))
}
epi_group_assert_compatible <- function(x, y) {
  if (!epi_group_compatible(x, y)) cli::cli_abort("Cannot combine grouped epidemiological tables with different classes, metadata or grouping. Harmonize them explicitly first.")
}
epi_group_ptype2 <- function(x, y, ...) {
  epi_group_assert_compatible(x, y)
  cls <- intersect(class(x), c("epi_linelist", "epi_cohort", "epi_ts"))[1]
  a <- new_epi(tibble::as_tibble(x), attr(x,"epi_metadata"), cls)
  b <- new_epi(tibble::as_tibble(y), attr(y,"epi_metadata"), cls)
  out <- vctrs::vec_ptype2(a, b)
  grouped <- dplyr::group_by(tibble::as_tibble(out), !!!rlang::syms(dplyr::group_vars(x)), .drop=dplyr::group_by_drop_default(x))
  epi_group_wrap(grouped, x)
}
epi_group_cast <- function(x, to, ...) {
  epi_group_assert_compatible(x, to)
  out <- vctrs::vec_cast(tibble::as_tibble(x), tibble::as_tibble(to))
  grouped <- dplyr::group_by(out, !!!rlang::syms(dplyr::group_vars(to)), .drop=dplyr::group_by_drop_default(to))
  epi_group_wrap(grouped, to)
}
epi_group_reject_mixed <- function(x, y, ...) {
  cli::cli_abort("Cannot combine grouped epidemiological tables with plain or ungrouped tables. Explicitly harmonize class, metadata and grouping first.")
}
#' @export
rename.grouped_epi_tbl <- function(.data, ...) epi_group_wrap(NextMethod(), .data)
#' @export
rename_with.grouped_epi_tbl <- function(.data, .fn, .cols=tidyselect::everything(), ...) {
  old_names <- names(.data); group_positions <- match(dplyr::group_vars(.data), old_names)
  out <- dplyr::rename_with(tibble::as_tibble(.data), .fn, {{.cols}}, ...)
  groups <- names(out)[group_positions]
  out <- dplyr::group_by(out, !!!rlang::syms(groups), .drop=dplyr::group_by_drop_default(.data))
  epi_group_wrap(out, .data)
}
#' @export
relocate.grouped_epi_tbl <- function(.data, ..., .before=NULL, .after=NULL) {
  out <- dplyr::relocate(tibble::as_tibble(.data), ..., .before={{.before}}, .after={{.after}})
  out <- dplyr::group_by(out, !!!rlang::syms(dplyr::group_vars(.data)), .drop=dplyr::group_by_drop_default(.data))
  epi_group_wrap(out, .data)
}
