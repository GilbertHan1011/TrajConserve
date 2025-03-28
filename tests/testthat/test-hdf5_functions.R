# Test HDF5 functionality
testthat::context("HDF5 Functions Testing")

testthat::test_that("HDF5 API functions work correctly", {
  
  # Skip if rhdf5 is not available
  testthat::skip_if_not_installed("rhdf5")
  
  # Create a temporary file
  tempfile <- tempfile(fileext = ".h5")
  
  # Test basic HDF5 operations using high-level functions
  rhdf5::h5createFile(tempfile)
  testthat::expect_true(file.exists(tempfile))
  
  # Create a group using high-level function
  rhdf5::h5createGroup(tempfile, "testgroup")
  
  # Open the file with low-level function to check existence
  fid <- rhdf5::H5Fopen(tempfile)
  testthat::expect_true(rhdf5::H5Lexists(fid, "testgroup"))
  rhdf5::H5Fclose(fid)
  
  # Test the h5write function
  test_data <- 1:10
  rhdf5::h5write(test_data, tempfile, "testdata")
  
  # Check existence again
  fid <- rhdf5::H5Fopen(tempfile)
  testthat::expect_true(rhdf5::H5Lexists(fid, "testdata"))
  rhdf5::H5Fclose(fid)
  
  # Read back and verify
  read_data <- rhdf5::h5read(tempfile, "testdata")
  testthat::expect_equal(test_data, read_data)
  
  # Delete the file
  file.remove(tempfile)
})

testthat::test_that("saveWeightsToHDF5 helper function works", {
  testthat::skip_if_not_installed("rhdf5")
  
  # Load the saveWeightsToHDF5 function
  # Note: In a real test environment, this would be properly exported or loaded
  saveWeightsToHDF5 <- trajConserve:::saveWeightsToHDF5
  
  # Create a temporary file
  tempfile <- tempfile(fileext = ".h5")
  
  # Create file and basic structure using high-level functions
  rhdf5::h5createFile(tempfile)
  rhdf5::h5createGroup(tempfile, "array_weights")
  
  # Create test dataframe
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
  
  # Save using our helper function
  testthat::expect_error(
    saveWeightsToHDF5(tempfile, "array_weights/test_gene", test_weights),
    NA
  )
  
  # Verify the data exists with proper API
  fid <- rhdf5::H5Fopen(tempfile)
  testthat::expect_true(rhdf5::H5Lexists(fid, "array_weights/test_gene"))
  testthat::expect_true(rhdf5::H5Lexists(fid, "array_weights/test_gene/Estimate"))
  rhdf5::H5Fclose(fid)
  
  # Read back and verify
  read_estimate <- rhdf5::h5read(tempfile, "array_weights/test_gene/Estimate")
  testthat::expect_equal(test_weights$Estimate, read_estimate)
  
  # Delete the file
  file.remove(tempfile)
}) 