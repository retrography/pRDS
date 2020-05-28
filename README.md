# pRDS (parallel RDS)

pRDS is a [R](https://www.r-project.org) package that uses existing parallelized 
compression software (e.g., `pigz`) to read and write compressed RDS files 
efficiently. The package looks for the appropriate compression software in 
the host system's path and if found, offload the handling of compression and 
decompression tasks to the external program. 

## Installation

You can easily use `devtools` to install pRDS:

```R
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
devtools::install_github("retrography/pRDS")
```

You will probably also need to install one or more of the compression software
packages that pRDS recognizes, so that pRDS can work its magic. Those include 
`xz`, `lbzip2`, `pixz`, `pxz`, `pbzip2`, `zstd`, and `pigz`. For that you will 
need to use your system's package manager (brew, APT, YUM, etc). Note that not 
all these packages are available on every Linux/Unix/macOS platform. That is why 
pRDS supports so many of them.

## Use

pRDS's main functions override `readRDS` and `writeRDS` to introduce new 
versions that use system commands with parallel implementation. Call them the 
same way you call the original functions from `base` package. In addition to 
the usual parameters you can also pass additional parameters to these functions
that are, in turn, channeled to the underlying `cmpfile` function. For 
instance you can control the number of cores to be used by setting the `core`
parameter, or change the compression level by passing a value to the
`compression` parameter.


