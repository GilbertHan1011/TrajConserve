#' Extract Metrics from HDF5 File
#'
#' This function extracts metric values (such as "Estimate", "Est.Error", etc.) from 
#' an HDF5 file created by the run_multiple_models function and organizes them into a matrix
#' where rows are groups/batches and columns are genes.
#'
#' @param h5_file Path to the HDF5 file
#' @param metric Name of the metric to extract (default: "Estimate")
#'
#' @return A matrix of extracted values with rows as groups/batches and columns as genes
#'
#' @importFrom rhdf5 h5ls h5read H5Fopen H5Lexists H5Fclose
#' @export
extract_hdf5_metric <- function(h5_file, metric = "Estimate") {
  # Check if rhdf5 package is available
  if (!requireNamespace("rhdf5", quietly = TRUE)) {
    stop("The 'rhdf5' package is required. Please install it with: BiocManager::install('rhdf5')")
  }
  
  # Check if file exists
  if (!file.exists(h5_file)) {
    stop("HDF5 file does not exist: ", h5_file)
  }
  
  # Open the file
  h5_fid <- rhdf5::H5Fopen(h5_file)
  
  # Check if array_weights group exists
  if (!rhdf5::H5Lexists(h5_fid, "array_weights")) {
    rhdf5::H5Fclose(h5_fid)
    stop("array_weights group not found in HDF5 file")
  }
  
  # List the file structure to get genes
  h5_structure <- rhdf5::h5ls(h5_file)
  rhdf5::H5Fclose(h5_fid)
  
  # Get all genes (groups under array_weights)
  gene_groups <- h5_structure[h5_structure$group == "/array_weights" & h5_structure$otype == "H5I_GROUP", "name"]
  
  if (length(gene_groups) == 0) {
    stop("No gene groups found in array_weights")
  }
  
  # Initialize a list to hold the data
  all_data <- list()
  group_names <- NULL
  
  # Process each gene
  for (gene in gene_groups) {
    # Construct the metric path
    metric_path <- paste0("array_weights/", gene, "/", metric)
    array_path <- paste0("array_weights/", gene, "/array")
    
    # Open the file to check if the metric exists
    h5_fid <- rhdf5::H5Fopen(h5_file)
    metric_exists <- rhdf5::H5Lexists(h5_fid, metric_path)
    array_exists <- rhdf5::H5Lexists(h5_fid, array_path)
    rhdf5::H5Fclose(h5_fid)
    
    if (!metric_exists || !array_exists) {
      warning(paste("Metric", metric, "or array data not found for gene", gene, "- skipping"))
      next
    }
    
    # Read the metric values and array names
    gene_values <- rhdf5::h5read(h5_file, metric_path)
    array_names <- rhdf5::h5read(h5_file, array_path)
    
    # Store the values with array names
    all_data[[gene]] <- data.frame(
      array = array_names,
      value = gene_values,
      stringsAsFactors = FALSE
    )
    
    # Store unique group names if not already captured
    if (is.null(group_names)) {
      group_names <- array_names
    } else {
      # Check if all genes have the same groups
      if (!identical(sort(group_names), sort(array_names))) {
        warning("Inconsistent array/group names across genes")
      }
    }
  }
  
  if (length(all_data) == 0) {
    stop("No data could be extracted for metric: ", metric)
  }
  
  # Create a matrix with rows=groups and columns=genes
  # First, get the unique group names across all genes
  all_groups <- unique(unlist(lapply(all_data, function(x) x$array)))
  
  # Initialize the result matrix
  result_matrix <- matrix(NA, nrow = length(all_groups), ncol = length(all_data))
  rownames(result_matrix) <- all_groups
  colnames(result_matrix) <- names(all_data)
  
  # Fill the matrix
  for (i in seq_along(all_data)) {
    gene <- names(all_data)[i]
    gene_data <- all_data[[gene]]
    
    # Map values to the right rows
    for (j in seq_len(nrow(gene_data))) {
      group <- gene_data$array[j]
      value <- gene_data$value[j]
      result_matrix[group, gene] <- value
    }
  }
  
  return(result_matrix)
}

#' Plot Heatmap from HDF5 Metrics
#'
#' This function creates a heatmap visualization from metrics extracted from an HDF5 file.
#'
#' @param h5_file Path to the HDF5 file
#' @param metric Name of the metric to visualize (default: "Estimate")
#' @param cluster_rows Whether to cluster rows in the heatmap (default: TRUE)
#' @param cluster_cols Whether to cluster columns in the heatmap (default: TRUE)
#' @param scale Character indicating if the values should be centered and scaled in either 
#'   the row or column direction (default: "none")
#' @param ... Additional arguments passed to pheatmap
#'
#' @return A heatmap plot object
#'
#' @importFrom pheatmap pheatmap
#' @export
plot_hdf5_heatmap <- function(h5_file, metric = "Estimate", cluster_rows = TRUE, 
                              cluster_cols = TRUE, scale = "none", ...) {
  # Check if pheatmap package is available
  if (!requireNamespace("pheatmap", quietly = TRUE)) {
    stop("The 'pheatmap' package is required. Please install it with: install.packages('pheatmap')")
  }
  
  # Extract the metric data
  metric_matrix <- extract_hdf5_metric(h5_file, metric)
  
  # Create a title
  plot_title <- paste("Heatmap of", metric, "from", basename(h5_file))
  
  # Create the heatmap
  heatmap_plot <- pheatmap::pheatmap(
    metric_matrix,
    main = plot_title,
    cluster_rows = cluster_rows,
    cluster_cols = cluster_cols,
    scale = scale,
    ...
  )
  
  return(heatmap_plot)
} 