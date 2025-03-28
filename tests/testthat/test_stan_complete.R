# Comprehensive Stan test script

# Set environment variables
Sys.setenv(TBB_CXX_TYPE = "gcc")
Sys.setenv(STAN_HAS_CXX17 = "true")

# Function to check if a package is installed and load it
load_package <- function(pkg_name) {
  if (!requireNamespace(pkg_name, quietly = TRUE)) {
    cat(paste0("Package '", pkg_name, "' is not installed. Attempting to install...\n"))
    install.packages(pkg_name)
  }
  library(pkg_name, character.only = TRUE)
  cat(paste0("Package '", pkg_name, "' loaded successfully\n"))
}

# Wrap operations in tryCatch to properly handle errors
tryCatch({
  # Load cmdstanr
  load_package("cmdstanr")
  
  # Print cmdstanr version and path information
  cat("CmdStan path:", cmdstanr::cmdstan_path(), "\n")
  cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")
  
  # Check if CmdStan is properly configured
  cat("Checking CmdStan configuration...\n")
  cmdstanr::check_cmdstan_toolchain(fix = TRUE)
  
  # Define a simple Stan model
  stan_code <- "
  data {
    int<lower=0> N;
    array[N] real y;
  }
  
  parameters {
    real mu;
    real<lower=0> sigma;
  }
  
  model {
    mu ~ normal(0, 10);
    sigma ~ cauchy(0, 5);
    y ~ normal(mu, sigma);
  }
  "
  
  # Create a temporary file for the Stan model
  stan_file <- tempfile(fileext = ".stan")
  writeLines(stan_code, stan_file)
  
  # Print the path to the Stan file
  cat("Stan model written to:", stan_file, "\n")
  
  # Compile the model
  cat("Compiling Stan model...\n")
  mod <- cmdstanr::cmdstan_model(stan_file, compile = TRUE)
  cat("Model successfully compiled!\n")
  
  # Generate fake data
  N <- 100
  y <- rnorm(N, mean = 5, sd = 2)
  data_list <- list(N = N, y = y)
  
  # Sample from the model
  cat("Running Stan model...\n")
  fit <- mod$sample(
    data = data_list,
    seed = 123,
    chains = 1,
    iter_warmup = 500,
    iter_sampling = 500,
    refresh = 250,
    show_messages = TRUE
  )
  
  # Examine results
  cat("\nModel results:\n")
  print(fit$summary(c("mu", "sigma")))
  
  # Simple diagnostic plot
  if (requireNamespace("bayesplot", quietly = TRUE)) {
    library(bayesplot)
    posterior <- fit$draws()
    mcmc_trace(posterior, pars = c("mu", "sigma"))
  } else {
    cat("Install 'bayesplot' package for diagnostic plots\n")
  }
  
  # Success message
  cat("\n=======================\n")
  cat("Stan test completed successfully!\n")
  cat("=======================\n")
}, error = function(e) {
  cat("\n=======================\n")
  cat("ERROR: Stan test failed with the following error:\n")
  cat(conditionMessage(e), "\n")
  cat("=======================\n")
  
  # Try to provide more diagnostic information
  cat("\nDiagnostic information:\n")
  cat("R version:", getRversion(), "\n")
  
  if (requireNamespace("cmdstanr", quietly = TRUE)) {
    tryCatch({
      cat("CmdStan path:", cmdstanr::cmdstan_path(), "\n")
      cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")
    }, error = function(e) {
      cat("Could not get CmdStan information:", conditionMessage(e), "\n")
    })
  } else {
    cat("cmdstanr is not installed\n")
  }
  
  # Check C++ compiler
  tryCatch({
    cc <- system("g++ --version", intern = TRUE)
    cat("C++ compiler:", cc[1], "\n")
  }, error = function(e) {
    cat("Could not get C++ compiler information\n")
  })
}) 