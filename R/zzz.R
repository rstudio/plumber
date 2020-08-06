
.onLoad <- function(...) {

  add_api_info_onLoad()

  register_parsers_onLoad()

  # TODO: Remove once UI load code moved to respective UI package
  register_uis_onLoad()

  add_serializers_onLoad()

}
