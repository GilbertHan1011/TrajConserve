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
#' @param save_metrics Whether to save the array weights to an HDF5 file (default: FALSE)
#' @param save_metrics_file File path to save metrics in HDF5 format (default: "model_metrics.h5")
#' @param save_plots Whether to save plot results as PDF files (default: FALSE)
#' @param save_plots_dir Directory to save plot PDFs (default: "model_plots")
#' @param save_models Whether to save the models to a directory (default: FALSE)
#' @param save_models_dir Directory to save model files (default: "model_files")
#'
#' @return A list of fitted model objects
#'
#' @import foreach
#' @importFrom doParallel registerDoParallel
#' @importFrom progressr with_progress progressor
#' @importFrom grDevices pdf dev.off
#' @importFrom tools file_path_sans_ext
#' @export
run_multiple_models <- function(data_array, gene_indices = NULL, n_knots = 5, n_samples = 2000, 
                                parallel = FALSE, n_cores = 1, 
                                save_metrics = FALSE, save_metrics_file = "model_metrics.h5",
                                save_plots = FALSE, save_plots_dir = "model_plots",
                                save_models = FALSE, save_models_dir = "model_files") {
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
  
  # Check for rhdf5 package if save_metrics is TRUE
  if (save_metrics) {
    if (!requireNamespace("rhdf5", quietly = TRUE)) {
      stop("The 'rhdf5' package is required to save metrics in HDF5 format. Please install it with: BiocManager::install('rhdf5')")
    }
    
    # Create HDF5 file and initialize structure
    if (file.exists(save_metrics_file)) {
      message("HDF5 file already exists. Data will be appended.")
    } else {
      # Create new file and structure using high-level functions
      rhdf5::h5createFile(save_metrics_file)
      rhdf5::h5createGroup(save_metrics_file, "array_weights")
      rhdf5::h5createGroup(save_metrics_file, "metadata")
      
      # Add metadata about the structure
      metrics_cols <- c("Estimate", "Est.Error", "Q2.5", "Q97.5", "shape", "weight", "weight_norm")
      rhdf5::h5write(metrics_cols, save_metrics_file, "metadata/metric_names")
    }
  }
  
  # Create directories for saving if needed
  if (save_plots) {
    if (!dir.exists(save_plots_dir)) {
      dir.create(save_plots_dir, recursive = TRUE)
    }
  }
  
  if (save_models) {
    if (!dir.exists(save_models_dir)) {
      dir.create(save_models_dir, recursive = TRUE)
    }
  }
  
  # Run models
  progressr::with_progress({
    p <- progressr::progressor(along = gene_indices)
    
    if (parallel && n_cores > 1) {
      # Parallel execution
      results <- foreach::foreach(i = seq_along(gene_indices), .packages = c("brms", "dplyr", "cmdstanr", "grDevices", "tools")) %dopar% {
        tryCatch({
          gene_idx <- gene_indices[i]
          gene_name <- gene_names[i]
          p(message = sprintf("Modeling gene %s", gene_name))
          model_result <- run_trajectory_model(data_array, gene_idx, n_knots, n_samples)
          
          if (save_plots) {
            pdf_file <- file.path(save_plots_dir, paste0(gene_name, "_plot.pdf"))
            grDevices::pdf(pdf_file, width = 10, height = 6)
            plot_obj <- plot_results_brms(model_result)
            print(plot_obj)
            grDevices::dev.off()
          }
          
          if (save_models) {
            model_file <- file.path(save_models_dir, paste0(gene_name, "_model.rds"))
            saveRDS(model_result, model_file)
          }
          
          # Note: We don't save to HDF5 here in parallel mode to avoid concurrent access issues
          # Will handle it after parallel execution
          
          model_result
        }, error = function(e) {
          message(sprintf("Error fitting model for gene %s: %s", gene_name, e$message))
          NULL
        })
      }
      names(results) <- gene_names
      
      # Now save metrics to HDF5 if needed in serial mode to avoid conflicts
      if (save_metrics) {
        for (i in seq_along(results)) {
          if (!is.null(results[[i]])) {
            gene_name <- names(results)[i]
            gene_weights <- results[[i]]$array_weights
            
            # Save array weights for this gene
            gene_path <- paste0("array_weights/", gene_name)
            saveWeightsToHDF5(save_metrics_file, gene_path, gene_weights)
          }
        }
      }
      
    } else {
      # Sequential execution
      results <- list()
      for (i in seq_along(gene_indices)) {
        gene_idx <- gene_indices[i]
        gene_name <- gene_names[i]
        
        tryCatch({
          p(message = sprintf("Modeling gene %s", gene_name))
          results[[i]] <- run_trajectory_model(data_array, gene_idx, n_knots, n_samples)
          
          if (save_plots) {
            pdf_file <- file.path(save_plots_dir, paste0(gene_name, "_plot.pdf"))
            grDevices::pdf(pdf_file, width = 10, height = 6)
            plot_obj <- plot_results_brms(results[[i]])
            print(plot_obj)
            grDevices::dev.off()
          }
          
          if (save_models) {
            model_file <- file.path(save_models_dir, paste0(gene_name, "_model.rds"))
            saveRDS(results[[i]], model_file)
          }
          
          # Save metrics to HDF5 if requested
          if (save_metrics && !is.null(results[[i]])) {
            gene_weights <- results[[i]]$array_weights
            
            # Save array weights for this gene
            gene_path <- paste0("array_weights/", gene_name)
            saveWeightsToHDF5(save_metrics_file, gene_path, gene_weights)
          }
          
        }, error = function(e) {
          message(sprintf("Error fitting model for gene %s: %s", gene_name, e$message))
          results[[i]] <- NULL
        })
      }
      names(results) <- gene_names
    }
  })
  
  return(results)
}

# Helper function to save weights to HDF5 file
saveWeightsToHDF5 <- function(h5_file, group_path, weights_df) {
  # Create group for this gene if it doesn't exist
  # First check if file exists
  if (!file.exists(h5_file)) {
    rhdf5::h5createFile(h5_file)
  }
  
  # Open file to work with it
  file_id <- rhdf5::H5Fopen(h5_file)
  
  # Check if group exists and create if needed
  if (!rhdf5::H5Lexists(file_id, group_path)) {
    # Close the file first
    rhdf5::H5Fclose(file_id)
    # Create the group using high-level function
    rhdf5::h5createGroup(h5_file, group_path)
    # Reopen the file
    file_id <- rhdf5::H5Fopen(h5_file)
  }
  
  # Close the file now that we've checked/created the group
  rhdf5::H5Fclose(file_id)
  
  # Save array weights dataframe components using high-level functions
  metrics_cols <- c("Estimate", "Est.Error", "Q2.5", "Q97.5", "shape", "weight", "weight_norm")
  for (col in metrics_cols) {
    if (col %in% colnames(weights_df)) {
      col_path <- paste0(group_path, "/", col)
      rhdf5::h5write(weights_df[[col]], h5_file, col_path)
    }
  }
  
  # Save array information - convert factor to character first
  array_path <- paste0(group_path, "/array")
  array_values <- weights_df$array
  if (is.factor(array_values)) {
    array_values <- as.character(array_values)
  }
  rhdf5::h5write(array_values, h5_file, array_path)
}