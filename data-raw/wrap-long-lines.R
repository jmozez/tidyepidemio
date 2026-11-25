# One-off maintenance script: wrap code lines longer than 100 characters.
# Each long line that holds exactly one complete expression is re-printed from
# its parse tree with one argument per line, braced `if` bodies and split
# `||`/`&&` chains. Safety net: every file is re-parsed and its expressions
# must be identical to the original's, otherwise the file is left unchanged.
# Run from the package root, then run styler::style_dir().
WIDTH <- 100L
binary_split <- c("||", "&&", "|", "&")

one_line <- function(e) {
  d <- deparse(e, width.cutoff = 500L)
  if (length(d) == 1L) d else NULL
}

fmt <- function(e, indent) {
  pad <- strrep(" ", indent)
  single <- one_line(e)
  if (!is.null(single) && indent + nchar(single) <= WIDTH) return(single)
  if (!is.call(e)) return(single %||% deparse(e))
  fn <- e[[1L]]
  fname <- if (is.symbol(fn)) as.character(fn) else ""
  if (fname == "{") {
    body <- unlist(lapply(as.list(e)[-1L], function(s) paste0("  ", fmt(s, indent + 2L))))
    return(c("{", body, "}"))
  }
  if (fname == "if") {
    cond <- fmt_cond(e[[2L]], indent + 4L)
    head <- c(paste0("if (", cond[1L]), cond[-1L])
    head[length(head)] <- paste0(head[length(head)], ") {")
    then <- e[[3L]]
    stmts <- if (is.call(then) && identical(then[[1L]], as.name("{"))) as.list(then)[-1L] else list(then)
    out <- c(head, unlist(lapply(stmts, function(s) paste0("  ", fmt(s, indent + 2L)))))
    if (length(e) == 4L) {
      els <- e[[4L]]
      if (is.call(els) && identical(els[[1L]], as.name("if"))) {
        nested <- fmt(els, indent)
        return(c(out, paste0("} else ", nested[1L]), nested[-1L]))
      }
      es <- if (is.call(els) && identical(els[[1L]], as.name("{"))) as.list(els)[-1L] else list(els)
      out <- c(out, "} else {", unlist(lapply(es, function(s) paste0("  ", fmt(s, indent + 2L)))))
    }
    return(c(out, "}"))
  }
  if (fname %in% c("<-", "=") && length(e) == 3L) {
    lhs <- one_line(e[[2L]])
    rhs <- fmt(e[[3L]], indent)
    return(c(paste(lhs, fname, rhs[1L]), rhs[-1L]))
  }
  if (fname %in% c(binary_split, "+") && length(e) == 3L) return(fmt_cond(e, indent))
  if (fname == "for" && length(e) == 4L) {
    body <- e[[4L]]
    stmts <- if (is.call(body) && identical(body[[1L]], as.name("{"))) as.list(body)[-1L] else list(body)
    head <- paste0("for (", as.character(e[[2L]]), " in ", one_line(e[[3L]]) %||% deparse(e[[3L]]), ") {")
    return(c(head, unlist(lapply(stmts, function(s) paste0("  ", fmt(s, indent + 2L)))), "}"))
  }
  if (fname == "function") {
    fm <- e[[2L]]
    args <- vapply(names(fm), function(n) {
      if (identical(fm[[n]], quote(expr = ))) return(n)
      paste(n, "=", one_line(fm[[n]]) %||% deparse(fm[[n]]))
    }, character(1), USE.NAMES = FALSE)
    if (length(args)) args[-length(args)] <- paste0(args[-length(args)], ",")
    body <- e[[3L]]
    stmts <- if (is.call(body) && identical(body[[1L]], as.name("{"))) as.list(body)[-1L] else list(body)
    return(c("function(", paste0("  ", args), ") {",
             unlist(lapply(stmts, function(s) paste0("  ", fmt(s, indent + 2L)))), "}"))
  }
  # Any other operator or special form (arithmetic, `!`, indexing):
  # keep on one line; printing these in call form would change the code.
  if (!is.symbol(fn) || !grepl("^[A-Za-z.][A-Za-z0-9._]*$", fname) ||
    fname %in% c("function", "while", "repeat")) {
    if (!is.symbol(fn) && is.call(fn) && as.character(fn[[1L]]) %in% c("::", ":::")) {
      # namespaced call such as cli::cli_abort(): fall through to argument wrapping
    } else {
      return(single %||% deparse(e, width.cutoff = 80L))
    }
  }
  # Ordinary function call: one argument per line.
  head <- one_line(fn)
  if (is.null(head)) return(single %||% deparse(e))
  args <- as.list(e)[-1L]
  nms <- names(args) %||% rep("", length(args))
  if (!length(args)) return(single)
  lines <- character(0)
  for (i in seq_along(args)) {
    a <- if (identical(args[[i]], quote(expr = ))) "" else fmt(args[[i]], indent + 2L)
    if (nzchar(nms[i])) a[1L] <- paste(nms[i], "=", a[1L])
    if (i < length(args)) a[length(a)] <- paste0(a[length(a)], ",")
    lines <- c(lines, paste0("  ", a))
  }
  c(paste0(head, "("), lines, ")")
}

# Flatten a chain of the same logical operator and put one operand per line.
fmt_cond <- function(e, indent) {
  single <- one_line(e)
  if (!is.null(single) && indent + nchar(single) <= WIDTH) return(single)
  if (!(is.call(e) && as.character(e[[1L]])[1] %in% c(binary_split, "+") && length(e) == 3L)) return(fmt(e, indent))
  op <- as.character(e[[1L]])
  operands <- list()
  walk <- function(x) {
    if (is.call(x) && identical(x[[1L]], as.name(op)) && length(x) == 3L) {
      walk(x[[2L]]); walk(x[[3L]])
    } else operands[[length(operands) + 1L]] <<- x
  }
  walk(e)
  parts <- lapply(operands, fmt, indent = indent)
  out <- character(0)
  for (i in seq_along(parts)) {
    p <- parts[[i]]
    if (i < length(parts)) p[length(p)] <- paste0(p[length(p)], " ", op)
    out <- c(out, if (i == 1L) p else p)
  }
  out
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# `{ x }` with a single statement evaluates exactly like `x`; drop such braces
# so that adding them around an `if` body does not count as a change.
unbrace <- function(e) {
  if (!is.call(e)) return(e)
  if (identical(e[[1L]], as.name("{")) && length(e) == 2L) return(unbrace(e[[2L]]))
  for (i in seq_along(e)) if (!is.null(e[[i]]) && !identical(e[[i]], quote(expr = ))) e[[i]] <- unbrace(e[[i]])
  e
}

wrap_file <- function(f) {
  lines <- readLines(f, warn = FALSE)
  long <- which(nchar(lines) > WIDTH & !grepl("^\\s*#", lines))
  if (!length(long)) return(0L)
  pd <- utils::getParseData(parse(f, keep.source = TRUE))
  exprs <- pd[pd$token == "expr" & pd$line1 == pd$line2, ]
  changed <- 0L
  for (l in rev(long)) {
    line <- lines[l]
    if (grepl("#", line, fixed = TRUE)) next
    first <- regexpr("[^ ]", line)
    cand <- exprs[exprs$line1 == l & exprs$col1 == first & exprs$col2 == nchar(line), ]
    if (!nrow(cand)) next
    e <- tryCatch(str2lang(substr(line, first, nchar(line))), error = function(err) NULL)
    if (is.null(e)) next
    out <- fmt(e, first - 1L)
    if (length(out) < 2L) next
    lines <- append(lines[-l], paste0(strrep(" ", first - 1L), out), after = l - 1L)
    changed <- changed + 1L
  }
  original <- parse(f, keep.source = FALSE)
  tmp <- tempfile(fileext = ".R")
  writeLines(lines, tmp)
  rewritten <- tryCatch(parse(tmp, keep.source = FALSE), error = function(err) NULL)
  if (is.null(rewritten) || !identical(lapply(original, unbrace), lapply(rewritten, unbrace))) {
    message("Skipped (parse tree changed): ", f)
    return(0L)
  }
  writeLines(lines, f)
  changed
}

files <- c(list.files("R", "[.]R$", full.names = TRUE), list.files("tests/testthat", "^test.*[.]R$", full.names = TRUE))
files <- setdiff(files, "R/RcppExports.R")
n <- vapply(files, wrap_file, integer(1))
cat("lines wrapped:", sum(n), "in", sum(n > 0), "files\n")
