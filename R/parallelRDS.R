# pRDS

cmdAvail <-
  function(command) {as.logical(nchar(Sys.which(command)))}

#' @export
getDefaultCmd <-
  function(format) {
    getOption(paste("pRDS", format, "default", sep = "."))
  }

#' @export
setDefaultCmd <-
  function(format, command) {
    commands <- getOption("pRDS.commands")
    if (command %in% (
      commands[commands[, "fmt"] == format &
               commands[, "avail"] == "TRUE", "cmd"])) {
      defs <- list()
      defs[paste("pRDS", format, "default", sep = ".")] <- command
      options(defs[paste("pRDS", format, "default", sep = ".")])
    }
  }

fmtDetect <- function(file) {
  if (!cmdAvail("file")) return("")
  fileDetails <-
    system2(
      "file",
      args = file,
      stdout = TRUE
    )
  selector <-
    sapply(
      c("gzip", "XZ", "bzip2"),
      function (x) {grepl(x, fileDetails)}
    )
  tolower(names(selector)[selector])
}

#' @export
cmpFile <-
  function(path,
           mode = c("wb", "rb"),
           format = c("gzip", "bzip2", "xz"),
           compressor = getDefaultCmd(format),
           compression = switch(format, gzip = 6, bzip2 = 9, xz = 6),
           cores = getOption("mc.cores"),
           encoding = getOption("encoding")) {
    if (compression <= 1 && compression >= 9)
      stop(paste("Compression level '", compression, "'not supported."))
    if (is.na(cores))
      cores <- as.integer(parallel::detectCores() / 2)
    commands <- getOption("pRDS.commands")
    mode <- match.arg(mode)
    format <- match.arg(format)
    if (compressor %in% rownames(commands)) {
      message("Using ", compressor, " with ", cores, " cores to ",
              switch(mode, wb = "compress...", rb = "decompress..."),
              appendLF = T)
      command <-
        switch(mode,
               wb =
                 paste(compressor,
                       gsub('%', compression,
                            gsub("#", cores, commands[compressor, mode])
                       ),
                       ">",
                       paste0('"', path, '"')
                 )
               ,
               rb =
                 paste(compressor,
                       gsub("#", cores, commands[compressor, mode]),
                       "<",
                       paste0('"', path, '"')
                 )
        )
      #message("Full command: ", command, appendLF = T)
      pipe(command, mode, encoding)
    } else {
      message("No suitable compression software found on the system. Falling back to R implementation.", appendLF = F)
      switch(
        format,
        gzip = gzfile(file, mode),
        bzip2 = bzfile(file, mode),
        xz = xzfile(file, mode)
      )
    }
  }

#' @export
saveRDS <-
  function (object,
            file = "",
            ascii = FALSE,
            version = NULL,
            compress = TRUE,
            refhook = NULL,
            ...) {
    if (is.character(file)) {
      if (file == "")
        stop("'file' must be non-empty string")
      object <- object
      mode <- if (ascii %in% FALSE)
        "wb"
      else
        "w"
      con <- if (is.logical(compress))
        if (compress)
          cmpFile(file, mode, "gzip", ...)
      else
        file(file, mode)
      else {
        # I disable this because I don't know what it is and how it works
        if (mode == "w") {
          warning("ASCII mode not supported for compressed files.
                  Switching to non-ASCII.")
          mode = "wb"
        }
        cmpFile(file, mode, compress,...)
      }
      on.exit(close(con))
    }
    else if (inherits(file, "connection")) {
      if (!missing(compress))
        warning("'compress' is ignored unless 'file' is a file name")
      con <- file
    }
    else
      stop("bad 'file' argument")
    .Internal(serializeToConn(object, con, ascii, version, refhook))
  }

#' @export
readRDS <-
  function (file, refhook = NULL, ...) {
    if (is.character(file)) {
      if (!file.exists(file)) stop(paste(file, "does not exist!"))
      format <-
        fmtDetect(file)
      con <-
        if (length(format) == 0)
          gzfile(file, "rb")
        else
          cmpFile(file, "rb", format = format, ...)
      on.exit(close(con))
    }
    else if (inherits(file, "connection"))
      con <-
        if (inherits(file, "url"))
          gzcon(file)
        else
          file
    else
      stop("Bad 'file' argument")
    .Internal(unserializeFromConn(con, refhook))
  }
