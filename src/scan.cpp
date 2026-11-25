// Compiled kernels for the circular spatial and space-time Poisson scans and
// the moving-window surveillance screen. The R wrappers keep all input
// validation and random-number generation, so results match the original R
// implementations exactly for a given seed.
#include <Rcpp.h>
#include <cmath>
#include <vector>
using namespace Rcpp;

// Enumerate eligible circles: for each centre (outer loop) and sorted radius
// (inner loop), the locations within the radius, kept when the population
// fraction is in (0, max_fraction] and below one. Membership is returned in
// compressed sparse column form (ptr, idx) with 0-based location indices.
// [[Rcpp::export(rng = false)]]
List scan_candidates_cpp(NumericVector x, NumericVector y, NumericVector pop,
                         NumericVector radii, double max_fraction) {
  const int n = x.size(), nr = radii.size();
  long double total_ld = 0.0L;
  for (int j = 0; j < n; ++j) total_ld += pop[j];
  const double total_pop = (double) total_ld;
  std::vector<int> centre, ptr(1, 0), idx;
  std::vector<double> rad, frac;
  std::vector<double> dist(n);
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < n; ++j) {
      const double dx = x[j] - x[i], dy = y[j] - y[i];
      dist[j] = std::sqrt(dx * dx + dy * dy);
    }
    for (int r = 0; r < nr; ++r) {
      long double s = 0.0L;
      for (int j = 0; j < n; ++j) if (dist[j] <= radii[r]) s += pop[j];
      const double f = (double) s / total_pop;
      if (f > 0 && f <= max_fraction && f < 1) {
        for (int j = 0; j < n; ++j) if (dist[j] <= radii[r]) idx.push_back(j);
        ptr.push_back((int) idx.size());
        centre.push_back(i + 1);
        rad.push_back(radii[r]);
        frac.push_back(f);
      }
    }
  }
  return List::create(_["center"] = wrap(centre), _["radius"] = wrap(rad),
                      _["fraction"] = wrap(frac), _["ptr"] = wrap(ptr),
                      _["idx"] = wrap(idx));
}

inline double poisson_llr(double inside, double expected, double total) {
  if (!(inside > expected)) return 0.0;
  double s = inside * std::log(inside / expected);
  const double outside = total - inside;
  if (outside > 0) s += outside * std::log(outside / (total - expected));
  return s;
}

// Observed counts and log-likelihood ratios for every candidate x window.
// `z` holds counts by location (rows) and period (columns). Output order is
// window-major, matching the R implementation: index = w * m + c.
// [[Rcpp::export(rng = false)]]
List scan_scores_cpp(IntegerVector ptr, IntegerVector idx, NumericVector expected,
                     IntegerVector windows, NumericMatrix z, double total) {
  const int n = z.nrow(), nt = z.ncol(), m = ptr.size() - 1, nw = windows.size();
  NumericVector observed(m * nw), score(m * nw);
  std::vector<double> tail(n, 0.0);
  int done = 0;
  for (int w = 0; w < nw; ++w) {
    for (; done < windows[w]; ++done)
      for (int l = 0; l < n; ++l) tail[l] += z(l, nt - 1 - done);
    for (int c = 0; c < m; ++c) {
      double s = 0.0;
      for (int k = ptr[c]; k < ptr[c + 1]; ++k) s += tail[idx[k]];
      const int o = w * m + c;
      observed[o] = s;
      score[o] = poisson_llr(s, expected[o], total);
    }
  }
  return List::create(_["observed"] = observed, _["score"] = score);
}

// Maximum scan statistic for each simulated dataset. Column b of `sims` is one
// dataset laid out location-fastest (n locations x nt periods).
// [[Rcpp::export(rng = false)]]
NumericVector scan_sim_max_cpp(IntegerVector ptr, IntegerVector idx,
                               NumericVector expected, IntegerVector windows,
                               int n, int nt, NumericMatrix sims, double total) {
  const int m = ptr.size() - 1, nw = windows.size(), B = sims.ncol();
  // Raw pointers: Rcpp element proxies cost more than the arithmetic here.
  const int* p = ptr.begin();
  const int* ix = idx.begin();
  const int* win = windows.begin();
  const double* ex = expected.begin();
  const double* all = sims.begin();
  NumericVector out(B);
  double* res = out.begin();
  std::vector<double> tail(n);
  double* tl = tail.data();
  for (int b = 0; b < B; ++b) {
    const double* col = all + (size_t) b * n * nt;
    std::fill(tail.begin(), tail.end(), 0.0);
    int done = 0;
    double best = 0.0;
    for (int w = 0; w < nw; ++w) {
      for (; done < win[w]; ++done) {
        const double* period = col + (size_t) (nt - 1 - done) * n;
        for (int l = 0; l < n; ++l) tl[l] += period[l];
      }
      const double* e = ex + (size_t) w * m;
      for (int c = 0; c < m; ++c) {
        double s = 0.0;
        for (int k = p[c]; k < p[c + 1]; ++k) s += tl[ix[k]];
        // Exact pruning: llr <= s * log(s / e) <= s * (s - e) / e, so a
        // candidate whose bound cannot beat `best` needs no log() calls.
        if (s > e[c] && s * (s - e[c]) / e[c] > best) {
          const double v = poisson_llr(s, e[c], total);
          if (v > best) best = v;
        }
      }
    }
    res[b] = best;
  }
  return out;
}

// Trailing-window mean and sample variance of the `window` values before each
// position (NA for the first `window` positions), using a two-pass formula.
// [[Rcpp::export(rng = false)]]
List moving_window_cpp(NumericVector y, int window) {
  const int n = y.size();
  NumericVector mu(n, NA_REAL), v(n, NA_REAL);
  for (int i = window; i < n; ++i) {
    long double s = 0.0L;
    for (int k = i - window; k < i; ++k) s += y[k];
    long double mean_ld = s / window, t = 0.0L;
    for (int k = i - window; k < i; ++k) t += y[k] - mean_ld;
    const double mean = (double) (mean_ld + t / window);
    double ss = 0.0;
    for (int k = i - window; k < i; ++k) { const double d = y[k] - mean; ss += d * d; }
    mu[i] = mean;
    v[i] = window > 1 ? ss / (window - 1) : 0.0;
  }
  return List::create(_["mean"] = mu, _["var"] = v);
}
