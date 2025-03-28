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
# devtools::install_github("GilbertHan1011/TrajConserve")


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
```

## Key Functions

- `seurat_to_trajectory_array()`: Converts a Seurat object to a 3D trajectory array
- `bayesian_gam_regression_nb_shape()`: Fits a Bayesian GAM model with negative binomial distribution
- `run_multiple_models()`: Runs models for multiple genes
- `plot_results_brms()`: Visualizes model results

## License

This package is released under the MIT License.