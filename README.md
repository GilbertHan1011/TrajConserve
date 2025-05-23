# TrajConserve

[![pkgdown](https://github.com/GilbertHan1011/TrajConserve/actions/workflows/pkgdown.yml/badge.svg)](https://github.com/GilbertHan1011/TrajConserve/actions/workflows/pkgdown.yml)
[![Website](https://img.shields.io/badge/website-online-blue.svg)](https://GilbertHan1011.github.io/TrajConserve/)

Trajectory Conservation Analysis Tools for Single-Cell Trajectories

## Overview

`TrajConserve` is an R package designed for analyzing trajectory conservation among population-level single-cell trajectory datastes. It enables the identification of conserved and non-conserved gene expression patterns across developmental trajectories.

### Key Features

1. **Trajectory Modeling**: Bayesian GAM regression modeling of expression trajectories
2. **Conservation Analysis**: Quantify and visualize gene conservation across samples
3. **HDF5 Integration**: Efficient storage and retrieval of model results
4. **Visualization Tools**: Publication-ready plots of model results and conservation metrics

## Documentation

For detailed documentation, tutorials, and examples, visit our [website](https://GilbertHan1011.github.io/TrajConserve/). And if you want to know the statistical background of TrajConserve, you can visit this [website](https://scatlas.readthedocs.io/en/latest/trajectory/20250330_statistical_trajconserve.html)



## Installation

```r
# Install from GitHub
devtools::install_github("GilbertHan1011/TrajConserve")
```

## Dependencies

TrajConserve depends on several packages, including:

- **brms**: For Bayesian regression modeling via Stan
- **rhdf5**: For HDF5 file handling
- **ggplot2**: For visualization

Make sure to install these dependencies:

```r
# Install BiocManager if needed
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

# Install rhdf5
BiocManager::install("rhdf5")

# Install CRAN packages
install.packages(c("brms", "ggplot2", "pheatmap", "ggrepel"))
```

### Stan Setup (Important)

TrajConserve uses Stan for Bayesian modeling. By default, it uses the rstan backend, but for optimal performance, we strongly recommend installing and configuring cmdstanr:

```r
# Install cmdstanr from Stan R-universe (recommended method)
install.packages("cmdstanr", repos = c('https://stan-dev.r-universe.dev', getOption("repos")))


# Install cmdstan
cmdstanr::check_cmdstan_toolchain(fix = TRUE)
options(timeout = 600)  # Set a longer timeout for downloading
cmdstanr::install_cmdstan(cores = 2)
```

These settings ensure Stan can properly compile with your C++ environment. After installing cmdstanr, you can use it by setting `backend = "cmdstanr"` in the modeling functions. 

## Quick Start

### Trajectory Modeling

```r
library(TrajConserve)

# Convert Seurat object to 3D trajectory array
trajectory_data <- seurat_to_trajectory_array(
  seurat_obj = your_seurat_object,
  assay = "RNA",
  pseudo_col = "pseudotime",
  project_col = "sample_id",
  genes = c("Gene1", "Gene2", "Gene3", "Gene4")
)

# Run multiple models and save to HDF5
# Using default rstan backend
run_multiple_models(
  data_array = trajectory_data$reshaped_data,
  gene_indices = 1:20,
  parallel = TRUE,
  n_cores = 4,
  save_metrics = TRUE,
  save_metrics_file = "trajectory_models.h5",
  save_plots = TRUE
)

# Or, if cmdstanr is installed, you can use it for better performance:
# run_multiple_models(
#   data_array = trajectory_data$reshaped_data,
#   gene_indices = 1:20,
#   parallel = TRUE,
#   n_cores = 4,
#   save_metrics = TRUE,
#   save_metrics_file = "trajectory_models.h5",
#   save_plots = TRUE,
#   backend = "cmdstanr"
# )
```

### Conservation Analysis

```r
# Calculate conservation scores
conservation_results <- calculate_conservation(
  h5_file = "trajectory_models.h5",
  metric = "Estimate",
  mean_weight = 0.6,
  variability_weight = 0.4,
  conservation_threshold = 0.7
)

# View results
head(conservation_results)

# Create visualizations
# Scatter plot
plot_conservation(
  conservation_results,
  plot_type = "scatter",
  highlight_n = 10,
  file_path = "figures/conservation_scatter.pdf"
)

# Histogram
plot_conservation(
  conservation_results,
  plot_type = "histogram",
  file_path = "figures/conservation_histogram.pdf"
)

# Extract data for heatmap
estimate_matrix <- extract_hdf5_metric("trajectory_models.h5", "Estimate")

# Create heatmap using pheatmap
library(pheatmap)
gene_type <- ifelse(conservation_results$is_conserved, "Conserved", "Non-conserved")
gene_anno <- data.frame(
  Conservation = factor(gene_type, levels = c("Conserved", "Non-conserved")),
  row.names = conservation_results$gene
)

# Create heatmap
pheatmap(t(estimate_matrix), 
         annotation_row = gene_anno,
         main = "Expression Patterns of Conserved vs Non-conserved Genes")
```

## Key Functions

**Trajectory Analysis**
- `seurat_to_trajectory_array()`: Converts a Seurat object to a 3D trajectory array
- `bayesian_gam_regression_nb_shape()`: Fits a Bayesian GAM model with negative binomial distribution
- `run_multiple_models()`: Runs models for multiple genes
- `plot_results_brms()`: Visualizes model results

**Conservation Analysis**
- `calculate_conservation()`: Calculates conservation scores for genes
- `plot_conservation()`: Creates visualizations of conservation results
- `extract_hdf5_metric()`: Extracts metrics from HDF5 files

**HDF5 Utilities**
- `extract_hdf5_metric()`: Extract metrics from HDF5 files
- `plot_hdf5_heatmap()`: Create heatmaps from HDF5 data



## License

This package is released under the MIT License.