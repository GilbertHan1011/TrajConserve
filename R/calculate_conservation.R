#' Calculate Gene Conservation Scores
#'
#' This function calculates conservation scores for genes based on their Estimate values
#' and the variability of these estimates across samples/batches. Genes with high estimate
#' values and low variability are considered conserved, while genes with low estimates
#' or high variability are considered non-conserved.
#'
#' @param h5_file Path to the HDF5 file containing model results
#' @param metric Name of the metric to use for conservation calculation (default: "Estimate")
#' @param mean_weight Weight for the mean component in the score calculation (default: 0.5)
#' @param variability_weight Weight for the variability component in the score calculation (default: 0.5)
#' @param conservation_threshold Threshold for classifying genes as conserved (default: 0.6)
#' @param normalize_scores Whether to normalize scores to 0-1 range (default: TRUE)
#'
#' @return A data frame with gene names, conservation scores, classification, and metrics
#'
#' @importFrom stats sd median
#' @export
calculate_conservation <- function(h5_file, metric = "Estimate", 
                                  mean_weight = 0.5, variability_weight = 0.5,
                                  conservation_threshold = 0.6,
                                  normalize_scores = TRUE) {
  # Check if required packages are available
  if (!requireNamespace("rhdf5", quietly = TRUE)) {
    stop("The 'rhdf5' package is required. Please install it with: BiocManager::install('rhdf5')")
  }
  
  # Extract the metric matrix
  metric_matrix <- extract_hdf5_metric(h5_file, metric)
  
  # Calculate statistics for each gene
  gene_stats <- data.frame(
    gene = colnames(metric_matrix),
    mean_estimate = apply(metric_matrix, 2, mean),
    sd_estimate = apply(metric_matrix, 2, sd),
    cv = apply(metric_matrix, 2, function(x) sd(x)/mean(x)),
    range_estimate = apply(metric_matrix, 2, function(x) max(x) - min(x)),
    stringsAsFactors = FALSE
  )
  
  # Normalize mean values (higher is better)
  if (normalize_scores) {
    gene_stats$mean_norm <- scale01(gene_stats$mean_estimate)
  } else {
    gene_stats$mean_norm <- gene_stats$mean_estimate
  }
  
  # Normalize variability measures (lower is better)
  if (normalize_scores) {
    # For coefficient of variation, lower is better for conservation
    gene_stats$cv_norm <- 1 - scale01(gene_stats$cv)
  } else {
    gene_stats$cv_norm <- 1 / gene_stats$cv
  }
  
  # Calculate conservation score (weighted combination of mean and variability)
  gene_stats$conservation_score <- mean_weight * gene_stats$mean_norm + 
                                   variability_weight * gene_stats$cv_norm
  
  # Normalize final conservation score if requested
  if (normalize_scores) {
    gene_stats$conservation_score <- scale01(gene_stats$conservation_score)
  }
  
  # Classify genes as conserved or non-conserved
  gene_stats$is_conserved <- gene_stats$conservation_score >= conservation_threshold
  
  # Order by conservation score (descending)
  gene_stats <- gene_stats[order(gene_stats$conservation_score, decreasing = TRUE), ]
  
  return(gene_stats)
}

#' Plot Conservation Results
#'
#' This function creates visualizations for gene conservation analysis results.
#'
#' @param conservation_results Output from calculate_conservation function
#' @param plot_type Type of plot to create: "scatter", "histogram", or "heatmap" (default: "scatter")
#' @param highlight_n Number of top and bottom conserved genes to highlight (default: 5)
#' @param original_data Original data matrix for heatmap (required only for heatmap plot)
#' @param gene_subset Subset of genes to include in heatmap (default: all genes)
#' @param file_path Path to save the plot (optional)
#'
#' @return A ggplot2 object or creates a plot file
#'
#' @importFrom ggplot2 ggplot aes geom_point scale_color_manual labs theme_bw geom_histogram
#' @importFrom stats reorder
#' @export
plot_conservation <- function(conservation_results, 
                             plot_type = "scatter", 
                             highlight_n = 5,
                             original_data = NULL,
                             gene_subset = NULL,
                             file_path = NULL) {
  # Check if required packages are available
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("The 'ggplot2' package is required. Please install it with: install.packages('ggplot2')")
  }
  
  # Setup for file output if specified
  if (!is.null(file_path)) {
    pdf(file_path)
    on.exit(dev.off())
  }
  
  if (plot_type == "scatter") {
    # For scatter plot, check if ggrepel is available for better labeling
    has_ggrepel <- requireNamespace("ggrepel", quietly = TRUE)
    if (!has_ggrepel) {
      warning("The 'ggrepel' package is recommended for better plot labeling. Install with: install.packages('ggrepel')")
    }
    
    # Prepare data for highlighting
    conservation_results$highlight <- "regular"
    top_n <- min(highlight_n, nrow(conservation_results))
    bottom_n <- min(highlight_n, nrow(conservation_results))
    
    conservation_results$highlight[1:top_n] <- "top"
    conservation_results$highlight[(nrow(conservation_results)-bottom_n+1):nrow(conservation_results)] <- "bottom"
    
    # Create scatter plot
    p <- ggplot2::ggplot(conservation_results, ggplot2::aes(x = mean_norm, y = cv_norm, 
                                            color = highlight)) +
      ggplot2::geom_point(ggplot2::aes(size = conservation_score)) +
      ggplot2::scale_color_manual(values = c("bottom" = "red", "regular" = "gray", "top" = "blue")) +
      ggplot2::labs(
        title = "Gene Conservation Analysis",
        x = "Normalized Mean Estimate",
        y = "Normalized Inverse Variability",
        color = "Gene Type"
      ) +
      ggplot2::theme_bw()
    
    # Add labels with ggrepel if available
    if (has_ggrepel) {
      label_data <- conservation_results[conservation_results$highlight != "regular", ]
      p <- p + ggrepel::geom_text_repel(
        data = label_data,
        ggplot2::aes(label = gene),
        box.padding = 0.5,
        point.padding = 0.3
      )
    }
    
    print(p)
    return(invisible(p))
    
  } else if (plot_type == "histogram") {
    # Create histogram of conservation scores
    p <- ggplot2::ggplot(conservation_results, ggplot2::aes(x = conservation_score)) +
      ggplot2::geom_histogram(bins = 30, fill = "steelblue", color = "black") +
      ggplot2::geom_vline(xintercept = mean(conservation_results$conservation_score), 
                linetype = "dashed", color = "red") +
      ggplot2::labs(
        title = "Distribution of Conservation Scores",
        x = "Conservation Score",
        y = "Count"
      ) +
      ggplot2::theme_bw()
    
    print(p)
    return(invisible(p))
    
  } else if (plot_type == "heatmap") {
    # For heatmap, check if pheatmap is available
    if (!requireNamespace("pheatmap", quietly = TRUE)) {
      stop("The 'pheatmap' package is required for heatmap plots. Please install it with: install.packages('pheatmap')")
    }
    
    if (is.null(original_data)) {
      stop("original_data parameter is required for heatmap plots")
    }
    
    # Determine genes to plot
    if (is.null(gene_subset)) {
      # Get top and bottom N genes
      top_genes <- conservation_results$gene[1:min(highlight_n, nrow(conservation_results))]
      bottom_genes <- conservation_results$gene[(nrow(conservation_results)-min(highlight_n, nrow(conservation_results))+1):nrow(conservation_results)]
      genes_to_plot <- c(top_genes, bottom_genes)
    } else {
      genes_to_plot <- gene_subset
    }
    
    # Subset matrix for selected genes
    if (!all(genes_to_plot %in% colnames(original_data))) {
      warning("Some genes not found in the matrix")
      genes_to_plot <- genes_to_plot[genes_to_plot %in% colnames(original_data)]
    }
    
    if (length(genes_to_plot) == 0) {
      stop("No valid genes found for heatmap")
    }
    
    # Subset the data to include only the genes we want to plot
    plot_matrix <- original_data[, genes_to_plot, drop = FALSE]
    
    # Create annotation for conserved vs non-conserved
    conserved_genes <- conservation_results$gene[conservation_results$is_conserved]
    gene_type <- ifelse(genes_to_plot %in% conserved_genes, "Conserved", "Non-conserved")
    
    # Create annotation data frame without using row names
    gene_anno <- data.frame(
      Gene = genes_to_plot,
      Conservation = factor(gene_type, levels = c("Conserved", "Non-conserved")),
      stringsAsFactors = FALSE
    )
    
    # Define colors for annotation
    anno_colors <- list(
      Conservation = c(Conserved = "blue", `Non-conserved` = "red")
    )
    
    # Generate a heatmap with custom labels
    heatmap_data <- t(plot_matrix)  # Transpose to get genes in rows
    rownames(heatmap_data) <- genes_to_plot
    
    # Ensure rownames match the data
    rownames(gene_anno) <- rownames(heatmap_data)
    gene_anno$Gene <- NULL  # Remove the Gene column as we're using rownames
    
    # Create heatmap
    p <- pheatmap::pheatmap(heatmap_data, 
              annotation_row = gene_anno,
              annotation_colors = anno_colors,
              main = "Expression Patterns of Conserved vs Non-conserved Genes",
              cluster_rows = TRUE,
              cluster_cols = TRUE)
    
    return(invisible(p))
  } else {
    stop("Invalid plot_type. Choose from 'scatter', 'histogram', or 'heatmap'.")
  }
}

# Helper function to scale values to 0-1 range
scale01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  if (rng[1] == rng[2]) return(rep(0.5, length(x)))
  (x - rng[1]) / (rng[2] - rng[1])
} 