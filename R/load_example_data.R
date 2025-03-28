#' Load example dataset
#'
#' This function loads the small example dataset included with the package.
#' It provides sample trajectory data that can be used to test the functionality
#' of the TrajConserve package.
#'
#' @return A list or data frame containing trajectory data
#' @export
#'
#' @examples
#' \dontrun{
#' # Load the example dataset
#' example_data <- load_example_data()
#' }
load_example_data <- function() {
  # Get the path to the example data file
  data_path <- system.file("data", "small_example.Rds", package = "trajConserve")
  
  # Check if the file exists
  if (data_path == "") {
    stop("Example data not found. Please ensure that the package was installed correctly.")
  }
  
  # Load and return the data
  readRDS(data_path)
} 