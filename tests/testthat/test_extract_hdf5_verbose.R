# Verbose test script for HDF5 extraction and heatmap functions
library(trajConserve)

# Source the functions directly for testing
source("R/extract_hdf5_metrics.R")

# Check if required packages are installed
if (!requireNamespace("rhdf5", quietly = TRUE)) {
  stop("Please install rhdf5: BiocManager::install('rhdf5')")
}
if (!requireNamespace("pheatmap", quietly = TRUE)) {
  stop("Please install pheatmap: install.packages('pheatmap')")
}

# File path
h5_file <- "data/test1.hdf5"

# Examine the HDF5 file structure
cat("Examining HDF5 file structure...\n")
h5_structure <- rhdf5::h5ls(h5_file)
print(h5_structure)

# List all genes in the file
gene_groups <- h5_structure[h5_structure$group == "/array_weights" & h5_structure$otype == "H5I_GROUP", "name"]
cat("\nGenes found in the HDF5 file:", paste(gene_groups, collapse=", "), "\n")

# Check if metadata exists
if (any(h5_structure$group == "/metadata")) {
  cat("\nMetadata group exists\n")
  if ("metric_names" %in% h5_structure$name[h5_structure$group == "/metadata"]) {
    metrics <- rhdf5::h5read(h5_file, "metadata/metric_names")
    cat("Available metrics:", paste(metrics, collapse=", "), "\n")
  }
}

# Look at one gene in detail
if (length(gene_groups) > 0) {
  gene_to_examine <- gene_groups[1]
  cat("\nExamining gene:", gene_to_examine, "\n")
  
  # List items for this gene
  gene_items <- h5_structure[h5_structure$group == paste0("/array_weights/", gene_to_examine), ]
  print(gene_items)
  
  # Read array names
  array_names <- rhdf5::h5read(h5_file, paste0("array_weights/", gene_to_examine, "/array"))
  cat("Array names:", paste(array_names, collapse=", "), "\n")
  
  # Read Estimate values
  if ("Estimate" %in% gene_items$name) {
    estimates <- rhdf5::h5read(h5_file, paste0("array_weights/", gene_to_examine, "/Estimate"))
    cat("Estimate values:", paste(estimates, collapse=", "), "\n")
  }
}

# Test extract_hdf5_metric function
cat("\nTesting extract_hdf5_metric function...\n")
tryCatch({
  # Extract Estimate
  estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")
  cat("Extract function returned a matrix with", nrow(estimate_matrix), "rows and", 
      ncol(estimate_matrix), "columns\n")
  
  cat("Matrix rownames (batches/groups):", paste(rownames(estimate_matrix), collapse=", "), "\n")
  cat("Matrix colnames (genes):", paste(colnames(estimate_matrix), collapse=", "), "\n")
  
  cat("Full matrix values:\n")
  print(estimate_matrix)
  
  # Extract Est.Error
  error_matrix <- extract_hdf5_metric(h5_file, "Est.Error")
  cat("\nEst.Error matrix:\n")
  print(error_matrix)
  
  cat("Extract function tests passed!\n")
}, error = function(e) {
  cat("Error in extract_hdf5_metric function:", e$message, "\n")
})

# Test plot_hdf5_heatmap function
cat("\nTesting plot_hdf5_heatmap function...\n")
tryCatch({
  # Create PDF file for the heatmap
  pdf_file <- "data/hdf5_heatmap_test_verbose.pdf"
  pdf(pdf_file, width = 10, height = 8)
  
  # Plot heatmap
  heatmap_plot <- plot_hdf5_heatmap(h5_file, "Estimate")
  
  # Close the PDF device
  dev.off()
  
  cat("Heatmap created and saved to", pdf_file, "\n")
  cat("Heatmap function test passed!\n")
}, error = function(e) {
  cat("Error in plot_hdf5_heatmap function:", e$message, "\n")
})

cat("\nAll tests completed!\n") 