# Simple script to examine the HDF5 file structure
library(rhdf5)

# File path
h5_file <- "data/test1.hdf5"

# Print if file exists
cat("File exists:", file.exists(h5_file), "\n")

# Examine the HDF5 file structure
cat("HDF5 file structure:\n")
h5_structure <- h5ls(h5_file)
print(h5_structure)

# Get all genes (groups under array_weights)
gene_groups <- h5_structure[h5_structure$group == "/array_weights" & h5_structure$otype == "H5I_GROUP", "name"]
cat("\nGenes found:", paste(gene_groups, collapse=", "), "\n")

# Check first gene
if (length(gene_groups) > 0) {
  gene <- gene_groups[1]
  cat("\nExamining gene:", gene, "\n")
  
  # Read array names
  array_names <- h5read(h5_file, paste0("array_weights/", gene, "/array"))
  cat("Array names:", paste(array_names, collapse=", "), "\n")
  
  # Read Estimate values if they exist
  estimate_path <- paste0("array_weights/", gene, "/Estimate")
  fid <- H5Fopen(h5_file)
  if (H5Lexists(fid, estimate_path)) {
    H5Fclose(fid)
    estimates <- h5read(h5_file, estimate_path)
    cat("Estimate values:", paste(estimates, collapse=", "), "\n")
  } else {
    H5Fclose(fid)
    cat("No Estimate values found for this gene\n")
  }
} 