# One-off maintenance script, companion to wrap-long-lines.R: put one argument
# per line in long function signatures of the form `name <- function(...) {`.
# Each file must re-parse to identical expressions or it is left unchanged.
# Remaining long lines (message strings, long expressions inside multi-line
# code) get an explicit lintr exemption so exceptions stay visible.
WIDTH <- 120L
sig_re <- "^( *)([A-Za-z_.][A-Za-z0-9_.]*) <- function\\((.*)\\) \\{$"

wrap_signatures <- function(f) {
  lines <- readLines(f, warn = FALSE)
  out <- character(0)
  for (line in lines) {
    m <- regmatches(line, regexec(sig_re, line))[[1L]]
    if (nchar(line) > WIDTH && length(m)) {
      fn <- tryCatch(str2lang(paste0("function(", m[4L], ") NULL")), error = function(e) NULL)
      if (!is.null(fn)) {
        fm <- fn[[2L]]
        args <- vapply(names(fm), function(n) {
          if (identical(fm[[n]], quote(expr = ))) return(n)
          paste(n, "=", paste(deparse(fm[[n]], width.cutoff = 500L), collapse = " "))
        }, character(1), USE.NAMES = FALSE)
        args[-length(args)] <- paste0(args[-length(args)], ",")
        out <- c(out, paste0(m[2L], m[3L], " <- function("), paste0(m[2L], "    ", args), paste0(m[2L], ") {"))
        next
      }
    }
    out <- c(out, line)
  }
  original <- parse(f, keep.source = FALSE)
  tmp <- tempfile(fileext = ".R")
  writeLines(out, tmp)
  rewritten <- tryCatch(parse(tmp, keep.source = FALSE), error = function(e) NULL)
  if (is.null(rewritten) || !identical(as.list(original), as.list(rewritten))) {
    message("Skipped (parse tree changed): ", f)
    return(invisible(FALSE))
  }
  writeLines(out, f)
  invisible(TRUE)
}

exempt_long_lines <- function(f) {
  lines <- readLines(f, warn = FALSE)
  long <- nchar(lines) > WIDTH & !grepl("^ *#", lines) & !grepl("nolint", lines, fixed = TRUE)
  if (!any(long)) return(invisible(0L))
  # A trailing comment is only safe where the line does not end inside a string.
  ok <- long & !grepl("\"[^\"]*$", sub("\"[^\"]*\"", "", lines))
  lines[ok] <- paste0(lines[ok], " # nolint: line_length_linter.")
  writeLines(lines, f)
  invisible(sum(ok))
}

files <- setdiff(c(list.files("R", "[.]R$", full.names = TRUE),
                   list.files("tests/testthat", "^test.*[.]R$", full.names = TRUE)),
                 "R/RcppExports.R")
invisible(lapply(files, wrap_signatures))
cat("lines exempted:", sum(unlist(lapply(files, exempt_long_lines))), "\n")
