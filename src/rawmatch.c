#include <R.h>
#include <Rinternals.h>

SEXP rawmatch(SEXP needle, SEXP haystack) {
  int i, j, n1, n2;
  Rbyte *x1, *x2;
  SEXP ans;

  n1 = LENGTH(needle);
  x1 = RAW(needle);
  n2 = LENGTH(haystack);
  x2 = RAW(haystack);
  if (n1 * n2 == 0 || n1 > n2) return allocVector(INTSXP, 0);

  ans = allocVector(INTSXP, 1);

  for (i = 0; i < n2; i++) {
    if (x2[i] == x1[0]) {
      for (j = 0; j < n1; j++) {
        if (x2[i + j] != x1[j]) break;
      }
      if (j == n1) {
        INTEGER(ans)[0] = i + 1;
        return ans;
      }
    }
  }
  return allocVector(INTSXP, 0);
}
