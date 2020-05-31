.onLoad <- function(libname, pkgname) {
  op <- options()

  if (Sys.info()['sysname'] == "Windows") {
    if (devtools::find_rtools()) {
      path <- Sys.getenv("PATH")
      rt <- gsub('/','\\\\', pkgbuild::rtools_path())
      path <- paste(path, rt, sep=";")
     Sys.setenv(PATH = path)
    } else {
      warning("Rtools not found. Will fall back to R implementation for all decompression tasks.")
    }
  }

  commands <- matrix(
    c(
      c("zstd", "--format=gzip -cT# -%", "-cdT#", "gzip"),
      c("pigz", "-cp# -%", "-dcp#", "gzip"),
      c("pixz", "-tp# -%", "-dp#", "xz"),
      c("pxz", "-cT# -%", "-dcT#", "xz"),
      c("xz", "-zcT# -%", "-cdT#", "xz"),
      c("zstd", "--format=xz -cT# -%", "-cdT#", "xz"),
      c("7z", "a dummy -txz -so -si -mmt=# -mx=%", "e -txz -so -si -mmt=#", "xz"),
      c("lbzip2", "-czn# -%", "-cdn#", "bzip2"),
      c("pbzip2", "-cp# -%", "-dcp#", "bzip2"),
      c("7z", "a dummy -tbzip2 -so -si -mmt=# -mx=%", "e -tbzip2 -so -si -mmt=#", "bzip2")
    ),
    ncol = 4,
    byrow = T
  )
  rownames(commands) <- commands[,1]
  commands <- cbind(commands, FALSE, FALSE)
  colnames(commands) <- c("cmd", "wb", "rb", "fmt", "avail", "def")

  commands[, "avail"] <- unlist(lapply(rownames(commands), cmdAvail))

  if (commands["zstd", "avail"] == "TRUE") {
    commands[commands[,"cmd"] == "zstd" & commands[,"fmt"] == "gzip", "avail"] <-
      any(grepl("--format=gzip", system2("zstd", args = "--help", stdout = TRUE)))
    commands[commands[,"cmd"] == "zstd" & commands[,"fmt"] == "xz", "avail"] <-
      any(grepl("--format=xz", system2("zstd", args = "--help", stdout = TRUE)))
  }

  op.pRDS <- list(
    pRDS.commands = commands[,-6]
  )

  for (f in unique(commands[, "fmt"])) {
    commands[commands[, "avail"] == TRUE & commands[, "fmt"] == f, "def"][1] <- "TRUE"
    fmtdef <- commands[commands[, "def"] == TRUE & commands[, "fmt"] == f, "cmd"]
    op.pRDS[paste("pRDS", f, "default", sep = ".")] <- ifelse(is.null(fmtdef), NA, fmtdef)
  }

  message("Available compressors and the default for each format:", appendLF = T)
  tbl <- capture.output(prmatrix(
    gsub("TRUE", "√", gsub("FALSE", "-", commands[,4:6])),
    quote=F,
    collab = c("Format", "Available", "Default")
  ))
  for (r in tbl)
    message(r, appendLF = T)

  message("Change the defaults by calling the setDefaultCmd function.", appendLF = T)


  toset <- !(names(op.pRDS) %in% names(op))
  if(any(toset)) options(op.pRDS[toset])

  invisible()
}

.onUnload <- function(libpath) {
  options(pRDS.commands = NULL,
          pRDS.gzip.default = NULL,
          pRDS.bzip2.default = NULL,
          pRDS.xz.default = NULL)
}
