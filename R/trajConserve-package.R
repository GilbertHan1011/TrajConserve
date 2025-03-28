 
#' 
#' @description 
#' Tools for analyzing trajectory conservation in single-cell data. This package 
#' provides functions for Bayesian GAM regression modeling of expression trajectories, 
#' pseudotime binning and transformation, and visualization of trajectory models.
#'
#' @section Key Functions:
#' \itemize{
#'   \item \code{\link{seurat_to_trajectory_array}} - Convert Seurat object to a 3D trajectory array
#'   \item \code{\link{bayesian_gam_regression_nb_shape}} - Fit Bayesian GAM regression model
#'   \item \code{\link{run_multiple_models}} - Run models for multiple genes in parallel
#'   \item \code{\link{plot_results_brms}} - Visualize model results
#' }
#'
#' @name trajConserve
#' @aliases trajConserve-package
#' @aliases trajConserve
#' @author Gilbert Han
#' @keywords package
"_PACKAGE"