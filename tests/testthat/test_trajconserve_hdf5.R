# Comprehensive test script for TrajConserve HDF5 integration
# This script tests that rhdf5 operations work correctly within the package

# Print R version and information about installed packages
cat("R version:", R.version.string, "\n")
cat("Working directory:", getwd(), "\n")

# Check for required packages with more detailed information
cat("Checking for required packages:\n")

cat("trajConserve package: ")
if (requireNamespace("trajConserve", quietly = TRUE)) {
  cat("INSTALLED\n")
  cat("  Package version:", packageVersion("trajConserve"), "\n")
} else {
  cat("NOT INSTALLED\n")
  stop("trajConserve package is not installed. Please install it first.")
}

cat("rhdf5 package: ")
if (requireNamespace("rhdf5", quietly = TRUE)) {
  cat("INSTALLED\n")
  cat("  Package version:", packageVersion("rhdf5"), "\n")
  library(rhdf5)
} else {
  cat("NOT INSTALLED\n")
  stop("rhdf5 is not installed. Please install it with BiocManager::install('rhdf5')")
}

cat("\nStarting TrajConserve HDF5 integration tests...\n")

# Create a temporary directory for test outputs
temp_dir <- tempdir()
test_h5_file <- file.path(temp_dir, "test_metrics.h5")
cat("Test HDF5 file will be created at:", test_h5_file, "\n")

# Create test data
cat("Creating test data...\n")
set.seed(42)
n_batches <- 2
n_times <- 10
n_genes <- 3

# Create simulated 3D array [batch, time, gene]
data_array <- array(
  data = rpois(n_batches * n_times * n_genes, lambda = 5),
  dim = c(n_batches, n_times, n_genes),
  dimnames = list(
    paste0("batch", 1:n_batches),
    1:n_times,
    paste0("gene", 1:n_genes)
  )
)

# Add some patterns to make data more realistic
for (i in 1:n_genes) {
  for (b in 1:n_batches) {
    data_array[b, , i] <- data_array[b, , i] + 
      sin(seq(0, pi, length.out = n_times)) * 10 * (i/n_genes) * (b/n_batches)
  }
}

# Test 1: Basic HDF5 operations with rhdf5
cat("\nTest 1: Basic HDF5 operations\n")
tryCatch({
  # Create a file
  rhdf5::h5createFile(test_h5_file)
  if (!file.exists(test_h5_file)) {
    stop("Failed to create HDF5 file")
  } else {
    cat("✓ HDF5 file created successfully\n")
  }
  
  # Create a group
  rhdf5::h5createGroup(test_h5_file, "testgroup")
  
  # Check if group exists
  fid <- rhdf5::H5Fopen(test_h5_file)
  if (!rhdf5::H5Lexists(fid, "testgroup")) {
    rhdf5::H5Fclose(fid)
    stop("Failed to create HDF5 group")
  } else {
    cat("✓ HDF5 group created successfully\n")
    rhdf5::H5Fclose(fid)
  }
  
  # Write some data
  test_data <- 1:5
  rhdf5::h5write(test_data, test_h5_file, "testdata")
  
  # Read back and verify
  read_data <- rhdf5::h5read(test_h5_file, "testdata")
  if (!identical(test_data, read_data)) {
    stop("Data read from HDF5 file does not match original")
  } else {
    cat("✓ Data written and read successfully\n")
  }
  
  # Delete the file to start fresh for next test
  file.remove(test_h5_file)
  cat("✓ Basic HDF5 operations test passed\n")
}, error = function(e) {
  cat("✗ Basic HDF5 operations test failed:", e$message, "\n")
  # Clean up
  if (file.exists(test_h5_file)) {
    file.remove(test_h5_file)
  }
})

# Test 2: Run the run_multiple_models function with metric saving
cat("\nTest 2: run_multiple_models with metric saving\n")
tryCatch({
  # Run models with reduced samples for speed
  models <- run_multiple_models(
    data_array,
    gene_indices = 1:2,  # Only test first 2 genes for speed
    n_samples = 100,     # Very few samples for speed in testing
    parallel = FALSE,
    save_metrics = TRUE,
    save_metrics_file = test_h5_file
  )
  
  # Check if HDF5 file was created
  if (!file.exists(test_h5_file)) {
    stop("Failed to create HDF5 file via run_multiple_models")
  } else {
    cat("✓ HDF5 file created via run_multiple_models\n")
  }
  
  # Check HDF5 file structure
  h5_structure <- rhdf5::h5ls(test_h5_file)
  print(h5_structure)
  
  # Verify array_weights group exists
  fid <- rhdf5::H5Fopen(test_h5_file)
  if (!rhdf5::H5Lexists(fid, "array_weights")) {
    rhdf5::H5Fclose(fid)
    stop("array_weights group missing from HDF5 file")
  } else {
    cat("✓ array_weights group exists\n")
  }
  
  # Verify metadata group exists
  if (!rhdf5::H5Lexists(fid, "metadata")) {
    rhdf5::H5Fclose(fid)
    stop("metadata group missing from HDF5 file")
  } else {
    cat("✓ metadata group exists\n")
  }
  rhdf5::H5Fclose(fid)
  
  # Check if first gene exists and can be read
  gene1_path <- "array_weights/gene1"
  fid <- rhdf5::H5Fopen(test_h5_file)
  if (!rhdf5::H5Lexists(fid, gene1_path)) {
    rhdf5::H5Fclose(fid)
    stop("gene1 metrics missing from HDF5 file")
  }
  rhdf5::H5Fclose(fid)
  
  # Read metrics for gene1
  metrics <- rhdf5::h5read(test_h5_file, "metadata/metric_names")
  gene1_array <- rhdf5::h5read(test_h5_file, paste0(gene1_path, "/array"))
  cat("✓ Successfully read gene1 array data:", paste(gene1_array[1:min(3, length(gene1_array))], collapse=", "), "...\n")
  
  # Try to read at least one metric
  for (metric in metrics) {
    metric_path <- paste0(gene1_path, "/", metric)
    fid <- rhdf5::H5Fopen(test_h5_file)
    metric_exists <- rhdf5::H5Lexists(fid, metric_path)
    rhdf5::H5Fclose(fid)
    
    if (metric_exists) {
      metric_data <- rhdf5::h5read(test_h5_file, metric_path)
      cat("✓ Successfully read metric:", metric, "\n")
      break
    }
  }
  
  cat("✓ run_multiple_models with metric saving test passed\n")
}, error = function(e) {
  cat("✗ run_multiple_models with metric saving test failed:", e$message, "\n")
})

# Test 3: Test directly using the saveWeightsToHDF5 function
cat("\nTest 3: Direct test of saveWeightsToHDF5 function\n")
tryCatch({
  # Get access to the internal function
  saveWeightsToHDF5 <- trajConserve:::saveWeightsToHDF5
  
  # Create a new file
  if (file.exists(test_h5_file)) {
    file.remove(test_h5_file)
  }
  rhdf5::h5createFile(test_h5_file)
  rhdf5::h5createGroup(test_h5_file, "array_weights")
  
  # Create test data frame
  test_weights <- data.frame(
    array = factor(c("batch1", "batch2")),
    Estimate = c(0.5, 0.7),
    `Est.Error` = c(0.1, 0.1),
    Q2.5 = c(0.3, 0.5),
    Q97.5 = c(0.7, 0.9),
    shape = c(1.0, 1.5),
    weight = c(1.0, 1.5),
    weight_norm = c(0.5, 0.75)
  )
  
  # Save weights
  saveWeightsToHDF5(test_h5_file, "array_weights/test_gene", test_weights)
  cat("✓ saveWeightsToHDF5 executed without errors\n")
  
  # Verify data was saved correctly
  fid <- rhdf5::H5Fopen(test_h5_file)
  if (!rhdf5::H5Lexists(fid, "array_weights/test_gene")) {
    rhdf5::H5Fclose(fid)
    stop("test_gene group missing from HDF5 file")
  }
  rhdf5::H5Fclose(fid)
  
  # Read back estimate and verify
  estimate <- rhdf5::h5read(test_h5_file, "array_weights/test_gene/Estimate")
  if (!all(estimate == test_weights$Estimate)) {
    stop("Saved Estimate values don't match original")
  }
  cat("✓ Verified saved Estimate values match original\n")
  
  cat("✓ Direct saveWeightsToHDF5 test passed\n")
}, error = function(e) {
  cat("✗ Direct saveWeightsToHDF5 test failed:", e$message, "\n")
})

# Clean up
if (file.exists(test_h5_file)) {
  file.remove(test_h5_file)
}

cat("\nAll TrajConserve HDF5 integration tests completed.\n") 