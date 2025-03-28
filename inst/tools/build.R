# trajConserve package build script

# Install required packages if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Set working directory to package root
# setwd("path/to/trajConserve")  # Uncomment and modify as needed

# Document the package (creates Rd files from roxygen comments)
devtools::document()

# Run tests
devtools::test()

# Build the package
devtools::build()

# Check the package
devtools::check()

# Install the package locally
devtools::install(dependencies = FALSE)

message("trajConserve package build completed!")
message("You can now use the package with: library(trajConserve)") 