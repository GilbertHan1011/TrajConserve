# Example script for extracting and visualizing metrics from HDF5 files
# This demonstrates how to use the extract_hdf5_metric and plot_hdf5_heatmap functions

library(trajConserve)
library(pheatmap)  # For additional heatmap customization
library(viridis)   # For alternative color palettes (optional)

# -----------------------------------------------------------------------------
# Basic Usage
# -----------------------------------------------------------------------------

# Path to your HDF5 file created by run_multiple_models
h5_file <- "output/gene_weights.h5"  # Change to your file path

# Extract Estimate values into a matrix
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")

# Print the dimensions
cat("Matrix dimensions:", nrow(estimate_matrix), "rows (batches) ×", 
    ncol(estimate_matrix), "columns (genes)\n")

# Display part of the matrix
head(estimate_matrix[, 1:5])  # First 5 genes

# Create a simple heatmap
heatmap_plot <- plot_hdf5_heatmap(h5_file, "Estimate")

# -----------------------------------------------------------------------------
# Advanced Customization
# -----------------------------------------------------------------------------

# 1. Extract multiple metrics and compare them
weight_matrix <- extract_hdf5_metric(h5_file, "weight")
weight_norm_matrix <- extract_hdf5_metric(h5_file, "weight_norm")

# 2. Create customized heatmaps
# Use different color palettes
pdf("output/custom_heatmap1.pdf", width=12, height=8)
plot_hdf5_heatmap(h5_file, "Estimate", 
                  color = colorRampPalette(c("navy", "white", "firebrick3"))(50))
dev.off()

# Scale by row to compare patterns across genes
pdf("output/custom_heatmap2.pdf", width=12, height=8)
plot_hdf5_heatmap(h5_file, "Estimate", scale="row")
dev.off()

# Disable clustering to preserve original order
pdf("output/custom_heatmap3.pdf", width=12, height=8)
plot_hdf5_heatmap(h5_file, "Estimate", cluster_rows=FALSE, cluster_cols=FALSE)
dev.off()

# 3. Create a heatmap with custom annotations (requires pheatmap)
if (requireNamespace("pheatmap", quietly = TRUE)) {
  # Extract data
  estimate_data <- extract_hdf5_metric(h5_file, "Estimate")
  
  # Create annotation data for batches
  batch_names <- rownames(estimate_data)
  batch_info <- data.frame(
    Batch = factor(batch_names),
    row.names = batch_names
  )
  
  # Custom colors for annotations
  anno_colors <- list(
    Batch = setNames(
      colorRampPalette(c("#1f78b4", "#a6cee3"))(length(batch_names)),
      batch_names
    )
  )
  
  # Create heatmap with annotations
  pdf("output/annotated_heatmap.pdf", width=12, height=8)
  pheatmap(
    estimate_data,
    annotation_row = batch_info,
    annotation_colors = anno_colors,
    main = "Gene Expression Estimates with Batch Annotation",
    fontsize = 8,
    fontsize_row = 8,
    fontsize_col = 6
  )
  dev.off()
}

# -----------------------------------------------------------------------------
# Advanced Analysis
# -----------------------------------------------------------------------------

# Find genes with highest variation across batches
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")
gene_vars <- apply(estimate_matrix, 2, var)
top_var_genes <- names(sort(gene_vars, decreasing = TRUE))[1:10]  # Top 10 most variable genes

# Create a heatmap of only the most variable genes
if (length(top_var_genes) > 0) {
  pdf("output/top_variable_genes.pdf", width=10, height=8)
  pheatmap(
    estimate_matrix[, top_var_genes],
    main = "Top 10 Most Variable Genes",
    scale = "row"
  )
  dev.off()
}

# -----------------------------------------------------------------------------
# Comparing Multiple Metrics
# -----------------------------------------------------------------------------

# Create a function to generate a comparison of multiple metrics
compare_metrics <- function(h5_file, metrics = c("Estimate", "weight", "weight_norm"), gene_subset = NULL) {
  # Create a list to store matrices
  result <- list()
  
  # Extract each metric
  for (metric in metrics) {
    tryCatch({
      matrix_data <- extract_hdf5_metric(h5_file, metric)
      
      # Apply gene subset if provided
      if (!is.null(gene_subset) && all(gene_subset %in% colnames(matrix_data))) {
        matrix_data <- matrix_data[, gene_subset]
      }
      
      result[[metric]] <- matrix_data
    }, error = function(e) {
      warning(paste("Could not extract metric", metric, ":", e$message))
    })
  }
  
  # Return the list of matrices
  return(result)
}

# Use the function to compare metrics
metric_comparison <- compare_metrics(h5_file)

# Print the names of metrics successfully extracted
cat("Metrics extracted:", paste(names(metric_comparison), collapse=", "), "\n") 