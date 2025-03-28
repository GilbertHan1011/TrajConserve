# Test script for the saveWeightsToHDF5 function
# This script tests the internal function without requiring the full package

# Print R version and information
cat("R version:", R.version.string, "\n")
cat("Working directory:", getwd(), "\n")

# Check for rhdf5 package
cat("Checking for rhdf5 package: ")
if (requireNamespace("rhdf5", quietly = TRUE)) {
  cat("INSTALLED\n")
  tryCatch({
    cat("  Package version:", as.character(packageVersion("rhdf5")), "\n")
  }, error = function(e) {
    cat("  Unable to determine package version\n")
  })
  library(rhdf5)
} else {
  cat("NOT INSTALLED\n")
  stop("rhdf5 is not installed. Please install it with BiocManager::install('rhdf5')")
}

cat("\nStarting saveWeightsToHDF5 function test...\n")

# Define a mock version of the saveWeightsToHDF5 function (copied from R/run_model.R)
# Updated to convert factors to character before writing
saveWeightsToHDF5 <- function(h5_file, group_path, weights_df) {
  # Create group for this gene if it doesn't exist
  # First check if file exists
  if (!file.exists(h5_file)) {
    rhdf5::h5createFile(h5_file)
  }
  
  # Open file to work with it
  file_id <- rhdf5::H5Fopen(h5_file)
  
  # Check if group exists and create if needed
  if (!rhdf5::H5Lexists(file_id, group_path)) {
    # Close the file first
    rhdf5::H5Fclose(file_id)
    # Create the group using high-level function
    rhdf5::h5createGroup(h5_file, group_path)
    # Reopen the file
    file_id <- rhdf5::H5Fopen(h5_file)
  }
  
  # Close the file now that we've checked/created the group
  rhdf5::H5Fclose(file_id)
  
  # Save array weights dataframe components using high-level functions
  metrics_cols <- c("Estimate", "Est.Error", "Q2.5", "Q97.5", "shape", "weight", "weight_norm")
  for (col in metrics_cols) {
    if (col %in% colnames(weights_df)) {
      col_path <- paste0(group_path, "/", col)
      rhdf5::h5write(weights_df[[col]], h5_file, col_path)
    }
  }
  
  # Save array information - convert factor to character first
  array_path <- paste0(group_path, "/array")
  array_values <- weights_df$array
  if (is.factor(array_values)) {
    array_values <- as.character(array_values)
  }
  rhdf5::h5write(array_values, h5_file, array_path)
}

# Create a temporary file for testing
temp_dir <- tempdir()
test_h5_file <- file.path(temp_dir, "test_weights.h5")
cat("Test HDF5 file will be created at:", test_h5_file, "\n")

# Test saveWeightsToHDF5 function
cat("\nTest: saveWeightsToHDF5 function\n")
tryCatch({
  # Create test data frame
  test_weights <- data.frame(
    array = factor(c("batch1", "batch2", "batch3")),
    Estimate = c(0.5, 0.7, 0.9),
    `Est.Error` = c(0.1, 0.1, 0.1),
    Q2.5 = c(0.3, 0.5, 0.7),
    Q97.5 = c(0.7, 0.9, 1.1),
    shape = c(1.0, 1.5, 2.0),
    weight = c(1.0, 1.5, 2.0),
    weight_norm = c(0.5, 0.75, 1.0)
  )
  
  cat("Test weights data frame created\n")
  cat("Columns:", paste(names(test_weights), collapse=", "), "\n")
  cat("array column is factor:", is.factor(test_weights$array), "\n")
  
  # Create file and root group for array_weights
  h5createFile(test_h5_file)
  h5createGroup(test_h5_file, "array_weights")
  
  # Call the function to save the weights
  cat("Calling saveWeightsToHDF5 function...\n")
  saveWeightsToHDF5(test_h5_file, "array_weights/gene1", test_weights)
  cat("Function call completed\n")
  
  # Verify file exists
  if (!file.exists(test_h5_file)) {
    stop("HDF5 file does not exist after function call")
  }
  cat("✓ HDF5 file exists\n")
  
  # Verify gene1 group exists
  fid <- H5Fopen(test_h5_file)
  if (!H5Lexists(fid, "array_weights/gene1")) {
    H5Fclose(fid)
    stop("array_weights/gene1 group missing from HDF5 file")
  }
  cat("✓ array_weights/gene1 group exists\n")
  H5Fclose(fid)
  
  # Check file structure
  cat("HDF5 file structure:\n")
  h5_structure <- h5ls(test_h5_file)
  print(h5_structure)
  
  # Check each metric was saved
  metrics_cols <- c("Estimate", "Est.Error", "Q2.5", "Q97.5", "shape", "weight", "weight_norm", "array")
  for (col in metrics_cols) {
    path <- paste0("array_weights/gene1/", col)
    
    # Check if metric exists
    fid <- H5Fopen(test_h5_file)
    exists <- H5Lexists(fid, path)
    H5Fclose(fid)
    
    if (!exists) {
      cat("✗ Metric", col, "not found in HDF5 file\n")
      if (col %in% names(test_weights)) {
        stop(paste("Metric", col, "missing from HDF5 file even though it's in the data frame"))
      }
    } else {
      cat("✓ Metric", col, "found in HDF5 file\n")
      
      # Read the data and verify values
      metric_data <- h5read(test_h5_file, path)
      
      if (col == "array") {
        # For factors, compare as.character to handle factor levels correctly
        original_values <- as.character(test_weights[[col]])
        read_values <- metric_data  # Should be character from h5write
      } else {
        original_values <- test_weights[[col]]
        read_values <- metric_data
      }
      
      # Check if values match
      if (length(original_values) != length(read_values) || !all(original_values == read_values)) {
        cat("Original:", original_values, "\n")
        cat("Read:", read_values, "\n")
        stop(paste("Values for metric", col, "do not match original data"))
      }
      cat("  ✓ Values match original data\n")
    }
  }
  
  cat("\n✓ saveWeightsToHDF5 function test passed\n")
}, error = function(e) {
  cat("✗ saveWeightsToHDF5 function test failed:", e$message, "\n")
})

# Clean up
if (file.exists(test_h5_file)) {
  file.remove(test_h5_file)
  cat("Test HDF5 file removed\n")
}

cat("\nsaveWeightsToHDF5 function test completed.\n") 