
.onLoad <- function(...) {

  add_api_info_onLoad()

  register_parsers_onLoad()

  add_serializers_onLoad()

  register_swagger_docs_onLoad()

}
