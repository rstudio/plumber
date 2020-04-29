#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>
#include <R_ext/Rdynload.h>

extern SEXP rawmatch (SEXP needle, SEXP haystack);
static const R_CallMethodDef callMethods[]  = {
  {"rawmatch", (DL_FUNC) &rawmatch, 2},
  {NULL, NULL, 0}
};

void R_init_plumber(DllInfo *dll)
{
  R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
