# Simple script to extract metrics from HDF5 file and plot heatmaps
source("R/extract_hdf5_metrics.R")
library(rhdf5)
library(pheatmap)

# File path to test data
h5_file <- "data/test1.hdf5"

# 1. Extract Estimate values
cat("Extracting estimates from HDF5 file...\n")
estimate_matrix <- extract_hdf5_metric(h5_file, "Estimate")
cat("Estimate matrix created with dimensions:", nrow(estimate_matrix), "rows x", 
    ncol(estimate_matrix), "columns\n")
cat("Values:\n")
print(estimate_matrix)

# 2. Extract Est.Error values
cat("\nExtracting Est.Error values...\n")
error_matrix <- extract_hdf5_metric(h5_file, "Est.Error")
cat("Est.Error matrix dimensions:", nrow(error_matrix), "rows x", ncol(error_matrix), "columns\n")
cat("Values:\n")
print(error_matrix)

# 3. Create basic heatmap
cat("\nCreating basic heatmap...\n")
pdf("data/estimates_heatmap_basic.pdf", width=10, height=8)
pheatmap(estimate_matrix, main="Gene Estimates Heatmap")
dev.off()
cat("Heatmap saved to data/estimates_heatmap_basic.pdf\n")

# 4. Create row-scaled heatmap
cat("\nCreating row-scaled heatmap...\n")
pdf("data/estimates_heatmap_rowscaled.pdf", width=10, height=8)
pheatmap(estimate_matrix, scale="row", main="Row-scaled Gene Estimates")
dev.off()
cat("Heatmap saved to data/estimates_heatmap_rowscaled.pdf\n")

# 5. Create heatmap with custom colors
cat("\nCreating heatmap with custom colors...\n")
pdf("data/estimates_heatmap_custom.pdf", width=10, height=8)
pheatmap(
  estimate_matrix,
  color = colorRampPalette(c("navy", "white", "firebrick3"))(50),
  main="Gene Estimates with Custom Colors"
)
dev.off()
cat("Heatmap saved to data/estimates_heatmap_custom.pdf\n")

# 6. Create heatmap with annotations
cat("\nCreating heatmap with annotations...\n")
# Create annotation data frame
annot_rows <- data.frame(
  Batch = factor(rownames(estimate_matrix)),
  row.names = rownames(estimate_matrix)
)

# Create annotation colors
batch_colors <- rainbow(nrow(estimate_matrix))
names(batch_colors) <- rownames(estimate_matrix)
annot_colors <- list(Batch = batch_colors)

pdf("data/estimates_heatmap_annotated.pdf", width=10, height=8)
pheatmap(
  estimate_matrix,
  annotation_row = annot_rows,
  annotation_colors = annot_colors,
  main="Gene Estimates with Batch Annotations"
)
dev.off()
cat("Heatmap saved to data/estimates_heatmap_annotated.pdf\n")

cat("\nAll operations completed successfully!\n") 