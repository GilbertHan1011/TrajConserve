 
#'
#' This function bins pseudotime values into a specified number of equal-width bins.
#'
#' @param x Numeric vector of pseudotime values
#' @param n_bins Number of bins to create (default: 100)
#'
#' @return An integer vector with bin assignments
#'
#' @export
bin_pseudotime <- function(x, n_bins = 100) {
  bins <- cut(x,
              breaks = seq(min(x), max(x), length.out = n_bins + 1),
              labels = FALSE,
              include.lowest = TRUE)
  return(bins)
}

#' Check Quality of Trajectory Tail
#'
#' This function examines the tail of a trajectory to ensure sufficient data points.
#'
#' @param metaDf Data frame containing batch and pseudotime bin information
#' @param n_bin Number of bins used in the pseudotime binning (default: 100)
#' @param tail_width Width of the tail to examine as a proportion (default: 0.3)
#' @param tail_num Minimum proportion of bins required in tail (default: 0.02)
#'
#' @return Character vector of batch names that pass the tail quality check
#'
#' @export
examine_trajectory_tail <- function(metaDf, n_bin = 100, tail_width = 0.3, tail_num = 0.02) {
  tail <- (1-tail_width) * n_bin
  metaDf$pseudotime_binned_tail <- metaDf$pseudotime_binned > tail
  metaBin <- unique(metaDf)
  selectTable <- table(metaBin$batch, metaBin$pseudotime_binned_tail)
  return(rownames(selectTable)[selectTable[,2] > tail_num * n_bin])
}

#' Calculate Bin Means Fast
#'
#' This function calculates the mean expression for each gene in each bin.
#'
#' @param expression_matrix A gene expression matrix (genes as rows, cells as columns)
#' @param bin_labels A vector of bin labels for each cell
#'
#' @return A matrix of mean expressions (genes as rows, bins as columns)
#'
#' @import data.table
#' @export
calculate_bin_means <- function(expression_matrix, bin_labels) {
  # Convert to data.table
  dt <- data.table::as.data.table(t(expression_matrix))
  dt[, bin := factor(bin_labels, levels = sort(unique(bin_labels)))]

  # Calculate means by group
  result <- dt[, lapply(.SD, mean), by = bin]
  result[, bin := NULL]

  # Return transposed matrix
  return(as.matrix(t(result)))
}

#' Reshape Matrix to 3D Array
#'
#' This function reshapes a 2D matrix to a 3D array for trajectory analysis.
#'
#' @param matrix_data Input matrix (genes as rows, bin-batch combinations as columns)
#' @param prefixes Vector of batch prefixes for each column
#' @param numbers Vector of bin numbers for each column
#' @param n_bins Total number of bins (default: 100)
#'
#' @return A 3D array with dimensions [batch, pseudotime, gene]
#'
#' @export
reshape_to_3d <- function(matrix_data, prefixes, numbers, n_bins = 100) {
  unique_prefixes <- unique(prefixes)
  result <- array(NA,
                  dim = c(length(unique_prefixes), n_bins, nrow(matrix_data)),
                  dimnames = list(unique_prefixes,
                                  1:n_bins,
                                  rownames(matrix_data)))

  for(i in seq_along(prefixes)) {
    prefix <- prefixes[i]
    number <- numbers[i]
    if(number <= n_bins) {
      result[prefix, number, ] <- matrix_data[, i]
    }
  }
  return(result)
}

#' Convert Seurat Object to 3D Expression Array
#'
#' This function processes a Seurat object to create a 3D array of binned expression data.
#'
#' @param seurat_obj A Seurat object
#' @param assay Assay to use for expression data (default: "RNA")
#' @param slot Slot to use for expression data (default: "data")
#' @param pseudo_col Column name in meta.data containing pseudotime values
#' @param project_col Column name in meta.data containing batch/project information
#' @param thred Threshold for gene filtering (proportion of non-zero bins) (default: 0.1)
#' @param batch_thred Threshold for batch filtering (proportion of bins present) (default: 0.3)
#' @param n_bin Number of bins for pseudotime (default: 100)
#' @param ensure_tail Whether to ensure quality in trajectory tail (default: TRUE)
#' @param tail_width Width of trajectory tail to examine (default: 0.3)
#' @param tail_num Minimum proportion of bins required in tail (default: 0.02)
#'
#' @return A list containing the processed data
#'
#' @importFrom Seurat GetAssayData
#' @import dplyr
#' @export
seurat_to_trajectory_array <- function(seurat_obj, 
                              assay = "RNA", 
                              slot = "data", 
                              pseudo_col, 
                              project_col, 
                              thred = 0.1, 
                              batch_thred = 0.3, 
                              n_bin = 100,
                              ensure_tail = TRUE, 
                              tail_width = 0.3, 
                              tail_num = 0.02) {
  # Extract expression matrix
  expr_matrix <- Seurat::GetAssayData(seurat_obj, assay = assay, slot = slot) %>% as.matrix()
  pseudotime <- seurat_obj@meta.data[[pseudo_col]]
  batch <- seurat_obj@meta.data[[project_col]]

  # Bin pseudotime
  pseudotime_binned <- bin_pseudotime(pseudotime, n_bins = n_bin)
  metaDf <- data.frame(batch, pseudotime_binned)
  metaDf$bin <- paste0(metaDf$batch, "_", metaDf$pseudotime_binned)

  # Calculate bin means
  binned_means <- calculate_bin_means(expr_matrix, metaDf$bin)
  colnames(binned_means) <- unique(metaDf$bin)
  
  # Filter genes and batches
  geneNum <- round(thred * ncol(binned_means))
  filteredGene <- rownames(binned_means)[rowSums(binned_means > 0) > geneNum]
  
  prefixes <- sapply(strsplit(colnames(binned_means), "_"),
                     function(x) paste(x[-length(x)], collapse = "_"))
  numbers <- sapply(strsplit(colnames(binned_means), "_"),
                    function(x) paste(x[length(x)], collapse = "_")) %>% as.numeric()

  bath_thred_real <- batch_thred * n_bin
  batchName <- names(table(prefixes) > bath_thred_real)[table(prefixes) > bath_thred_real]
  
  if (ensure_tail) {
    remain_sample <- examine_trajectory_tail(metaDf, n_bin = n_bin, tail_width = tail_width, tail_num = tail_num)
    batchName <- intersect(remain_sample, batchName)
  }

  binned_means_filter <- binned_means[filteredGene, prefixes %in% batchName]

  # Process final data
  prefixes <- sapply(strsplit(colnames(binned_means_filter), "_"),
                     function(x) paste(x[-length(x)], collapse = "_"))
  numbers <- sapply(strsplit(colnames(binned_means_filter), "_"),
                    function(x) paste(x[length(x)], collapse = "_")) %>% as.numeric()
  reshaped_data <- reshape_to_3d(binned_means_filter, prefixes, numbers, n_bins = n_bin)

  # Return results
  return(list(
    reshaped_data = reshaped_data,
    binned_means = binned_means,
    binned_means_filter = binned_means_filter,
    filtered_genes = filteredGene,
    batch_names = batchName,
    metadata = metaDf
  ))
} 