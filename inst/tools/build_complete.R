# Comprehensive build script for trajConserve package
# Usage: Rscript build_complete.R

# Print start message
cat("=== trajConserve Package Build Process ===\n")
cat("Starting build process at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# Install required packages if needed
required_packages <- c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing package:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.r-project.org")
  }
}

# Load devtools
library(devtools)

# Set the path to the package
pkg_path <- "."  # Current directory
cat("Package path:", normalizePath(pkg_path), "\n\n")

# Document the package
cat("Step 1: Documenting package...\n")
result <- tryCatch({
  document(pkg = pkg_path)
  cat("  Documentation successful!\n\n")
  TRUE
}, error = function(e) {
  cat("  Error in documentation:", e$message, "\n\n")
  FALSE
})

# Only continue if documentation was successful
if (result) {
  # Run tests
  cat("Step 2: Running tests...\n")
  tryCatch({
    test_results <- test(pkg = pkg_path)
    cat("  Tests complete. Results:\n")
    print(test_results)
    cat("\n")
  }, error = function(e) {
    cat("  Error in tests:", e$message, "\n\n")
  })
  
  # Build the package
  cat("Step 3: Building package...\n")
  tryCatch({
    built_pkg <- build(pkg = pkg_path)
    cat("  Package built at:", built_pkg, "\n\n")
  }, error = function(e) {
    cat("  Error in build:", e$message, "\n\n")
  })
  
  # Check the package
  cat("Step 4: Checking package...\n")
  tryCatch({
    check_results <- check(pkg = pkg_path)
    cat("  Check complete. Results:\n")
    print(check_results)
    cat("\n")
  }, error = function(e) {
    cat("  Error in check:", e$message, "\n\n")
  })
  
  # Install the package locally
  cat("Step 5: Installing package locally...\n")
  tryCatch({
    install(pkg = pkg_path, dependencies = FALSE)
    cat("  Package installed successfully!\n\n")
  }, error = function(e) {
    cat("  Error in installation:", e$message, "\n\n")
  })
}

# Print completion message
cat("trajConserve package build process completed at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("============================================\n")