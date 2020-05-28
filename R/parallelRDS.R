# pRDS

whichcmd <-
  function(commands) {
    for (c in commands) {
      if (as.logical(nchar(Sys.which(c)))) return(c)
    }
    return(NA)
  }

#' @export
cmpfile <-
  function(path,
           mode = c("wb", "rb"),
           format = c("gzip", "bzip2", "xz"),
           # compressor = c(),
           compression = switch(format, gzip = 6, bzip2 = 9, xz = 6),
           cores = getOption("mc.cores"),
           encoding = getOption("encoding")) {
    commands <- getOption("pRDS.commands")
    mode <- match.arg(mode)
    format <- match.arg(format)
    command <- whichcmd(commands[commands[,"fmt"] == format, "cmd"])
    if (compression <= 1 && compression >= 9) stop(paste("Compression level '", compression, "'not supported."))
    con <-
      if (!is.na(command)) {
        if (is.na(cores))
          cores <- as.integer(parallel::detectCores() / 2)
        cat("Using", command, "with", cores, "cores to",
            switch(mode, wb = "compress...", rb="decompress..."), "\n")
        switch(mode,
               wb = pipe(
                 paste(command,
                       paste0(commands[command, mode], cores),
                       paste0("-", compression),
                       ">",
                       path),
                 mode,
                 encoding
               ),
               rb = pipe(
                 paste(command,
                       paste0(commands[command, mode], cores),
                       "<",
                       path),
                 mode,
                 encoding
               ))
      } else {
        cat("No suitable compression software found on the system.
          Falling back to R implementation.")
        switch(
          format,
          gzip = gzfile(file, mode),
          bzip2 = bzfile(file, mode),
          xz = xzfile(file, mode)
        )
      }
    return(con)
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
          cmpfile(file, mode, "gzip", ...)
      else
        file(file, mode)
      else {
        # I disable this because I don't know what it is and how it works
        if (mode == "w") {
          warning("ASCII mode not supported for compressed files.
                  Switching to non-ASCII.")
          mode = "wb"
        }
        cmpfile(file, mode, compress,...)
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
      format <-
        tolower(names(selector)[selector])
      con <-
        if (length(format) == 0) {
          file(file, "rb")
        } else {
          cmpfile(file, "rb", format = format, ...)
        }
      on.exit(close(con))
    }
    else if (inherits(file, "connection"))
      con <- if (inherits(file, "url"))
        gzcon(file)
    else file
    else stop("bad 'file' argument")
    .Internal(unserializeFromConn(con, refhook))
  }
