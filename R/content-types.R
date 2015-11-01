# FROM Shiny
# @author Shiny package authors
knownContentTypes <- list(
  html='text/html; charset=UTF-8',
  htm='text/html; charset=UTF-8',
  js='text/javascript',
  css='text/css',
  png='image/png',
  jpg='image/jpeg',
  jpeg='image/jpeg',
  gif='image/gif',
  svg='image/svg+xml',
  txt='text/plain',
  pdf='application/pdf',
  ps='application/postscript',
  xml='application/xml',
  m3u='audio/x-mpegurl',
  m4a='audio/mp4a-latm',
  m4b='audio/mp4a-latm',
  m4p='audio/mp4a-latm',
  mp3='audio/mpeg',
  wav='audio/x-wav',
  m4u='video/vnd.mpegurl',
  m4v='video/x-m4v',
  mp4='video/mp4',
  mpeg='video/mpeg',
  mpg='video/mpeg',
  avi='video/x-msvideo',
  mov='video/quicktime',
  ogg='application/ogg',
  swf='application/x-shockwave-flash',
  doc='application/msword',
  xls='application/vnd.ms-excel',
  ppt='application/vnd.ms-powerpoint',
  xlsx='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  xltx='application/vnd.openxmlformats-officedocument.spreadsheetml.template',
  potx='application/vnd.openxmlformats-officedocument.presentationml.template',
  ppsx='application/vnd.openxmlformats-officedocument.presentationml.slideshow',
  pptx='application/vnd.openxmlformats-officedocument.presentationml.presentation',
  sldx='application/vnd.openxmlformats-officedocument.presentationml.slide',
  docx='application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  dotx='application/vnd.openxmlformats-officedocument.wordprocessingml.template',
  xlam='application/vnd.ms-excel.addin.macroEnabled.12',
  xlsb='application/vnd.ms-excel.sheet.binary.macroEnabled.12')

getContentType <- function(ext, defaultType='application/octet-stream') {
  ct <- knownContentTypes[[tolower(ext)]]
  if (is.null(ct)){
    ct <- defaultType
  }
  return(ct)
}
