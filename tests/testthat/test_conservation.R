# Test script for gene conservation analysis functions
library(TrajConserve)

# Load required libraries
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
if (!requireNamespace("rhdf5", quietly = TRUE)) {
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }
  BiocManager::install("rhdf5")
}
if (!requireNamespace("pheatmap", quietly = TRUE)) {
  install.packages("pheatmap")
}
if (!requireNamespace("ggrepel", quietly = TRUE)) {
  install.packages("ggrepel")
}

# Source the new functions directly for testing
source("R/calculate_conservation.R")

# File path to test data
h5_file <- "data/test1.hdf5"

# Verify the HDF5 file exists
if (!file.exists(h5_file)) {
  stop("Test HDF5 file not found. Please run the earlier test scripts to create it.")
}

# Print structure of the HDF5 file
cat("HDF5 file structure:\n")
h5_structure <- rhdf5::h5ls(h5_file)
print(h5_structure)

# Extract metrics to verify data
cat("\nExtracting estimate matrix for verification...\n")
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")
cat("Estimate matrix dimensions:", nrow(estimate_matrix), "×", ncol(estimate_matrix), "\n")
print(estimate_matrix)

# Calculate gene conservation scores
cat("\nCalculating gene conservation scores...\n")
conservation_results <- calculate_conservation(
  h5_file = h5_file,
  metric = "Estimate",
  weight_mean = 0.6,  # Weigh mean estimate slightly higher
  weight_var = 0.4,   # Weigh variability slightly lower
  conservation_threshold = 0.5,
  normalize_scores = TRUE
)

# Print the conservation results
cat("\nConservation results:\n")
print(conservation_results)

# Create output directory if it doesn't exist
if (!dir.exists("output")) {
  dir.create("output")
}

# Create scatter plot of conservation metrics
cat("\nCreating scatter plot of conservation metrics...\n")
pdf("output/conservation_scatter.pdf", width = 10, height = 8)
scatter_plot <- plot_conservation(
  conservation_results = conservation_results,
  plot_type = "scatter",
  highlight_n_top = 2,
  highlight_n_bottom = 2
)
print(scatter_plot)
dev.off()

# Create histogram of conservation scores
cat("\nCreating histogram of conservation scores...\n")
pdf("output/conservation_histogram.pdf", width = 10, height = 8)
histogram_plot <- plot_conservation(
  conservation_results = conservation_results,
  plot_type = "histogram"
)
print(histogram_plot)
dev.off()

# Create heatmap of conserved vs non-conserved genes
cat("\nCreating heatmap of conserved vs non-conserved genes...\n")
pdf("output/conservation_heatmap.pdf", width = 10, height = 8)
plot_conservation(
  conservation_results = conservation_results,
  plot_type = "heatmap",
  highlight_n_top = 2,
  highlight_n_bottom = 2,
  h5_file = h5_file
)
dev.off()

cat("\nAll plots saved in the output directory.\n")

# Simple validation analysis
cat("\nValidation analysis:\n")
cat("Number of genes classified as conserved:", sum(conservation_results$conserved), "\n")
cat("Number of genes classified as non-conserved:", sum(!conservation_results$conserved), "\n")

# Print top conserved and non-conserved genes
cat("\nTop conserved genes:\n")
top_genes <- conservation_results[conservation_results$conserved, ]
if (nrow(top_genes) > 0) {
  print(head(top_genes[, c("gene", "mean_estimate", "cv_estimate", "conservation_score")]))
} else {
  cat("No genes classified as conserved with the current threshold.\n")
}

cat("\nTop non-conserved genes:\n")
non_conserved_genes <- conservation_results[!conservation_results$conserved, ]
if (nrow(non_conserved_genes) > 0) {
  print(head(non_conserved_genes[, c("gene", "mean_estimate", "cv_estimate", "conservation_score")]))
} else {
  cat("No genes classified as non-conserved with the current threshold.\n")
}

cat("\nTest completed successfully!\n") 