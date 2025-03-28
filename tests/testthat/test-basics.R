library(testthat)
test_that("bin_pseudotime works correctly", {
  # Test with simple vector
  x <- seq(0, 1, length.out = 10)
  bins <- bin_pseudotime(x, n_bins = 5)
  
  # Should have 5 bins
  expect_equal(length(unique(bins)), 5)
  
  # First and last elements should be in first and last bins
  expect_equal(bins[1], 1)
  expect_equal(bins[length(bins)], 5)
})

test_that("prepare_data_for_gam works correctly", {
  # Create a simple 2D array
  data <- matrix(1:6, nrow = 2, ncol = 3)
  
  # Prepare data
  result <- prepare_data_for_gam(data)
  
  # Check structure
  expect_type(result, "list")
  expect_named(result, c("x", "y", "array_idx"))
  
  # Check values
  expect_equal(result$x, c(1, 2, 3, 1, 2, 3))
  expect_equal(result$y, c(1, 3, 5, 2, 4, 6))
  expect_equal(result$array_idx, c(1, 1, 1, 2, 2, 2))
})

test_that("reshape_to_3d works correctly", {
  # Create test data
  mat <- matrix(1:6, nrow = 2, ncol = 3)
  rownames(mat) <- c("gene1", "gene2")
  colnames(mat) <- c("batch1_1", "batch1_2", "batch2_1")
  
  # Extract prefixes and numbers
  prefixes <- c("batch1", "batch1", "batch2")
  numbers <- c(1, 2, 1)
  
  # Reshape
  result <- reshape_to_3d(mat, prefixes, numbers, n_bins = 2)
  
  # Check dimensions
  expect_equal(dim(result), c(2, 2, 2))
  
  # Check values
  expect_equal(result["batch1", 1, "gene1"], 1)
  expect_equal(result["batch1", 2, "gene1"], 3)
  expect_equal(result["batch2", 1, "gene1"], 5)
  expect_true(is.na(result["batch2", 2, "gene1"]))
})