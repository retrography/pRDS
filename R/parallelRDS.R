# Run the following line at the command prompt before using the functions.
#
#     brew install lbzip2 pigz pbzip2 pixz pxz zstd xz
#

#TODO: Use saveRDS's original structure from base (create new gzfile, etc. functions instead of creating specialized saveRDS functions) (or structure from dplyr's write_rds)
#TODO: Add a message print for all operations
#TODO: Add quiet switch wherever it is needed
#TODO: Make package
#TODO: Read number of cores from options, if present?
#TODO: Option for compression program choice (overall, and during each writeup)
#TODO: For now when in windows always fall back to R implementation, but maybe we can work on that too? The problem is that the "file" command doens't work there. How can we detect the format oif the file?
#TODO: Print a matrix of which software is present at module load, and set the preferred commans upfront (and maybe show a warning for windows)
#TODO add snzip and lz4 and zstd (non-standard).
#TODO make it possible to modify the commands matrix in runtime
#TODO Docs
#TODO Compress other formats (feather? RData?)
#TODO Add tests devtools::use_testthat()

prds <- new.env()

prds$cmds <- matrix(
  c(
    c("zstd", "--format=gzip -cT", "-cdT", "gzip"),
    c("pigz", "-cp", "-dcp", "gzip"),
    c("pixz", "-tp", "-dp", "xz"),
    c("pxz", "-cT", "-dcT", "xz"),
    c("xz", "-zcT", "-cdT", "xz"),
    c("lbzip2", "-czn", "-ckdn", "bzip2"),
    c("pbzip2", "-cp", "-dcp", "bzip2")
  ),
  ncol = 4,
  byrow = T
)
rownames(prds$cmds) <- prds$cmds[,1]
colnames(prds$cmds) <- c("cmd", "wb", "rb", "fmt")

whichcmd <- function(commands) {
  for (c in commands) {
    if (as.logical(nchar(Sys.which(c)))) return(c)
  }
  return(NA)
}

#' @export
cmpfile <- function(path,
                     mode = c("wb", "rb"),
                     format = c("gzip", "bzip2", "xz"),
                     # compressor = c(),
                     compression = switch(format, gzip = 6, bzip2 = 9, xz = 6),
                     cores = getOption("mc.cores"),
                     encoding = getOption("encoding")) {
  mode <- match.arg(mode)
  format <- match.arg(format)
  command <- whichcmd(prds$cmds[prds$cmds[,"fmt"] == format, "cmd"])
  if (compression <= 1 && compression >= 9) stop(paste("Compression level '", compression, "'not supported."))
  con <-
    if (!is.na(command)) {
      if (is.na(cores))
        cores <- as.integer(parallel::detectCores()/2)
      cat("Using", command, "with", cores, "cores to", switch(mode, wb = "compress...", rb="decompress..."), "\n")
      switch(mode,
             wb = pipe(
               paste(command,
                     paste0(prds$cmds[command, mode], cores),
                     paste0("-", compression),
                     ">",
                     path),
               mode,
               encoding
             ),
             rb = pipe(
               paste(command,
                     paste0(prds$cmds[command, mode], cores),
                     "<",
                     path),
               mode,
               encoding
             ))
    } else {
      cat("No suitable compression software found on the system. Falling back to R implementation.")
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
          warning("ASCII mode not supported for compressed files. Switching to non-ASCII.")
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
