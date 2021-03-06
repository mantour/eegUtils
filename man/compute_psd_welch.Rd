% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/psd.R
\name{compute_psd_welch}
\alias{compute_psd_welch}
\title{Compute power spectral density using Welch's method}
\usage{
compute_psd_welch(data, seg_length = NULL, noverlap = 0, n_fft = 256,
  srate = NULL)
}
\arguments{
\item{data}{Data to be plotted. Accepts objects of class \code{eeg_data} or
simple vectors. If a vector is supplied, \code{srate} must also be
provided.}

\item{seg_length}{Length of rolling data segments.}

\item{noverlap}{Number of (sampling) points of overlap between segments.}

\item{n_fft}{Length of FFT to be calculated.}

\item{srate}{Sampling rate}
}
\description{
Compute power spectral density using Welch's method
}
\author{
Matt Craddock \email{matt@mattcraddock.com}
}
