#!/usr/bin/env Rscript

# Test script for conservation analysis functions
# This script tests the calculate_conservation and plot_conservation functions

# Load required libraries
library(rhdf5)
library(ggplot2)
if (!requireNamespace("pheatmap", quietly = TRUE)) {
  install.packages("pheatmap")
}
if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel")
}

# Source the required functions
source("R/extract_hdf5_metric.R")
source("R/calculate_conservation.R")

# Run h5closeAll() to close any open HDF5 handles
if (exists("h5closeAll")) {
  h5closeAll()
}

# Set the HDF5 file path
h5_file <- "data/test1.hdf5"

# Check if the file exists
if (!file.exists(h5_file)) {
  stop("Test HDF5 file not found: ", h5_file)
}

# Print the HDF5 file structure
cat("HDF5 file structure:\n")
file_structure <- h5ls(h5_file)
print(file_structure)

# Extract the estimate matrix using our extract_hdf5_metric function
cat("\nExtracting metrics using extract_hdf5_metric function...\n")
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")

# Print dimensions of the estimate matrix
cat("\nEstimate matrix dimensions:", dim(estimate_matrix), "\n")
cat("Row names (arrays):", paste(rownames(estimate_matrix), collapse=", "), "\n")
cat("Column names (genes):", paste(colnames(estimate_matrix), collapse=", "), "\n")

# Calculate conservation scores
cat("\nCalculating conservation scores...\n")
conservation_results <- calculate_conservation(
  h5_file = h5_file,
  metric = "Estimate",
  mean_weight = 0.6,
  variability_weight = 0.4,
  conservation_threshold = 0.7,
  normalize_scores = TRUE
)

# Print conservation results summary
cat("\nConservation Results Summary:\n")
cat("Number of genes analyzed:", nrow(conservation_results), "\n")
cat("Number of conserved genes:", sum(conservation_results$is_conserved), "\n")
cat("Number of non-conserved genes:", sum(!conservation_results$is_conserved), "\n")

# Print top most conserved genes
cat("\nTop most conserved genes:\n")
top_conserved <- conservation_results[order(-conservation_results$conservation_score), ]
top_n <- min(5, nrow(top_conserved))
print(top_conserved[1:top_n, c("gene", "conservation_score", "is_conserved", "mean_estimate", "cv")])

# Print least conserved genes
cat("\nLeast conserved genes:\n")
bottom_conserved <- conservation_results[order(conservation_results$conservation_score), ]
bottom_n <- min(5, nrow(bottom_conserved))
print(bottom_conserved[1:bottom_n, c("gene", "conservation_score", "is_conserved", "mean_estimate", "cv")])

# Create output directory if it doesn't exist
output_dir <- "output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
}

# Generate plots
cat("\nGenerating plots...\n")

# Scatter plot
scatter_file <- file.path(output_dir, "conservation_scatter.pdf")
plot_conservation(
  conservation_results,
  plot_type = "scatter",
  highlight_n = 10,
  file_path = scatter_file
)
cat("Created scatter plot:", scatter_file, "\n")

# Histogram plot
hist_file <- file.path(output_dir, "conservation_histogram.pdf")
plot_conservation(
  conservation_results,
  plot_type = "histogram",
  file_path = hist_file
)
cat("Created histogram plot:", hist_file, "\n")

# Heatmap plot - Create directly instead of using plot_conservation
heatmap_file <- file.path(output_dir, "conservation_heatmap.pdf")

# Prepare data for heatmap
# Create annotation for conserved vs non-conserved genes
gene_type <- ifelse(conservation_results$is_conserved, "Conserved", "Non-conserved")
gene_anno <- data.frame(
  Conservation = factor(gene_type, levels = c("Conserved", "Non-conserved")),
  row.names = conservation_results$gene
)

# Define colors for annotation
anno_colors <- list(
  Conservation = c(Conserved = "blue", `Non-conserved` = "red")
)

# Create heatmap
pdf(heatmap_file)
pheatmap::pheatmap(t(estimate_matrix), 
         annotation_row = gene_anno,
         annotation_colors = anno_colors,
         main = "Expression Patterns of Conserved vs Non-conserved Genes",
         cluster_rows = TRUE,
         cluster_cols = TRUE)
dev.off()
cat("Created heatmap plot:", heatmap_file, "\n")

# Close any open HDF5 handles
if (exists("h5closeAll")) {
  h5closeAll()
}

cat("\nTest completed successfully!\n")