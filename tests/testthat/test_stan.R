# Set environment variables
Sys.setenv(TBB_CXX_TYPE = "gcc")
Sys.setenv(STAN_HAS_CXX17 = "true")

# Load library
library(cmdstanr)

# Try a simple Stan model
cat("Compiling a simple Stan model...\n")

code <- "
data {
  int<lower=0> N;
  vector[N] y;
}
parameters {
  real mu;
  real<lower=0> sigma;
}
model {
  y ~ normal(mu, sigma);
}
"

# Create temp file
temp_file <- tempfile(fileext = ".stan")
writeLines(code, temp_file)

# Try to compile
model <- cmdstanr::cmdstan_model(
  stan_file = temp_file,
  compile = TRUE,
  quiet = FALSE
)

# Run a simple example
N <- 10
y <- rnorm(N)
data_list <- list(N = N, y = y)

# Fit the model
fit <- model$sample(
  data = data_list,
  seed = 123,
  chains = 1,
  iter_warmup = 500,
  iter_sampling = 500
)

# Print summary
cat("\nModel results:\n")
print(fit$summary()) 