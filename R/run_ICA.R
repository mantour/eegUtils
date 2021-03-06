#' ICA for EEG data
#'
#' Implements SOBI ICA. Although SOBI exists in R already, thanks to the JADE
#' package, it doesn't respect epoch boundaries when computing correlations
#' across different time lags. This is a port of SOBI from EEGLAB. Currently
#' only works on epoched data.
#'
#' @param data Data frame to be ICAed.
#' @param method Only SOBI is currently implemented, so this is ignored.
#'
#' @import dplyr
#' @import tidyr
#' @importFrom JADE rjd
#' @importFrom MASS ginv
#' @export

run_ICA <- function (data, method = "sobi") {

  n_epochs <- length(unique(data$epoch))
  n_channels <- length(unique(data$electrode))
  n_times <- length(unique(data$time))

  ##number of lags at which to assess autocovariance matrices
  n_lags <- min(100, ceiling(n_times / 3))

  ## reshape amplitude X electrode to a square matrix before doing SVD
  data <- spread(data, electrode, amplitude)

  ## Pre-whiten the data using the SVD. zero-mean columns and get SVD. NB:
  ## should probably edit this to zero mean *epochs*
  amp_matrix <-
    scale(data.matrix(data[, (ncol(data) - n_channels + 1):ncol(data)]),
          scale = FALSE)
  SVD_amp <- svd(amp_matrix)

  ## get the psuedo-inverse of the diagonal matrix, multiply by right singular
  ## vectors
  Q <- MASS::ginv(diag(SVD_amp$d)) %*% t(SVD_amp$v)
  amp_matrix <- Q %*% t(amp_matrix)

  ## reshape to reflect epoching structure
  dim(amp_matrix) <- c(n_channels, n_times, n_epochs)

  ## vectorise this loop ASAP.
  k <- 1
  pm <- n_channels * n_lags
  N <- n_times
  M <- matrix(NA, nrow = n_channels, ncol = pm)

  for (u in seq(1, pm, n_channels)) {
    k <- k + 1
    for (tlag in 1:n_epochs) {
      if (tlag == 1) {
        Rxp <- amp_matrix[, k:N, tlag] %*%
          t(amp_matrix[, 1:(N - k + 1), tlag]) / (N - k + 1) / n_epochs
        } else {
        Rxp <- Rxp + amp_matrix[, k:N, tlag] %*%
          t(amp_matrix[, 1:(N - k + 1), tlag]) / (N - k + 1) / n_epochs
      }
      M[, u:(u + n_channels - 1)] <- norm(Rxp, "F") * Rxp #  % Frobenius norm
    }
  }

  dim(M) <- c(n_channels, n_channels, pm / n_channels)

  ## do joint diagonalization of matrices using rjd from JADE
  M_rjd <- JADE::rjd(M, maxiter = 300, eps = 1 / sqrt(N) / 100)

  ## create mixing matrix for output
  mixing_matrix <- data.frame(MASS::ginv(Q) %*% M_rjd$V)
  names(mixing_matrix) <- 1:n_channels
  mixing_matrix$electrode <-
    names(data[, (ncol(data) - n_channels + 1):ncol(data)])
  dim(amp_matrix) <- c(n_channels, n_times * n_epochs)
  S <- t(M_rjd$V) %*% amp_matrix
  return(list("mixing_matrix" = mixing_matrix, "comp_activations" = t(S)))
}
