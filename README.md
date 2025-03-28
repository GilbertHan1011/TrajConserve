# TrajConserve

[![pkgdown](https://github.com/GilbertHan1011/TrajConserve/actions/workflows/pkgdown.yml/badge.svg)](https://github.com/GilbertHan1011/TrajConserve/actions/workflows/pkgdown.yml)
[![Website](https://img.shields.io/badge/website-online-blue.svg)](https://GilbertHan1011.github.io/TrajConserve/)

Trajectory Conservation Analysis Tools for Single-Cell Data

## Overview

`TrajConserve` is an R package designed for analyzing trajectory conservation in single-cell data. It enables the identification of conserved and non-conserved gene expression patterns across developmental trajectories.

### Key Features

1. **Trajectory Modeling**: Bayesian GAM regression modeling of expression trajectories
2. **Conservation Analysis**: Quantify and visualize gene conservation across samples
3. **HDF5 Integration**: Efficient storage and retrieval of model results
4. **Visualization Tools**: Publication-ready plots of model results and conservation metrics

## Documentation

For detailed documentation, tutorials, and examples, visit our [website](https://GilbertHan1011.github.io/TrajConserve/).

The documentation website is automatically built and deployed using GitHub Actions whenever changes are pushed to the main branch.

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

TrajConserve uses Stan (via cmdstanr) for Bayesian modeling. To avoid C++ compilation issues, configure your environment:

```r
# Install cmdstanr
install.packages("remotes")
remotes::install_github("stan-dev/cmdstanr")

# Create necessary configuration files
# 1. Configure C++ compiler settings in ~/.R/Makevars
dir.create(file.path(Sys.getenv("HOME"), ".R"), showWarnings = FALSE)
cat('CXX14 = g++
CXX17 = g++
CXX14FLAGS = -O3 -march=native -mtune=native -fPIC
CXX17FLAGS = -O3 -march=native -mtune=native -fPIC
STAN_CXX17 = TRUE
STAN_HAS_CXX17 = TRUE
TBB_CXX_TYPE = gcc', 
file = file.path(Sys.getenv("HOME"), ".R", "Makevars"))

# 2. Configure cmdstan make settings
dir.create(file.path(Sys.getenv("HOME"), ".cmdstan", "make"), recursive = TRUE, showWarnings = FALSE)
cat('STAN_HAS_CXX17 = true
TBB_CXX_TYPE = gcc', 
file = file.path(Sys.getenv("HOME"), ".cmdstan", "make", "local"))

# Install cmdstan
cmdstanr::check_cmdstan_toolchain(fix = TRUE)
options(timeout = 600)  # Set a longer timeout for downloading
cmdstanr::install_cmdstan(cores = 2)
```

These settings ensure Stan can properly compile with your C++ environment. Without this configuration, you might encounter errors related to C++17 detection and TBB_CXX_TYPE settings.

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
run_multiple_models(
  data_array = trajectory_data$reshaped_data,
  gene_indices = 1:20,
  parallel = TRUE,
  n_cores = 4,
  save_metrics = TRUE,
  save_metrics_file = "trajectory_models.h5",
  save_plots = TRUE
)
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

## Website Development

The documentation website is automatically built and deployed using GitHub Actions whenever changes are pushed to the main branch.

To build the documentation website locally for testing:

```r
# Install pkgdown if needed
install.packages("pkgdown")

# Build the site
pkgdown::build_site()
```

Alternatively, run the included script:

```bash
Rscript build_site.R
```

The automated GitHub Actions workflow is defined in `.github/workflows/pkgdown.yml`.

## License

This package is released under the MIT License.