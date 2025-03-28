# Script to test the extract_hdf5_metric function
source("R/extract_hdf5_metrics.R")
library(rhdf5)

# File path
h5_file <- "data/test1.hdf5"

cat("Testing extract_hdf5_metric function...\n")

# Extract the Estimate metric
cat("Extracting Estimate metric...\n")
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")

cat("Matrix dimensions:", nrow(estimate_matrix), "rows x", ncol(estimate_matrix), "columns\n")
cat("Row names (batches):", paste(rownames(estimate_matrix), collapse=", "), "\n")
cat("Column names (genes):", paste(colnames(estimate_matrix), collapse=", "), "\n")

cat("\nEstimate matrix values:\n")
print(estimate_matrix)

# Extract the Est.Error metric
cat("\nExtracting Est.Error metric...\n")
error_matrix <- extract_hdf5_metric(h5_file, "Est.Error")

cat("Matrix dimensions:", nrow(error_matrix), "rows x", ncol(error_matrix), "columns\n")
cat("\nEst.Error matrix values:\n")
print(error_matrix)

# Try plotting the heatmap
cat("\nSaving heatmap to PDF...\n")
pdf("data/estimates_heatmap.pdf", width=10, height=8)
library(pheatmap)
pheatmap(estimate_matrix, main="Estimate Values Heatmap")
dev.off()

cat("\nTest completed successfully!\n") 