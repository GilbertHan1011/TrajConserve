# A simple verification script for rhdf5 high-level API functions
# Run this script to ensure that the rhdf5 API is working correctly

# Check if rhdf5 is installed
if (!requireNamespace("rhdf5", quietly = TRUE)) {
  stop("rhdf5 is not installed. Please install it with BiocManager::install('rhdf5')")
}

library(rhdf5)

# Create a temporary file
tempfile <- tempfile(fileext = ".h5")
cat("Creating temporary HDF5 file:", tempfile, "\n")

# Create the file
h5createFile(tempfile)
if (file.exists(tempfile)) {
  cat("✓ HDF5 file created successfully\n")
} else {
  stop("✗ Failed to create HDF5 file")
}

# Create a group
h5createGroup(tempfile, "testgroup")

# Check if group exists
fid <- H5Fopen(tempfile)
if (H5Lexists(fid, "testgroup")) {
  cat("✓ HDF5 group created successfully\n")
  H5Fclose(fid)
} else {
  H5Fclose(fid)
  stop("✗ Failed to create HDF5 group")
}

# Create a nested group
h5createGroup(tempfile, "testgroup/nestedgroup")

# Check if nested group exists
fid <- H5Fopen(tempfile)
if (H5Lexists(fid, "testgroup/nestedgroup")) {
  cat("✓ Nested HDF5 group created successfully\n")
  H5Fclose(fid)
} else {
  H5Fclose(fid)
  stop("✗ Failed to create nested HDF5 group")
}

# Write data to the file
test_data <- 1:10
h5write(test_data, tempfile, "testdata")

# Check if data exists
fid <- H5Fopen(tempfile)
if (H5Lexists(fid, "testdata")) {
  cat("✓ Data written to HDF5 file successfully\n")
  H5Fclose(fid)
} else {
  H5Fclose(fid)
  stop("✗ Failed to write data to HDF5 file")
}

# Read data back
read_data <- h5read(tempfile, "testdata")
if (identical(test_data, read_data)) {
  cat("✓ Data read from HDF5 file successfully and matches original\n")
} else {
  stop("✗ Data read from HDF5 file does not match original")
}

# Test writing data to a group
h5write(test_data * 2, tempfile, "testgroup/groupdata")

# Check if data in group exists
fid <- H5Fopen(tempfile)
if (H5Lexists(fid, "testgroup/groupdata")) {
  cat("✓ Data written to HDF5 group successfully\n")
  H5Fclose(fid)
} else {
  H5Fclose(fid)
  stop("✗ Failed to write data to HDF5 group")
}

# List the file structure
cat("\nHDF5 file structure:\n")
print(h5ls(tempfile))

# Clean up
file.remove(tempfile)
cat("\n✓ All tests passed successfully\n") 