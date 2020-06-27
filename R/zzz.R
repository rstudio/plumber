
.onLoad <- function(...) {

  addApiInfo_onLoad()

  addParsers_onLoad()

  # TODO: Remove once UI load code moved to respective UI package
  addUIs_onLoad()

}
