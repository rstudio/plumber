# FROM Shiny
# @author Shiny package authors
knownContentTypes <- c(
  html = "text/html; charset=UTF-8",
  htm = "text/html; charset=UTF-8",
  js = "text/javascript",
  css = "text/css",
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  svg = "image/svg+xml",
  txt = "text/plain",
  pdf = "application/pdf",
  ps = "application/postscript",
  xml = "application/xml",
  m3u = "audio/x-mpegurl",
  m4a = "audio/mp4a-latm",
  m4b = "audio/mp4a-latm",
  m4p = "audio/mp4a-latm",
  mp3 = "audio/mpeg",
  wav = "audio/x-wav",
  m4u = "video/vnd.mpegurl",
  m4v = "video/x-m4v",
  mp4 = "video/mp4",
  mpeg = "video/mpeg",
  mpg = "video/mpeg",
  avi = "video/x-msvideo",
  mov = "video/quicktime",
  ogg = "application/ogg",
  swf = "application/x-shockwave-flash",
  doc = "application/msword",
  xls = "application/vnd.ms-excel",
  ppt = "application/vnd.ms-powerpoint",
  xlsx = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  xltx = "application/vnd.openxmlformats-officedocument.spreadsheetml.template",
  potx = "application/vnd.openxmlformats-officedocument.presentationml.template",
  ppsx = "application/vnd.openxmlformats-officedocument.presentationml.slideshow",
  pptx = "application/vnd.openxmlformats-officedocument.presentationml.presentation",
  sldx = "application/vnd.openxmlformats-officedocument.presentationml.slide",
  docx = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
  dotx = "application/vnd.openxmlformats-officedocument.wordprocessingml.template",
  xlam = "application/vnd.ms-excel.addin.macroEnabled.12",
  xlsb = "application/vnd.ms-excel.sheet.binary.macroEnabled.12",
  feather = "application/feather",
  parquet = "application/parquet",
  rds = "application/rds",
  tsv = "application/tab-separated-values",
  csv = "application/csv",
  json = "application/json",
  yml = "application/yaml",
  yaml = "application/yaml"
)

getContentType <- function(ext, defaultType = 'application/octet-stream') {
  ext <- tolower(ext)

  ret <-
    knownContentTypes[ext] %|%
    mime::mimemap[ext] %|%
    defaultType

  ret[[1]]
}

cleanup_content_type <- function(type) {
  if (length(type) == 0) return(type)

  type <- tolower(type)

  # remove trailing content type information
  # "text/yaml; charset=UTF-8"
  # to
  # "text/yaml"
  if (stri_detect_fixed(type, ";")) {
    type <- stri_split_fixed(type, ";")[[1]][1]
  }

  type
}

get_fileext <- function(type) {
  type <- cleanup_content_type(type)

  all_content_types <- c(knownContentTypes, mime::mimemap)

  type_to_ext <- setNames(names(all_content_types), all_content_types)

  ret <- type_to_ext[type] %|% NULL
  ret[[1]]
}

#' Request character set
#' @param content_type Request Content-Type header
#' @return Default to `UTF-8`. Otherwise return `charset` defined in request header.
#' @export
get_character_set <- function(content_type = NULL) {
  if (is.null(content_type)) return("UTF-8")
  stri_match_first_regex(paste(content_type,"; charset=UTF-8"), "charset=([^;\\s]*)")[,2]
}
