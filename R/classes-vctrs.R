#' Create epidemiological tibble subclasses
#'
#' Classes label input data; they do not validate a clinical schema. Metadata is
#' a uniquely named list and is restored after compatible row-preserving dplyr
#' operations. Row-binding a plain table to an epidemiological table is rejected:
#' assign the appropriate class and metadata explicitly before combining.
#' Grouped row-preserving operations also retain metadata and class. Summarise
#' and group_modify can drop them because arbitrary aggregates need not represent
#' individual-level epidemiological tables. Rowwise conversion is not supported
#' for metadata preservation. Joins retain left-hand metadata only.
#' @param .data A data frame.
#' @param metadata A named list of descriptive metadata.
#' @return A tibble subclass with an `epi_metadata` attribute.
#' @examples
#' x <- epi_linelist(data.frame(case = 1:3), metadata = list(source = "clinic"))
#' x[1:2, ]
#' epi_cohort(data.frame(id = 1:3))
#' epi_ts(data.frame(time = 1:3, cases = c(1, 2, 3)))
#' @export
epi_linelist <- function(.data, metadata = list()) new_epi(.data, metadata, "epi_linelist")
#' @rdname epi_linelist
#' @export
epi_cohort <- function(.data, metadata = list()) new_epi(.data, metadata, "epi_cohort")
#' @rdname epi_linelist
#' @export
epi_ts <- function(.data, metadata = list()) new_epi(.data, metadata, "epi_ts")
new_epi <- function(.data, metadata, cls) {
  check_data(.data)
  if (!is.list(metadata) || (length(metadata) && (is.null(names(metadata)) || anyNA(names(metadata)) || any(names(metadata) == "") || anyDuplicated(names(metadata))))) { # nolint: line_length_linter.
    cli::cli_abort("{.arg metadata} must be a list with unique, non-missing, non-empty names.")
  }
  x <- tibble::as_tibble(.data)
  vctrs::new_data_frame(
    x,
    n = nrow(x),
    class = c(cls, "epi_tbl", "tbl_df", "tbl"),
    epi_metadata = metadata
  )
}
#' @export
vec_restore.epi_tbl <- function(x, to, ...) {
  x <- tibble::as_tibble(x)
  vctrs::new_data_frame(
    x,
    n = nrow(x),
    class = class(to)[class(to) != "data.frame"],
    epi_metadata = attr(to, "epi_metadata")
  )
}
#' @export
dplyr_reconstruct.epi_tbl <- function(data, template) vctrs::vec_restore(data, template)
# Combining epidemiological objects with incompatible provenance must never
# silently inherit the first object's metadata.
#' @export
vec_ptype2.epi_tbl.epi_tbl <- function(x, y, ...) {
  if (!identical(class(x)[1], class(y)[1]) ||
    !identical(attr(x, "epi_metadata"), attr(y, "epi_metadata"))) {
    cli::cli_abort(
      "Cannot combine epidemiological tables with different classes or metadata. Harmonize metadata explicitly first."
    )
  }
  result <- vctrs::vec_ptype2(tibble::as_tibble(x), tibble::as_tibble(y), ...)
  new_epi(result, attr(x, "epi_metadata"), class(x)[1])
}
#' @export
vec_cast.epi_tbl.epi_tbl <- function(x, to, ...) {
  if (!identical(class(x)[1], class(to)[1]) ||
    !identical(attr(x, "epi_metadata"), attr(to, "epi_metadata"))) {
    cli::cli_abort("Cannot cast epidemiological tables with different classes or metadata.")
  }
  result <- vctrs::vec_cast(tibble::as_tibble(x), tibble::as_tibble(to), ...)
  new_epi(result, attr(to, "epi_metadata"), class(to)[1])
}

# Mixing raw tables into a provenance-bearing type without an explicit decision
# would falsely attribute the raw records to the metadata of the first input.
epi_reject_plain_combine <- function(x, y, ...) {
  cli::cli_abort(
    "Cannot combine or cast epidemiological tables with plain data frames. Assign class and harmonized metadata explicitly first." # nolint: line_length_linter.
  )
}
