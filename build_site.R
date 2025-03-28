#!/usr/bin/env Rscript

# Build pkgdown site for TrajConserve
# This script builds the documentation website for the TrajConserve package

# Check for pkgdown
if (!requireNamespace("pkgdown", quietly = TRUE)) {
  cat("Installing pkgdown...\n")
  install.packages("pkgdown")
}

library(pkgdown)

# Clean and rebuild site
pkgdown::clean_site()
pkgdown::build_site()

cat("Website built successfully!\n")
cat("You can view the site locally by opening 'docs/index.html' in your web browser.\n")
cat("To deploy the site, push the 'docs/' directory to your GitHub repository.\n") 