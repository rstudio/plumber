
.onLoad <- function(...) {

  add_api_info_onLoad()

  addParsers_onLoad()

  # TODO: Remove once UI load code moved to respective UI package
  addUIs_onLoad()

  add_serializers_onLoad()


}
