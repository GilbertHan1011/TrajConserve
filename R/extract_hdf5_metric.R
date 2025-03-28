#' Extract Metric from HDF5 File
#'
#' This function extracts a specific metric from an HDF5 file containing model results.
#' It returns a matrix where genes are in columns and arrays/samples are in rows.
#'
#' @param h5_file Path to the HDF5 file containing model results
#' @param metric Name of the metric to extract (e.g., "Estimate", "Est.Error")
#'
#' @return A matrix with arrays/samples in rows and genes in columns
#'
#' @importFrom rhdf5 h5ls h5read H5Fopen H5Fclose H5Lexists
#' @export
extract_hdf5_metric <- function(h5_file, metric) {
  # Check if required packages are available
  if (!requireNamespace("rhdf5", quietly = TRUE)) {
    stop("The 'rhdf5' package is required. Please install it with: BiocManager::install('rhdf5')")
  }
  
  # Check if file exists
  if (!file.exists(h5_file)) {
    stop("HDF5 file not found: ", h5_file)
  }
  
  # Get file structure
  file_structure <- rhdf5::h5ls(h5_file)
  
  # Find gene groups
  gene_paths <- grep("/array_weights/gene", file_structure$group, value = TRUE)
  unique_genes <- unique(gsub(".*/gene([0-9]+)$", "gene\\1", gene_paths))
  
  if (length(unique_genes) == 0) {
    stop("No gene data found in the HDF5 file")
  }
  
  # Get the number of arrays/samples
  sample_gene <- unique_genes[1]
  array_path <- paste0("/array_weights/", sample_gene, "/array")
  arrays <- rhdf5::h5read(h5_file, array_path)
  n_arrays <- length(arrays)
  n_genes <- length(unique_genes)
  
  # Initialize the matrix
  result_matrix <- matrix(NA, nrow = n_arrays, ncol = n_genes)
  colnames(result_matrix) <- unique_genes
  rownames(result_matrix) <- arrays
  
  # Open the HDF5 file
  h5_id <- rhdf5::H5Fopen(h5_file)
  
  # Fill the matrix with the metric values
  for (i in 1:length(unique_genes)) {
    gene <- unique_genes[i]
    metric_path <- paste0("/array_weights/", gene, "/", metric)
    
    if (rhdf5::H5Lexists(h5_id, metric_path)) {
      gene_metric <- rhdf5::h5read(h5_file, metric_path)
      result_matrix[, i] <- gene_metric
    } else {
      warning("Metric '", metric, "' not found for gene '", gene, "'")
    }
  }
  
  # Close the HDF5 file
  rhdf5::H5Fclose(h5_id)
  
  return(result_matrix)
} 