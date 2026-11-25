#' Create square spatial blocks
#'
#' Assigns projected planar coordinates to a fixed square grid of width `size`.
#' The grid is anchored at (`origin_x`, `origin_y`); indices use mathematical
#' floor so points immediately west or south of the origin have index -1.
#' Boundary points belong to the cell on their right or above. Fixed origins
#' ensure consistent assignments across datasets. Input is not transformed or
#' projected; latitude/longitude coordinates must first be converted to an
#' appropriate projected coordinate reference system by the caller.
#'
#' Blocking alone does not guarantee separation between neighboring train and
#' assessment observations. Use an appropriate distance buffer with
#' [epi_spatial_cv()] if the analysis requires separation. Selection of grid
#' size and origin should reflect the study's spatial dependence and deployment
#' domain. Coordinates and grid size share the same units.
#' @param .data A data frame of locations.
#' @param x,y Numeric finite projected coordinate columns.
#' @param size Positive width of each square block.
#' @param origin_x,origin_y Finite numeric coordinates of the grid origin.
#' @return Input tibble with integer `block_x` and `block_y` indices and a
#'   character `block_id` of the form `"x:y"`.
#' @examples
#' d<-data.frame(x=c(-1,0,9,10),y=c(0,0,11,11))
#' epi_spatial_blocks(d,x,y,size=10)
#' @export
epi_spatial_blocks <- function(.data, x, y, size, origin_x=0, origin_y=0) {
  check_data(.data); a<-column(.data,rlang::enquo(x),"x"); b<-column(.data,rlang::enquo(y),"y"); check_scalar(size,"size")
  for (v in list(origin_x,origin_y)) if (!is.numeric(v) || length(v)!=1L || is.na(v) || !is.finite(v)) cli::cli_abort("Grid origins must be finite numeric scalars.")
  if (!is.numeric(a) || !is.numeric(b) || anyNA(a) || anyNA(b) || any(!is.finite(a)) || any(!is.finite(b))) cli::cli_abort("Coordinates must be finite numeric projected coordinates.")
  if (any(c("block_x","block_y","block_id") %in% names(.data))) cli::cli_abort("Output block columns already exist; rename them before creating blocks.")
  ix<-floor((a-origin_x)/size); iy<-floor((b-origin_y)/size)
  if (any(!is.finite(ix)) || any(!is.finite(iy)) || any(abs(ix)>1e9) || any(abs(iy)>1e9)) cli::cli_abort("Block indices exceed the supported range; adjust grid origin or size.")
  out<-tibble::as_tibble(.data); out$block_x<-as.integer(ix); out$block_y<-as.integer(iy); out$block_id<-paste0(out$block_x,":",out$block_y); out
}
