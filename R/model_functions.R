#'
#' This function fits a Bayesian Generalized Additive Model with negative binomial distribution
#' and array-specific shape parameters to model gene expression trajectories.
#'
#' @param x Numeric vector of pseudotime values
#' @param y Numeric vector of gene expression counts
#' @param array_idx Vector of array/batch identifiers
#' @param n_knots Number of knots for the cubic regression spline (default: 5)
#' @param n_samples Number of MCMC samples (default: 2000)
#'
#' @return A list containing:
#'   \item{fit}{The fitted brms model object}
#'   \item{array_weights}{Data frame with array-specific weights based on shape parameters}
#'   \item{diagnostics}{Data frame with array-specific diagnostics}
#'   \item{data}{The data used for fitting}
#'
#' @import brms
#' @import dplyr
#' @import cmdstanr
#' @importFrom mgcv gam
#' @importFrom stats var
#' @export
bayesian_gam_regression_nb_shape <- function(x, y, array_idx, n_knots = 5, n_samples = 2000) {
  # Create data frame
  df <- data.frame(
    y = round(y[!is.na(y)]),  # ensure integers
    x = x[!is.na(y)],
    array = factor(array_idx[!is.na(y)])
  )

  # Define formula with array-specific shape parameters
  formula <- brms::bf(
    y ~ s(x, bs = "cr", k = 5) + array,
    shape ~ 0 + array  # shape parameter varies by array
  )

  # Set priors
  prior <- c(
    brms::prior(normal(0, 5), class = "b"),  # prior for fixed effects
    brms::prior(normal(0, 2), class = "b", dpar = "shape"),  # prior for shape parameters
    brms::prior(normal(0, 2), class = "sds")  # prior for smooth terms
  )

  # Fit the model with negative binomial family
  fit <- brms::brm(
    formula = formula,
    data = df,
    family = brms::negbinomial(),
    prior = prior,
    chains = 4,
    cores = 4,
    iter = n_samples,
    backend = "cmdstanr",
    control = list(
      adapt_delta = 0.95,
      max_treedepth = 12
    )
  )

  # Extract array-specific weights based on shape parameter
  # Higher shape = less overdispersion = more reliable
  array_weights <- brms::posterior_summary(fit, pars = "b_shape") %>%
    as.data.frame() %>%
    dplyr::mutate(
      array = 1:dplyr::n_distinct(array_idx),
      shape = exp(Estimate),  # Convert from log scale
      weight = shape,  # Higher shape means more reliable
      weight_norm = weight / max(weight)
    )

  # Calculate additional diagnostics
  diagnostics <- df %>%
    dplyr::group_by(array) %>%
    dplyr::summarise(
      mean = mean(y),
      variance = var(y),
      overdispersion = variance/mean,
      n_obs = n()
    )

  return(list(
    fit = fit,
    array_weights = array_weights,
    diagnostics = diagnostics,
    data = df
  ))
}

#' Plot Results from Bayesian GAM Regression
#'
#' This function generates diagnostic plots for the Bayesian GAM regression model.
#'
#' @param fit A model fit object returned by \code{bayesian_gam_regression_nb_shape}
#'
#' @return A grid arrangement of plots
#'
#' @import ggplot2
#' @import gridExtra
#' @export
plot_results_brms <- function(fit) {
  if (!inherits(fit, "list") || !all(c("data", "array_weights", "fit") %in% names(fit))) {
    stop("fit must be a list containing 'data', 'array_weights', and 'fit' elements")
  }

  # Extract data
  df <- fit$data

  # Plot 1: Array weights
  p1 <- ggplot2::ggplot(fit$array_weights,
               ggplot2::aes(x = array, y = Estimate)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_line() +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    ggplot2::labs(title = "Array Weights",
         x = "Array",
         y = "Normalized Weight") +
    ggplot2::theme_minimal()

  # Plot 2: Data and fitted curve
  # Generate prediction data
  x_seq <- seq(min(df$x), max(df$x), length.out = 100)
  pred_data <- data.frame(
    x = x_seq,
    # Use the first array for predictions
    array = factor(rep(levels(df$array)[1], 100))
  )

  # Get predictions
  predictions <- predict(fit$fit, newdata = pred_data)

  pred_df <- data.frame(
    x = x_seq,
    y = predictions[,"Estimate"],
    lower = predictions[,"Q2.5"],
    upper = predictions[,"Q97.5"]
  )

  # Create the second plot
  p2 <- ggplot2::ggplot() +
    # Original data points
    ggplot2::geom_point(data = df,
               ggplot2::aes(x = x, y = y, color = array,
                   alpha = fit$array_weights$weight_norm[as.numeric(array)])) +
    # Fitted line
    ggplot2::geom_line(data = pred_df,
              ggplot2::aes(x = x, y = y),
              color = "red",
              size = 1) +
    # Confidence interval
    ggplot2::geom_ribbon(data = pred_df,
                ggplot2::aes(x = x, ymin = lower, ymax = upper),
                alpha = 0.2,
                fill = "red") +
    ggplot2::labs(title = "Data and Fitted GAM",
         x = "X",
         y = "Y") +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")

  # Arrange plots
  gridExtra::grid.arrange(p1, p2, ncol = 2)
}