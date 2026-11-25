make_adjusted_data <- function() {
 set.seed(2)
 d <- data.frame(e = rbinom(400, 1, .5), age = rnorm(400, 50, 10), sex = sample(c("f","m"), 400, TRUE),
                 cl = rep(1:40, each = 10), w = runif(400, .5, 2))
 d$y <- rbinom(400, 1, plogis(-2 + .7 * d$e + .03 * (d$age - 50)))
 d$t <- runif(400, 1, 5); d$k <- rpois(400, d$t * exp(-1 + .4 * d$e))
 d
}
se_of <- function(z) (log(z$conf_high) - log(z$estimate)) / qnorm(.975)

test_that("weights reproduce weighted glm coefficients", {
 d <- make_adjusted_data()
 g <- suppressWarnings(glm(y ~ e + age, quasibinomial, d, weights = w))
 z <- epi_adjusted_odds_ratio(d, e, y, age, weights = w, robust = "HC0")
 expect_equal(z$estimate, unname(exp(coef(g)["e"])))
 expect_true(z$weighted)
 gr <- glm(k ~ e + age + offset(log(t)), quasipoisson, d, weights = w)
 expect_equal(epi_adjusted_rate_ratio(d, k, t, e, age, weights = w)$estimate, unname(exp(coef(gr)["e"])))
 expect_error(epi_adjusted_odds_ratio(transform(d, w = -w), e, y, weights = w), "non-negative")
})

test_that("HC1 rescales HC0 by n / (n - p) and cluster implies a sandwich", {
 d <- make_adjusted_data()
 h0 <- se_of(epi_adjusted_odds_ratio(d, e, y, age, robust = "HC0"))
 h1 <- epi_adjusted_odds_ratio(d, e, y, age, robust = "HC1")
 expect_equal(se_of(h1), h0 * sqrt(400 / (400 - 3)))
 expect_equal(h1$se_type, "HC1")
 cz <- suppressWarnings(epi_adjusted_odds_ratio(d, e, y, age, cluster = cl))
 expect_equal(cz$se_type, "cluster_HC0"); expect_equal(cz$clusters, 40L)
 expect_equal(epi_adjusted_odds_ratio(d, e, y, age)$se_type, "model")
})

test_that("robust rate-ratio errors widen under overdispersion", {
 set.seed(3)
 d <- data.frame(e = rep(0:1, 200), t = 1)
 d$k <- rnbinom(400, mu = exp(1 + .3 * d$e), size = 0.7)
 expect_gt(se_of(epi_adjusted_rate_ratio(d, k, t, e, robust = "HC0")), 1.5 * se_of(epi_adjusted_rate_ratio(d, k, t, e)))
})

test_that("modifier returns level-specific effects and an interaction test", {
 d <- make_adjusted_data()
 g <- glm(y ~ e * factor(sex) + age, binomial, d)
 m <- epi_adjusted_odds_ratio(d, e, y, age, modifier = sex)
 expect_equal(m$modifier_level, c("f", "m"))
 expect_equal(m$estimate, unname(exp(c(coef(g)["e"], coef(g)["e"] + coef(g)["e:factor(sex)m"]))))
 expect_equal(m$interaction_p_value[1], summary(g)$coefficients["e:factor(sex)m", 4])
 expect_error(epi_adjusted_odds_ratio(d, e, y, modifier = e), "differ")
 bad <- transform(d, grp = ifelse(e == 1, "a", "b"))
 expect_error(epi_adjusted_odds_ratio(bad, e, y, modifier = grp), "both exposure groups")
})

test_that("nonlinear terms use natural splines", {
 d <- make_adjusted_data()
 g <- glm(y ~ e + splines::ns(age, df = 3), binomial, d)
 expect_equal(epi_adjusted_odds_ratio(d, e, y, age, nonlinear = age)$estimate, unname(exp(coef(g)["e"])))
 expect_error(epi_adjusted_odds_ratio(d, e, y, nonlinear = age), "also be selected")
 rr <- epi_adjusted_risk_ratio(d, e, y, age, nonlinear = age)
 expect_equal(rr$se_type, "HC0")
})
