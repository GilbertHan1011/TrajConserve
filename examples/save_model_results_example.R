# Example script demonstrating how to save model metrics, plots, and model files
library(trajConserve)

# Simulate data for example
set.seed(123)
n_batches <- 3
n_times <- 50
n_genes <- 5

# Create simulated 3D array [batch, time, gene]
data_array <- array(
  data = rpois(n_batches * n_times * n_genes, lambda = 10),
  dim = c(n_batches, n_times, n_genes),
  dimnames = list(
    paste0("batch", 1:n_batches),
    1:n_times,
    paste0("gene", 1:n_genes)
  )
)

# Add some patterns to make data more realistic
for (i in 1:n_genes) {
  for (b in 1:n_batches) {
    data_array[b, , i] <- data_array[b, , i] + 
      sin(seq(0, pi, length.out = n_times)) * 20 * (i/n_genes) * (b/n_batches)
  }
}

# Create output directory
dir.create("output", showWarnings = FALSE)

# Run models and save all outputs
models <- run_multiple_models(
  data_array,
  gene_indices = 1:3,  # Analyze first 3 genes only for speed
  n_samples = 1000,    # Reduced samples for faster execution
  parallel = FALSE,    # Set to TRUE for faster execution on multi-core systems
  n_cores = 1,
  save_metrics = TRUE,
  save_metrics_file = "output/gene_weights.h5",
  save_plots = TRUE,
  save_plots_dir = "output/plots",
  save_models = TRUE,
  save_models_dir = "output/models"
)

# Example of how to load and use a saved model
model_file <- "output/models/gene1_model.rds"
if (file.exists(model_file)) {
  model <- readRDS(model_file)
  print("Loaded saved model:")
  print(names(model))
  
  # You can now use the model for additional analysis
  print("Array weights from loaded model:")
  print(head(model$array_weights))
}

# If rhdf5 package is installed, demonstrate loading HDF5 file in R
if (requireNamespace("rhdf5", quietly = TRUE)) {
  h5_file <- "output/gene_weights.h5"
  if (file.exists(h5_file)) {
    print("Examining HDF5 file structure:")
    # List available groups in the file
    h5_groups <- rhdf5::h5ls(h5_file)
    print(h5_groups)
    
    # Example of reading data for a specific gene
    gene1_path <- "array_weights/gene1"
    
    # Open the file
    h5_fid <- rhdf5::H5Fopen(h5_file)
    
    # Check if the gene path exists
    gene_exists <- rhdf5::H5Lexists(h5_fid, gene1_path)
    
    # Close the file
    rhdf5::H5Fclose(h5_fid)
    
    if (file.exists(h5_file) && gene_exists) {
      # Read all metrics for gene1
      gene1_weights <- list()
      metrics <- rhdf5::h5read(h5_file, "metadata/metric_names")
      gene1_weights$array <- rhdf5::h5read(h5_file, paste0(gene1_path, "/array"))
      
      for (metric in metrics) {
        metric_path <- paste0(gene1_path, "/", metric)
        
        # Open the file
        h5_fid <- rhdf5::H5Fopen(h5_file)
        
        # Check if the metric exists
        metric_exists <- rhdf5::H5Lexists(h5_fid, metric_path)
        
        # Close the file
        rhdf5::H5Fclose(h5_fid)
        
        if (metric_exists) {
          gene1_weights[[metric]] <- rhdf5::h5read(h5_file, metric_path)
        }
      }
      
      # Convert to data frame
      gene1_df <- data.frame(gene1_weights)
      print("Loaded gene1 weights from HDF5:")
      print(head(gene1_df))
    }
  }
}

# Usage example for adding more data to an existing HDF5 file
if (requireNamespace("rhdf5", quietly = TRUE)) {
  h5_file <- "output/gene_weights.h5"
  if (file.exists(h5_file)) {
    print("Adding an additional gene to the HDF5 file...")
    
    # Run model for an additional gene
    gene4_model <- run_trajectory_model(data_array, 4, n_samples = 1000)
    
    # Add the results to the existing HDF5 file
    if (!is.null(gene4_model)) {
      gene_weights <- gene4_model$array_weights
      gene_path <- "array_weights/gene4"
      
      # Check if the gene group exists and create if needed
      h5_fid <- rhdf5::H5Fopen(h5_file)
      if (!rhdf5::H5Lexists(h5_fid, gene_path)) {
        rhdf5::H5Fclose(h5_fid)
        rhdf5::h5createGroup(h5_file, gene_path)
      } else {
        rhdf5::H5Fclose(h5_fid)
      }
      
      # Save array weights dataframe components
      metrics_cols <- c("Estimate", "Est.Error", "Q2.5", "Q97.5", "shape", "weight", "weight_norm")
      for (col in metrics_cols) {
        if (col %in% colnames(gene_weights)) {
          col_path <- paste0(gene_path, "/", col)
          rhdf5::h5write(gene_weights[[col]], h5_file, col_path)
        }
      }
      
      # Save array information
      array_path <- paste0(gene_path, "/array")
      rhdf5::h5write(gene_weights$array, h5_file, array_path)
      
      print("Successfully added gene4 to the HDF5 file")
    }
  }
} 