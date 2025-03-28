# TrajConserve

Trajectory Conservation Analysis Tools for Single-Cell Data

## Overview

`trajConserve` is an R package designed for analyzing trajectory conservation in single-cell data. It provides tools for:

1. Binning and transforming pseudotime data
2. Bayesian GAM regression modeling of expression trajectories
3. Visualization of trajectory models and conservation patterns

This package is particularly useful for identifying and comparing gene expression patterns across developmental trajectories in single-cell RNA-seq data from different conditions, tissues, or species.

## Installation

```r
# Install from GitHub
devtools::install_github("GilbertHan1011/TrajConserve")


```

## Quick Start

```r
library(trajConserve)

# Convert Seurat object to 3D trajectory array
trajectory_data <- seurat_to_trajectory_array(
  seurat_obj = your_seurat_object,
  pseudo_col = "your_pseudotime_column",
  project_col = "your_batch_column"
)

# Run model for a single gene
gene_idx <- 10  # Example gene index
model <- run_trajectory_model(trajectory_data$reshaped_data, gene_idx)

# Visualize results
plot_results_brms(model)

# Run multiple models in parallel
models <- run_multiple_models(
  trajectory_data$reshaped_data, 
  gene_indices = 1:20,  # First 20 genes
  parallel = TRUE, 
  n_cores = 4
)

# Run models and save metrics, plots, and models
models_with_saving <- run_multiple_models(
  trajectory_data$reshaped_data,
  gene_indices = 1:20,
  parallel = TRUE,
  n_cores = 4,
  save_metrics = TRUE,
  save_metrics_file = "output/gene_weights.h5",
  save_plots = TRUE,
  save_plots_dir = "output/plots",
  save_models = TRUE,
  save_models_dir = "output/models"
)

# Load and work with saved metrics in R
# ```r
# library(rhdf5)
# # List the HDF5 file structure
# h5ls("output/gene_weights.h5")
# 
# # Get the metric names
# metrics <- h5read("output/gene_weights.h5", "metadata/metric_names")
# 
# # Read data for gene1
# gene1_weights <- list()
# gene1_weights$array <- h5read("output/gene_weights.h5", "array_weights/gene1/array")
# 
# # Open the file to check for existence
# h5_file <- "output/gene_weights.h5"
# for (metric in metrics) {
#   metric_path <- paste0("array_weights/gene1/", metric)
#   
#   # Check if the metric exists for this gene using proper API
#   # Open the file
#   h5_fid <- H5Fopen(h5_file)
#   metric_exists <- H5Lexists(h5_fid, metric_path)
#   H5Fclose(h5_fid)
#   
#   if (metric_exists) {
#     gene1_weights[[metric]] <- h5read(h5_file, metric_path)
#   }
# }
# gene1_df <- data.frame(gene1_weights)
# ```
```

## Key Functions

- `seurat_to_trajectory_array()`: Converts a Seurat object to a 3D trajectory array
- `bayesian_gam_regression_nb_shape()`: Fits a Bayesian GAM model with negative binomial distribution
- `run_multiple_models()`: Runs models for multiple genes
- `plot_results_brms()`: Visualizes model results

## License

This package is released under the MIT License.