# Script to verify Stan is working

library(cmdstanr)

cat("CmdStan path:", cmdstan_path(), "\n")

# Create a simple Stan model
cat("Creating and compiling a simple Stan model...\n")

stan_code <- "
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

# Write the Stan code to a file
stan_file <- tempfile(fileext = ".stan")
writeLines(stan_code, stan_file)

# Compile the model
mod <- cmdstan_model(stan_file, compile = TRUE)

# Simulate some data
N <- 10
y <- rnorm(N)
data <- list(N = N, y = y)

# Run the model
fit <- mod$sample(
  data = data,
  seed = 123,
  chains = 1,
  parallel_chains = 1,
  iter_warmup = 500,
  iter_sampling = 500
)

# Print summary
cat("\nModel summary:\n")
print(fit$summary())

cat("\nStan is working properly!\n") 