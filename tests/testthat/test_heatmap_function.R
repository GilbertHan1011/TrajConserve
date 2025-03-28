# Script to test the plot_hdf5_heatmap function
source("R/extract_hdf5_metrics.R")
library(rhdf5)
library(pheatmap)

# File path
h5_file <- "data/test1.hdf5"

cat("Testing plot_hdf5_heatmap function...\n")

# Test with default parameters (Estimate metric)
cat("Creating heatmap with default parameters...\n")
pdf("data/heatmap_default.pdf", width=10, height=8)
heatmap1 <- plot_hdf5_heatmap(h5_file)
dev.off()

# Test with Est.Error metric and row scaling
cat("Creating heatmap with Est.Error metric and row scaling...\n")
pdf("data/heatmap_error_scaled.pdf", width=10, height=8)
heatmap2 <- plot_hdf5_heatmap(h5_file, metric="Est.Error", scale="row")
dev.off()

# Test with custom colors and no clustering
cat("Creating heatmap with custom colors and no clustering...\n")
pdf("data/heatmap_custom.pdf", width=10, height=8)
heatmap3 <- plot_hdf5_heatmap(
  h5_file, 
  metric="Estimate", 
  cluster_rows=FALSE, 
  cluster_cols=FALSE,
  color=colorRampPalette(c("navy", "white", "firebrick3"))(50)
)
dev.off()

cat("All heatmaps created successfully. Check the data directory.\n")
cat("Test completed!\n")
