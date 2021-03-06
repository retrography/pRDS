% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parallelRDS.R
\name{saveRDS}
\alias{saveRDS}
\title{Read/write RDS streams}
\usage{
saveRDS(
  object,
  file = "",
  ascii = FALSE,
  version = NULL,
  compress = TRUE,
  refhook = NULL,
  ...
)
}
\arguments{
\item{object}{R object to serialize.}

\item{file}{a \link{connection} or the name of the file where the R object is saved
to or read from.}

\item{ascii}{a logical. If TRUE or NA, an ASCII representation is written;
otherwise (default), a binary one is used. See the comments in the help
for \link{save}. d}
}
\description{
Drop-in replacements for \link[base:saveRDS]{saveRDS} and \link[base:readRDS]{readRDS} from \link{base}
allowing use of external multi-threaded programs for faster
compression/decompression. The functions also allow use of additional
parameters, which are directly passed to \link{cmpFile}.
}
