# Shared fitting engine for epi_adjusted_odds_ratio(), epi_adjusted_risk_ratio()
# and epi_adjusted_rate_ratio(). Callers validate their own outcome/exposure and
# pass quosures for the optional weights, cluster, modifier and nonlinear terms.

adjusted_one_name <- function(.data, q, what) {
  n <- names(tidyselect::eval_select(q, .data, allow_rename = FALSE))
  if (length(n) != 1L) cli::cli_abort("Select exactly one column for {.arg {what}}.")
  n
}

adjusted_glm <- function(.data, y, e, selected, used, family, measure, conf_level,
                         wq, cq, mq, nq, se_type, offset = NULL, extra = list(),
                         check_fit = NULL, keep_clusters = FALSE) {
  n <- length(y)
  for (nm in selected) {
    z <- .data[[nm]]
    if (anyNA(z) || !(is.numeric(z) || is.factor(z) || is.logical(z)) || (is.numeric(z) && any(!is.finite(z))) || length(unique(z)) < 2) { # nolint: line_length_linter.
      cli::cli_abort(
        "Adjustment column {.field {nm}} must be complete, numeric, factor, or logical, and have at least two observed values." # nolint: line_length_linter.
      )
    }
  }
  # Prior weights
  w <- rep(1, n)
  weighted <- FALSE
  if (!rlang::quo_is_null(wq)) {
    wn <- adjusted_one_name(.data, wq, "weights")
    if (wn %in% c(used, selected)) cli::cli_abort("{.arg weights} must be a separate column.")
    w <- .data[[wn]]
    if (!is.numeric(w) || anyNA(w) || any(!is.finite(w)) || any(w < 0) || !any(w > 0)) {
      cli::cli_abort("{.arg weights} must be finite, non-negative and not all zero.")
    }
    weighted <- TRUE
  }
  # Clusters
  group <- NULL
  ng <- NA_integer_
  if (!rlang::quo_is_null(cq)) {
    cn <- adjusted_one_name(.data, cq, "cluster")
    group <- .data[[cn]]
    if (anyNA(group) || !(is.character(group) || is.factor(group) || is.numeric(group) || is.logical(group)) || (is.numeric(group) && any(!is.finite(group)))) { # nolint: line_length_linter.
      cli::cli_abort(
        "{.arg cluster} must be a complete character, factor, logical or finite numeric identifier."
      )
    }
    ng <- length(unique(group))
    if (ng < 2) cli::cli_abort("At least two independent clusters are required.")
    if (ng < 30) {
      cli::cli_warn("Only {ng} clusters are present; normal sandwich intervals may be unreliable.")
    }
    if (se_type == "model") se_type <- "HC0"
  }
  # Effect modifier
  mod <- NULL
  mname <- NA_character_
  if (!rlang::quo_is_null(mq)) {
    mname <- adjusted_one_name(.data, mq, "modifier")
    if (mname %in% used) {
      cli::cli_abort("{.arg modifier} must differ from the outcome and exposure columns.")
    }
    mod <- .data[[mname]]
    if (anyNA(mod) || !(is.factor(mod) || is.character(mod) || is.logical(mod) || is.numeric(mod))) {
      cli::cli_abort(
        "{.arg modifier} must be a complete factor, character, logical or numeric column."
      )
    }
    mod <- if (is.factor(mod)) droplevels(mod) else factor(mod)
    if (nlevels(mod) < 2 || nlevels(mod) > 10) {
      cli::cli_abort("{.arg modifier} must have between 2 and 10 levels.")
    }
    if (any(tapply(e, mod, function(x) length(unique(x))) < 2)) {
      cli::cli_abort("Every level of {.arg modifier} must contain both exposure groups.")
    }
    selected <- setdiff(selected, mname)
  }
  # Nonlinear (natural spline) terms
  nonlinear <- names(tidyselect::eval_select(nq, .data, allow_rename = FALSE))
  if (length(setdiff(nonlinear, selected))) {
    cli::cli_abort("{.arg nonlinear} columns must also be selected in {.arg adjust}.")
  }
  for (nm in nonlinear) {
    if (!is.numeric(.data[[nm]]) || length(unique(.data[[nm]])) < 5) {
      cli::cli_abort(
        "Nonlinear column {.field {nm}} must be numeric with at least five distinct values."
      )
    }
  }

  frame <- data.frame(.outcome = y, .exposure = e, .w = w)
  terms <- ".exposure"
  for (i in seq_along(selected)) {
    v <- paste0(".cov", i)
    frame[[v]] <- .data[[selected[i]]]
    terms <- c(terms, if (selected[i] %in% nonlinear) sprintf("splines::ns(%s, df = 3)", v) else v)
  }
  if (!is.null(mod)) {
    frame$.mod <- mod
    terms <- c(terms, ".mod", ".exposure:.mod")
  }
  if (!is.null(offset)) {
    frame$.offset <- offset
    terms <- c(terms, "offset(.offset)")
  }
  form <- stats::reformulate(terms, response = ".outcome")
  fam <- if (weighted && family$family == "binomial") {
    stats::quasibinomial()
  } else if (weighted && family$family == "poisson") {
    stats::quasipoisson(link = family$link)
  } else {
    family
  }
  fit <- withCallingHandlers(stats::glm(form, data = frame, family = fam, weights = .w),
    warning = function(cnd) {
      cli::cli_warn("Model fitting warning: {conditionMessage(cnd)}")
      invokeRestart("muffleWarning")
    }
  )
  if (!fit$converged || fit$rank < length(stats::coef(fit)) || anyNA(stats::coef(fit))) {
    cli::cli_abort(
      "The model did not converge or is rank-deficient; revise covariates and inspect overlap."
    )
  }
  X <- stats::model.matrix(fit)
  mu <- stats::fitted(fit)
  p <- ncol(X)
  bread <- tryCatch(solve(crossprod(X, X * fit$weights)), error = function(err) NULL)
  if (is.null(bread) || any(!is.finite(bread))) {
    cli::cli_abort("The model information matrix is singular; inspect overlap and covariates.")
  }
  V <- if (se_type == "model") {
    bread
  } else {
    eta <- fit$linear.predictors
    info <- crossprod(X, X * (w * fam$mu.eta(eta)^2 / fam$variance(mu)))
    bread <- tryCatch(solve(info), error = function(err) NULL)
    if (is.null(bread) || any(!is.finite(bread))) {
      cli::cli_abort("The model information matrix is singular; inspect overlap and covariates.")
    }
    score <- X * (w * (y - mu))
    if (!is.null(group)) score <- rowsum(score, group = group, reorder = FALSE)
    meat <- crossprod(score)
    adj <- if (se_type == "HC1") {
      if (is.null(group)) n / (n - p) else ng / (ng - 1) * (n - 1) / (n - p)
    } else {
      1
    }
    adj * bread %*% meat %*% bread
  }
  dimnames(V) <- list(colnames(X), colnames(X))
  if (!is.null(check_fit)) check_fit(fit, mu)
  beta <- stats::coef(fit)
  z <- stats::qnorm((1 + conf_level) / 2)
  contrast <- function(L) {
    b <- sum(L * beta)
    se <- sqrt(drop(t(L) %*% V %*% L))
    c(b, se)
  }
  base <- stats::setNames(numeric(p), colnames(X))
  base[".exposure"] <- 1
  if (is.null(mod)) {
    est <- list(contrast(base))
    levels_out <- NULL
  } else {
    levels_out <- levels(mod)
    est <- lapply(levels_out, function(lv) {
      L <- base
      nm <- paste0(".exposure:.mod", lv)
      if (nm %in% names(L)) L[nm] <- 1
      contrast(L)
    })
  }
  bs <- vapply(est, `[`, numeric(1), 1)
  ses <- vapply(est, `[`, numeric(1), 2)
  if (any(!is.finite(ses)) || any(ses < 0)) {
    cli::cli_abort("The exposure standard error is not estimable.")
  }
  if (any(ses > 10) || any(abs(bs) > 15)) {
    cli::cli_warn(
      "Possible sparse data or separation; Wald estimates and intervals may be unreliable."
    )
  }
  out <- tibble::tibble(
    measure = measure,
    estimate = unname(exp(bs)),
    conf_low = unname(exp(bs - z * ses)),
    conf_high = unname(exp(bs + z * ses))
  )
  if (!is.null(mod)) {
    ix <- grep("^\\.exposure:\\.mod", names(beta))
    b <- beta[ix]
    v_int <- V[ix, ix, drop = FALSE]
    wald <- tryCatch(drop(t(b) %*% solve(v_int) %*% b), error = function(err) NA_real_)
    out <- tibble::add_column(out, modifier = mname, modifier_level = levels_out, .after = "measure")
    out$interaction_p_value <- stats::pchisq(wald, length(ix), lower.tail = FALSE)
  }
  for (nm in names(extra)) out[[nm]] <- extra[[nm]]
  out$se_type <- if (se_type == "model") "model" else if (is.null(group)) se_type else paste0("cluster_", se_type)
  if (!is.null(group) || keep_clusters) out$clusters <- ng
  if (weighted) out$weighted <- TRUE
  out$adjusted_for <- paste(selected, collapse = ", ")
  new_epi_result(out)
}
