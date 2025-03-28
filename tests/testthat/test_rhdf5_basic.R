# Basic test script for rhdf5 functionality
# This script tests basic HDF5 operations using the rhdf5 package

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

cat("\nStarting basic rhdf5 functionality tests...\n")

# Create a temporary file for testing
temp_dir <- tempdir()
test_h5_file <- file.path(temp_dir, "test_rhdf5.h5")
cat("Test HDF5 file will be created at:", test_h5_file, "\n")

# Test 1: Basic HDF5 operations
cat("\nTest 1: Basic HDF5 operations\n")
tryCatch({
  # Create a file
  result <- h5createFile(test_h5_file)
  cat("h5createFile result:", result, "\n")
  
  if (!file.exists(test_h5_file)) {
    stop("Failed to create HDF5 file")
  } else {
    cat("✓ HDF5 file created successfully\n")
  }
  
  # Create a group
  result <- h5createGroup(test_h5_file, "testgroup")
  cat("h5createGroup result:", result, "\n")
  
  # Check if group exists
  fid <- H5Fopen(test_h5_file)
  result <- H5Lexists(fid, "testgroup")
  cat("H5Lexists result for testgroup:", result, "\n")
  
  if (!result) {
    H5Fclose(fid)
    stop("Failed to create HDF5 group")
  } else {
    cat("✓ HDF5 group created successfully\n")
    H5Fclose(fid)
  }
  
  # Write some data
  test_data <- 1:5
  cat("Original test data:\n")
  print(test_data)
  
  h5write(test_data, test_h5_file, "testdata")
  cat("Data written to HDF5 file\n")
  
  # Read back and verify
  read_data <- h5read(test_h5_file, "testdata")
  cat("Read data from HDF5 file:\n")
  print(read_data)
  
  # Check if values match (not using identical since class will differ)
  if (length(test_data) != length(read_data) || !all(test_data == read_data)) {
    stop("Data values read from HDF5 file do not match original")
  } else {
    cat("✓ Data values match (original: ", class(test_data), 
        ", read: ", class(read_data), ")\n")
  }
  
  # Test nested groups
  h5createGroup(test_h5_file, "testgroup/nestedgroup")
  
  fid <- H5Fopen(test_h5_file)
  if (!H5Lexists(fid, "testgroup/nestedgroup")) {
    H5Fclose(fid)
    stop("Failed to create nested HDF5 group")
  } else {
    cat("✓ Nested HDF5 group created successfully\n")
    H5Fclose(fid)
  }
  
  # Write data to nested group
  test_data2 <- test_data * 2
  h5write(test_data2, test_h5_file, "testgroup/nestedgroup/data")
  
  # Read back and verify
  read_nested_data <- h5read(test_h5_file, "testgroup/nestedgroup/data")
  
  # Check if values match
  if (length(test_data2) != length(read_nested_data) || !all(test_data2 == read_nested_data)) {
    stop("Data values read from nested group do not match original")
  } else {
    cat("✓ Data values in nested group match\n")
  }
  
  # Print file structure
  cat("\nHDF5 file structure:\n")
  print(h5ls(test_h5_file))
  
  cat("\n✓ All basic HDF5 operations tests passed\n")
}, error = function(e) {
  cat("✗ Basic HDF5 operations test failed:", e$message, "\n")
})

# Clean up
if (file.exists(test_h5_file)) {
  file.remove(test_h5_file)
  cat("Test HDF5 file removed\n")
}

cat("\nBasic rhdf5 functionality tests completed.\n") 