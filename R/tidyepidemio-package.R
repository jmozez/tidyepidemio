#' tidyepidemio: Tidy Epidemiological Tools
#'
#' Methods here are educational and exploratory; validate assumptions and
#' suitability before using results for clinical or public health decisions.
#' @keywords internal
#' @importFrom rlang .data
#' @importFrom yardstick new_numeric_metric new_prob_metric
#' @importFrom ggplot2 autoplot
#' @importFrom recipes prep bake required_pkgs
#' @importFrom generics tidy glance augment
#' @importFrom dplyr dplyr_reconstruct dplyr_row_slice dplyr_col_modify group_by ungroup select group_modify rename rename_with relocate
#' @importFrom vctrs vec_restore vec_ptype2 vec_cast
#' @importFrom splines ns
#' @importFrom Rcpp sourceCpp
#' @useDynLib tidyepidemio, .registration = TRUE
"_PACKAGE"

# Data columns referenced inside model formulas.
utils::globalVariables(c(".w", "id"))
