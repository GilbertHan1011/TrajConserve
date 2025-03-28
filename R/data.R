#' Small example dataset for TrajConserve
#'
#' A dataset containing example trajectory data for demonstrating the 
#' functionality of the TrajConserve package. The data is stored as a Seurat object
#' with a subset of cells and genes for testing package functionality. This small
#' example contains 8,000 cells and 100 genes extracted from a tooth development dataset.
#'
#' The dataset can be loaded using the \code{\link{load_example_data}} function.
#'
#' @format A Seurat object with the following slots:
#' \describe{
#'   \item{assays}{Contains expression data in the 'originalexp' assay}
#'   \item{meta.data}{Cell metadata including clustering information and pseudotime values}
#'   \item{reductions}{Dimension reductions including UMAP projections}
#'   \item{graphs}{Cell-cell similarity graphs}
#' }
#'
#' @details
#' The dataset includes cells from tooth development at embryonic stage E13.5,
#' with clustering information and pseudotime values. It can be used for testing
#' trajectory conservation analysis functions in the TrajConserve package.
#'
#' @source Generated as a small example from actual tooth development trajectory data
#' @examples
#' \dontrun{
#' # Load the example dataset
#' data <- load_example_data()
#' # View the structure of the data
#' str(data)
#' # Plot UMAP visualization
#' if (require("Seurat")) {
#'   Seurat::DimPlot(data, reduction = "X_umap")
#' }
#' } 