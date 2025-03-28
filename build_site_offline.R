#!/usr/bin/env Rscript

# Build pkgdown site for TrajConserve without internet checks
# This script builds the documentation website for the TrajConserve package

# Load pkgdown
library(pkgdown)

# Clean directory
if (dir.exists("docs")) {
  unlink("docs", recursive = TRUE)
}

# Create basic site structure
dir.create("docs/reference", recursive = TRUE, showWarnings = FALSE)
dir.create("docs/articles", recursive = TRUE, showWarnings = FALSE)

# Initialize site
message("Initializing site...")
if (dir.exists("pkgdown/assets")) {
  file.copy("pkgdown/assets", "docs", recursive = TRUE)
} else {
  # Copy default assets
  file.copy(
    system.file("BS5/assets/link.svg", package = "pkgdown"),
    "docs/link.svg"
  )
  file.copy(
    system.file("BS5/assets/pkgdown.js", package = "pkgdown"),
    "docs/pkgdown.js"
  )
}

# Build reference index
message("Building reference index...")
tryCatch({
  pkgdown::build_reference(override = list(destination = "docs/reference"))
}, error = function(e) {
  message("Error building reference: ", e$message)
})

# Build home page
message("Building home page...")
tryCatch({
  pkgdown::build_home(override = list(destination = "docs"))
}, error = function(e) {
  message("Error building home page: ", e$message)
})

# Build articles (if available)
if (dir.exists("vignettes")) {
  message("Building articles...")
  tryCatch({
    pkgdown::build_articles(override = list(destination = "docs/articles"))
  }, error = function(e) {
    message("Error building articles: ", e$message)
  })
}

# Create a simple index page if it doesn't exist
if (!file.exists("docs/index.html")) {
  message("Creating basic index.html...")
  index_content <- paste0(
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "<title>TrajConserve: Trajectory Conservation Analysis Tools</title>",
    "<meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width, initial-scale=1.0'>",
    "<style>",
    "body { font-family: 'Helvetica', sans-serif; line-height: 1.6; padding: 2em; max-width: 800px; margin: 0 auto; }",
    "h1 { color: #0054AD; }",
    "a { color: #0054AD; text-decoration: none; }",
    "a:hover { text-decoration: underline; }",
    "nav { margin: 2em 0; }",
    "nav a { margin-right: 1em; }",
    ".content { margin-top: 2em; }",
    "</style>",
    "</head>",
    "<body>",
    "<h1>TrajConserve</h1>",
    "<p>Trajectory Conservation Analysis Tools for Single-Cell Data</p>",
    "<nav>",
    "<a href='reference/index.html'>Function Reference</a>",
    "<a href='articles/index.html'>Articles</a>",
    "</nav>",
    "<div class='content'>",
    "<h2>Overview</h2>",
    "<p>TrajConserve is an R package designed for analyzing trajectory conservation in single-cell data. It enables the identification of conserved and non-conserved gene expression patterns across developmental trajectories.</p>",
    "<h3>Key Features</h3>",
    "<ul>",
    "<li><strong>Trajectory Modeling</strong>: Bayesian GAM regression modeling of expression trajectories</li>",
    "<li><strong>Conservation Analysis</strong>: Quantify and visualize gene conservation across samples</li>",
    "<li><strong>HDF5 Integration</strong>: Efficient storage and retrieval of model results</li>",
    "<li><strong>Visualization Tools</strong>: Publication-ready plots of model results and conservation metrics</li>",
    "</ul>",
    "</div>",
    "</body>",
    "</html>"
  )
  writeLines(index_content, "docs/index.html")
}

message("Website built successfully!")
message("You can view the site locally by opening 'docs/index.html' in your web browser.") 