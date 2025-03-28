#' Run Bayesian GAM Model for a Single Gene
#'
#' This function runs a Bayesian GAM model for a single gene across a trajectory.
#'
#' @param data_array A 3D array of expression values [batch, time, gene]
#' @param gene_index Index of the gene to model in the 3D array
#' @param n_knots Number of knots for the cubic regression spline (default: 5)
#' @param n_samples Number of MCMC samples (default: 2000)
#'
#' @return A fitted model object from \code{bayesian_gam_regression_nb_shape}
#'
#' @export
run_trajectory_model <- function(data_array, gene_index, n_knots = 5, n_samples = 2000) {
  # Extract data for the gene
  data_for_model <- prepare_data_for_gam(data_array[,,gene_index])
  
  # Fit model
  fitModel <- bayesian_gam_regression_nb_shape(
    data_for_model$x,
    data_for_model$y,
    data_for_model$array_idx,
    n_knots = n_knots,
    n_samples = n_samples
  )
  
  return(fitModel)
}

#' Prepare 3D Array Data for GAM Modeling
#'
#' This function prepares data from a 3D array for GAM modeling.
#'
#' @param gene_data A 2D slice of a 3D array for a single gene [batch, time]
#'
#' @return A list containing:
#'   \item{x}{Vector of pseudotime values}
#'   \item{y}{Vector of expression values}
#'   \item{array_idx}{Vector of batch indices}
#'
#' @export
prepare_data_for_gam <- function(gene_data) {
  # Get dimensions
  n_batches <- dim(gene_data)[1]
  n_times <- dim(gene_data)[2]
  
  # Create vectors for model
  x <- rep(1:n_times, n_batches)
  array_idx <- rep(1:n_batches, each = n_times)
  
  # Flatten the data
  y <- as.vector(t(gene_data))
  
  # Return as list
  return(list(
    x = x,
    y = y,
    array_idx = array_idx
  ))
}

#' Run Trajectory Models for Multiple Genes
#'
#' This function runs Bayesian GAM models for multiple genes across a trajectory.
#'
#' @param data_array A 3D array of expression values [batch, time, gene]
#' @param gene_indices Indices of genes to model (default: all genes)
#' @param n_knots Number of knots for the cubic regression spline (default: 5)
#' @param n_samples Number of MCMC samples (default: 2000)
#' @param parallel Whether to run in parallel (default: FALSE)
#' @param n_cores Number of cores to use for parallel processing (default: 1)
#'
#' @return A list of fitted model objects
#'
#' @import foreach
#' @importFrom doParallel registerDoParallel
#' @importFrom progressr with_progress progressor
#' @export
run_multiple_models <- function(data_array, gene_indices = NULL, n_knots = 5, n_samples = 2000, 
                               parallel = FALSE, n_cores = 1) {
  # If gene_indices is NULL, use all genes
  if (is.null(gene_indices)) {
    gene_indices <- 1:dim(data_array)[3]
  }
  
  # Get gene names
  gene_names <- dimnames(data_array)[[3]][gene_indices]
  
  # Set up parallel processing if requested
  if (parallel && n_cores > 1) {
    doParallel::registerDoParallel(cores = n_cores)
  }
  
  # Run models
  progressr::with_progress({
    p <- progressr::progressor(along = gene_indices)
    
    if (parallel && n_cores > 1) {
      # Parallel execution
      results <- foreach::foreach(i = gene_indices, .packages = c("brms", "dplyr", "cmdstanr")) %dopar% {
        tryCatch({
          p(message = sprintf("Modeling gene %s", gene_names[i]))
          run_trajectory_model(data_array, i, n_knots, n_samples)
        }, error = function(e) {
          message(sprintf("Error fitting model for gene %s: %s", gene_names[i], e$message))
          NULL
        })
      }
    } else {
      # Sequential execution
      results <- list()
      for (i in seq_along(gene_indices)) {
        tryCatch({
          p(message = sprintf("Modeling gene %s", gene_names[gene_indices[i]]))
          results[[i]] <- run_trajectory_model(data_array, gene_indices[i], n_knots, n_samples)
        }, error = function(e) {
          message(sprintf("Error fitting model for gene %s: %s", gene_names[gene_indices[i]], e$message))
          results[[i]] <- NULL
        })
      }
      names(results) <- gene_names
    }
  })
  
  return(results)
}