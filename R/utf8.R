# Shiny has been tried and tested on different encodings
# adoption from https://github.com/rstudio/shiny/blob/6ede0194c6e52d18be3ec13514defd8e0f22a3c1/R/utils.R#L1459-L1532

isWindows <- function() .Platform$OS.type == 'windows'

# assume file is encoded in UTF-8, but warn against BOM
checkEncoding <- function(file) {
  # skip *nix because its locale is normally UTF-8 based (e.g. en_US.UTF-8), and
  # *nix users have to make a conscious effort to save a file with an encoding
  # that is not UTF-8; if they choose to do so, we cannot do much about it
  # except sitting back and seeing them punished after they choose to escape a
  # world of consistency (falling back to getOption('encoding') will not help
  # because native.enc is also normally UTF-8 based on *nix)
  if (!isWindows()) return('UTF-8')
  size <- file.info(file)[, 'size']
  if (is.na(size)) stop('Cannot access the file ', file)
  # BOM is 3 bytes, so if the file contains BOM, it must be at least 3 bytes
  if (size < 3L) return('UTF-8')

  # check if there is a BOM character: this is also skipped on *nix, because R
  # on *nix simply ignores this meaningless character if present, but it hurts
  # on Windows
  if (identical(charToRaw(readChar(file, 3L, TRUE)), charToRaw('\UFEFF'))) {
    warning('You should not include the Byte Order Mark (BOM) in ', file, '. ',
            'Please re-save it in UTF-8 without BOM. See ',
            'http://shiny.rstudio.com/articles/unicode.html for more info.')
    return('UTF-8-BOM')
  }
  x <- readChar(file, size, useBytes = TRUE)
  if (is.na(iconv(x, 'UTF-8', 'UTF-8'))) {
    warning('The input file ', file, ' does not seem to be encoded in UTF8')
  }
  'UTF-8'
}

# read a file using UTF-8 and (on Windows) convert to native encoding if possible
readUTF8 <- function(file) {
  enc <- checkEncoding(file)
  file <- base::file(file, encoding = enc)
  on.exit(close(file), add = TRUE)
  x <- enc2utf8(readLines(file, warn = FALSE))
  tryNativeEncoding(x)
}

# if the UTF-8 string can be represented in the native encoding, use native encoding
tryNativeEncoding <- function(string) {
  if (!isWindows()) return(string)
  string2 <- enc2native(string)
  if (identical(enc2utf8(string2), string)) string2 else string
}

# similarly, try to source() a file with UTF-8
sourceUTF8 <- function(file, envir = globalenv()) {
  exprs <- parseUTF8(file)

  eval(exprs, envir)
}


parseUTF8 <- function(file) {
  lines <- readUTF8(file)
  enc <- if (any(Encoding(lines) == 'UTF-8')) 'UTF-8' else 'unknown'
  src <- srcfilecopy(file, lines, isFile = TRUE)  # source reference info

  # oddly, parse(file) does not work when file contains multibyte chars that
  # **can** be encoded natively on Windows (might be a bug in base R); we
  # rewrite the source code in a natively encoded temp file and parse it in this
  # case (the source reference is still pointed to the original file, though)
  if (isWindows() && enc == 'unknown') {
    file <- tempfile(); on.exit(unlink(file), add = TRUE)
    writeLines(lines, file)
  }
  
  # keep the source locations within the file while parsing
  exprs <- try(parse(file, keep.source = TRUE, srcfile = src, encoding = enc))
  if (inherits(exprs, "try-error")) {
    stop("Error sourcing ", file)
  }

  exprs
}
