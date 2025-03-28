# Simple Stan test script
cat("Starting Stan test...\n")

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

# Check CmdStan configuration
cat("Checking CmdStan configuration...\n")
cmdstanr::check_cmdstan_toolchain(fix = TRUE)

# See if we can compile the simplest possible Stan program
cat("Testing with simplest possible Stan model...\n")

# Define the simplest possible Stan model
stan_code <- "
parameters {
  real y;
}
model {
  y ~ normal(0, 1);
}
"

# Create a temporary file for the Stan model
stan_file <- tempfile(fileext = ".stan")
writeLines(stan_code, stan_file)
cat("Stan model written to:", stan_file, "\n")

# Try to compile
tryCatch({
  cat("Compiling Stan model...\n")
  mod <- cmdstan_model(stan_file, compile = TRUE, cpp_options = list(STAN_THREADS = TRUE))
  cat("Model successfully compiled!\n")
  
  # If we get here, Stan is working properly
  cat("Stan is working correctly!\n")
  
}, error = function(e) {
  cat("ERROR: Stan compilation failed with the following error:\n")
  cat(conditionMessage(e), "\n")
  
  # Try to get more information about the system
  cat("\nSystem information:\n")
  system("g++ --version", intern = FALSE)
  system("uname -a", intern = FALSE)
  system("echo $TBB_CXX_TYPE", intern = FALSE)
  system("echo $STAN_HAS_CXX17", intern = FALSE)
  
  # Print cmdstan path
  cat("\nCmdStan location checks:\n")
  cat("- cmdstan_path(): ", cmdstanr::cmdstan_path(), "\n")
  
  # Check if the directory exists
  cmdstan_dir <- cmdstanr::cmdstan_path()
  cat("- Directory exists: ", file.exists(cmdstan_dir), "\n")
  
  # List files in the directory
  cat("- Files in directory:\n")
  system(paste("ls -la", cmdstan_dir), intern = FALSE)
}) 