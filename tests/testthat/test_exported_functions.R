# Test script to verify that the functions are properly exported
library(TrajConserve)

# Check if the functions are available
cat("Checking if extract_hdf5_metric is exported: ", 
    exists("extract_hdf5_metric", mode="function"), "\n")
cat("Checking if plot_hdf5_heatmap is exported: ", 
    exists("plot_hdf5_heatmap", mode="function"), "\n")

# Print function documentation if available
if (exists("extract_hdf5_metric", mode="function")) {
  cat("\nHelp for extract_hdf5_metric:\n")
  cat(capture.output(args(extract_hdf5_metric)), sep="\n")
}

if (exists("plot_hdf5_heatmap", mode="function")) {
  cat("\nHelp for plot_hdf5_heatmap:\n")
  cat(capture.output(args(plot_hdf5_heatmap)), sep="\n")
}

# Test with an existing HDF5 file if available
h5_file <- "data/test1.hdf5"
if (file.exists(h5_file) && 
    exists("extract_hdf5_metric", mode="function") && 
    requireNamespace("rhdf5", quietly = TRUE)) {
  cat("\nTesting extract_hdf5_metric with", h5_file, "...\n")
  tryCatch({
    result <- extract_hdf5_metric(h5_file, "Estimate")
    cat("Function executed successfully!\n")
    cat("Result dimensions:", dim(result)[1], "x", dim(result)[2], "\n")
    print(result)
  }, error = function(e) {
    cat("Error:", e$message, "\n")
  })
  
  if (exists("plot_hdf5_heatmap", mode="function") && 
      requireNamespace("pheatmap", quietly = TRUE)) {
    cat("\nTesting plot_hdf5_heatmap...\n")
    tryCatch({
      pdf("data/test_export_heatmap.pdf", width=10, height=8)
      plot_hdf5_heatmap(h5_file, "Estimate")
      dev.off()
      cat("Heatmap created successfully at data/test_export_heatmap.pdf\n")
    }, error = function(e) {
      cat("Error:", e$message, "\n")
    })
  }
}

cat("\nTest completed.\n") 