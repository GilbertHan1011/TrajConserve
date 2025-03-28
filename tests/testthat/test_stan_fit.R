# Stan fitting test script
cat("Starting Stan model fitting test...\n")

# Set environment variables
Sys.setenv(TBB_CXX_TYPE = "gcc")
Sys.setenv(STAN_HAS_CXX17 = "true")

# Try to load cmdstanr
if (!requireNamespace("cmdstanr", quietly = TRUE)) {
  cat("cmdstanr not installed\n")
  quit(status = 1)
}

library(cmdstanr)

# Print version information
cat("R version:", as.character(getRversion()), "\n")
cat("CmdStan path:", cmdstanr::cmdstan_path(), "\n")
cat("CmdStan version:", cmdstanr::cmdstan_version(), "\n")

# Define a simple normal model with data
cat("Creating simple normal model...\n")
stan_code <- "
data {
  int<lower=0> N;
  vector[N] y;
  
  // Known values for testing
  real true_mu;
  real true_sigma;
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

generated quantities {
  // Log the difference for validation
  real mu_error = mu - true_mu;
  real sigma_error = sigma - true_sigma;
}
"

# Create a temporary file for the Stan model
stan_file <- tempfile(fileext = ".stan")
writeLines(stan_code, stan_file)
cat("Stan model written to:", stan_file, "\n")

# Generate synthetic data
set.seed(123)
N <- 50
true_mu <- 3.5
true_sigma <- 1.2
y <- rnorm(N, mean = true_mu, sd = true_sigma)

# Create data list for Stan
data_list <- list(
  N = N,
  y = y,
  true_mu = true_mu,
  true_sigma = true_sigma
)

# Try to compile and fit the model
tryCatch({
  cat("Compiling Stan model...\n")
  mod <- cmdstan_model(stan_file, compile = TRUE)
  cat("Model successfully compiled!\n")
  
  # Fit the model
  cat("\nFitting the model...\n")
  fit <- mod$sample(
    data = data_list,
    seed = 123,
    chains = 1,
    iter_warmup = 500,
    iter_sampling = 500,
    refresh = 250,
    show_messages = TRUE
  )
  
  # Print summary
  cat("\nModel results:\n")
  summary <- fit$summary(c("mu", "sigma", "mu_error", "sigma_error"))
  print(summary)
  
  # Evaluate fit
  mu_estimate <- summary$mean[summary$variable == "mu"]
  sigma_estimate <- summary$mean[summary$variable == "sigma"]
  
  cat("\nTrue vs Estimated parameters:\n")
  cat("mu (true):", true_mu, "vs (estimated):", mu_estimate, "\n")
  cat("sigma (true):", true_sigma, "vs (estimated):", sigma_estimate, "\n")
  
  # Success message
  cat("\n=======================\n")
  cat("Stan model fitting successful!\n")
  cat("=======================\n")
  
}, error = function(e) {
  cat("ERROR: Stan model fitting failed with the following error:\n")
  cat(conditionMessage(e), "\n")
  
  # Try to get more information
  cat("\nDiagnostic information:\n")
  system("g++ --version", intern = FALSE)
  system("uname -a", intern = FALSE)
}) 