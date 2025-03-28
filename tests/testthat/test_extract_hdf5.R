# Test script for HDF5 extraction and heatmap functions
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

# Check if file exists
if (!file.exists(h5_file)) {
  cat("Test file does not exist at", h5_file, "\n")
  
  # Create a directory if it doesn't exist
  if (!dir.exists("data")) {
    dir.create("data")
  }
  
  # Create a test HDF5 file
  library(rhdf5)
  
  cat("Creating a test HDF5 file...\n")
  
  # Create HDF5 file
  h5createFile(h5_file)
  
  # Create groups
  h5createGroup(h5_file, "array_weights")
  h5createGroup(h5_file, "metadata")
  
  # Create some gene groups with data
  gene_names <- c("gene1", "gene2", "gene3", "gene4")
  array_names <- c("batch1", "batch2", "batch3")
  
  # Add metadata
  metrics <- c("Estimate", "Est.Error", "Q2.5", "Q97.5")
  h5write(metrics, h5_file, "metadata/metric_names")
  
  # Add data for each gene
  set.seed(123)  # For reproducibility
  for (gene in gene_names) {
    gene_path <- paste0("array_weights/", gene)
    h5createGroup(h5_file, gene_path)
    
    # Create random estimates
    estimates <- runif(length(array_names), min = 0, max = 10)
    h5write(estimates, h5_file, paste0(gene_path, "/Estimate"))
    
    # Create random est.errors
    est_errors <- runif(length(array_names), min = 0, max = 2)
    h5write(est_errors, h5_file, paste0(gene_path, "/Est.Error"))
    
    # Add array names
    h5write(array_names, h5_file, paste0(gene_path, "/array"))
  }
  
  cat("Test HDF5 file created at", h5_file, "\n")
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
  
  cat("Example values:\n")
  print(estimate_matrix[1:min(3, nrow(estimate_matrix)), 1:min(3, ncol(estimate_matrix))])
  
  # Extract Est.Error
  error_matrix <- extract_hdf5_metric(h5_file, "Est.Error")
  cat("\nSuccessfully extracted Est.Error matrix with dimensions", 
      dim(error_matrix)[1], "x", dim(error_matrix)[2], "\n")
  
  cat("Extract function tests passed!\n")
}, error = function(e) {
  cat("Error in extract_hdf5_metric function:", e$message, "\n")
})

# Test plot_hdf5_heatmap function
cat("\nTesting plot_hdf5_heatmap function...\n")
tryCatch({
  # Create PDF file for the heatmap
  pdf_file <- "data/hdf5_heatmap_test.pdf"
  pdf(pdf_file, width = 10, height = 8)
  
  # Plot heatmap
  heatmap_plot <- plot_hdf5_heatmap(h5_file, "Estimate")
  
  # Close the PDF device
  dev.off()
  
  cat("Heatmap created and saved to", pdf_file, "\n")
  
  # Try with different metric
  pdf(gsub(".pdf", "_error.pdf", pdf_file), width = 10, height = 8)
  heatmap_plot <- plot_hdf5_heatmap(h5_file, "Est.Error", scale = "row")
  dev.off()
  
  cat("Est.Error heatmap created and saved\n")
  
  cat("Heatmap function tests passed!\n")
}, error = function(e) {
  cat("Error in plot_hdf5_heatmap function:", e$message, "\n")
})

cat("\nAll tests completed!\n") 