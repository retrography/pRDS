.onLoad <- function(libname, pkgname) {
  op <- options()

  commands <- matrix(
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
  rownames(commands) <- commands[,1]
  colnames(commands) <- c("cmd", "wb", "rb", "fmt")

  op.pRDS <- list(
    pRDS.commands = commands
  )
  toset <- !(names(op.pRDS) %in% names(op))
  if(any(toset)) options(op.pRDS[toset])

  invisible()
}

.onUnload <- function(libpath) {
  .Options$pRDS.commands <- NULL
}
