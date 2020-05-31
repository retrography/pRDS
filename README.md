# pRDS (parallel RDS)

pRDS is a [R](https://www.r-project.org) package that uses existing parallelized 
compression software (e.g., [pigz](https://github.com/madler/pigz)) to read and 
write compressed RDS files, leading to a speedup given the multi-threading 
capabalities of modern computers. The package looks for the appropriate 
compression software in the host system's path and if found, offload the 
handling of compression and decompression tasks to the external program. 

## Installation

You can easily use `devtools` to install pRDS:

```R
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
devtools::install_github("retrography/pRDS")
```

You will probably also need to install one or more of the compression software
packages that pRDS recognizes, so that pRDS can work its magic. Those include 
[xz](https://github.com/xz-mirror/xz), [lbzip2](https://github.com/kjn/lbzip2),
[pixz](https://github.com/vasi/pixz), [pxz](https://github.com/jnovy/pxz),
[pbzip2](https://github.com/ruanhuabin/pbzip2), 
[zstd](https://github.com/facebook/zstd), 
[7-zip](https://sourceforge.net/projects/sevenzip/), and 
[pigz](https://github.com/madler/pigz). For that you will need to use your 
system's package manager (brew, APT, YUM, etc). Note that not all these packages 
are available on every Linux/Unix/macOS platform. That is why pRDS supports so 
many of them.

On Windows (to the best of my knowledge) you will need zstd for gzip as well as 
7-zip for xz and bzip2 compression. You will also need to install RTools that 
includes cruicial utilities for detecting the mime type of the files:

```bat
choco install rtools zstandard 7zip
```

For pRDS to find your programs, they have to be in the system's path. zstd adds
its executables directly to the path. For 7zip you have to do it yourself by 
adding the directoy (normally `C:\Program Files\7-Zip`) to the PATH environment
variable. Otherwise you can add it to R's PATH environment:

```R
Sys.setenv(PATH = paste("c:\\Program Files\\7-Zip", Sys.getenv("PATH"), sep=";"))
```

The same holds if you have pigz or any other compression software installed.

## Usage

pRDS is designed to be a drop-in replacement for R's base RDS manipulation 
functions. Its functions override `readRDS` and `writeRDS` to introduce new 
versions that use system commands with parallel implementation. Call them the 
same way you call the original functions from `base` package. In addition to 
the usual parameters you can also pass additional parameters to these functions
that are, in turn, channeled to the underlying `cmpFile` function. For 
instance you can control the number of cores to be used by setting the `core`
parameter, or change the compression level by passing a value to the
`compression` parameter. You can also explicitly set the default compression 
software for a given format using the `setDefaultCmd` function (only the 
supported software).

Note that for the package to know how many cores it can use for its task you
will have to set the `mc.cores` option:

```R
options(mc.cores = parallel::detectCores())
```

## Why

Writing RDS files is rather fast if the compression option is switched off. But
with compression turned on saving large quantities of data quickly becomes 
impossible, as R's base implementation uses only a single thread. One way to 
solve this issue is to create the appropriate C bindings for the existiing 
compression libraries. But bindings are hard to maintain and subject to breaking
when the upstream changes. Quite a few projects of this kind have already gone 
bust. CLI interfaces, though, rarely change, and OS package managers take care
of maintaining them. pRDS smartly takes the dumb approach to fast compression /
decompression: Relying on the external, well-maintained tools that we all have
access to on our computers. This is particularly useful in HPC environments and
analytic servers where we don't have access to all the libraries we want, but 
where most popular compression packages are pre-installed.

## License

pRDS is published under [GNU General Public License, version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html) because it proudly
steals some GPL code from [R](https://www.r-project.org) itself.  

