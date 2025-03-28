# Diagnostic script for Stan/cmdstanr
cat("Starting Stan/cmdstanr diagnostics...\n")

# Check system information
cat("\nSystem information:\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("OS:", Sys.info()["sysname"], "\n")
cat("Machine:", Sys.info()["machine"], "\n")

# Check for cmdstanr
cat("\nChecking cmdstanr installation:\n")
if (requireNamespace("cmdstanr", quietly = TRUE)) {
  cat("cmdstanr is installed.\n")
  
  # Check cmdstanr version
  cat("cmdstanr version:", packageVersion("cmdstanr"), "\n")
  
  # Check if cmdstan path exists
  cmdstan_path <- tryCatch({
    cmdstanr::cmdstan_path()
  }, error = function(e) {
    cat("Error getting cmdstan path:", conditionMessage(e), "\n")
    return(NULL)
  })
  
  if (!is.null(cmdstan_path)) {
    cat("cmdstan path:", cmdstan_path, "\n")
    cat("cmdstan path exists:", file.exists(cmdstan_path), "\n")
  }
  
  # Check toolchain
  cat("\nChecking toolchain:\n")
  tryCatch({
    cmdstanr::check_cmdstan_toolchain(fix = FALSE)
    cat("Toolchain check passed.\n")
  }, error = function(e) {
    cat("Toolchain check failed:", conditionMessage(e), "\n")
  })
  
  # Try to find the make/local file
  potential_locations <- c(
    file.path(cmdstan_path, "make", "local"),
    file.path(Sys.getenv("HOME"), ".cmdstan", "make", "local")
  )
  
  cat("\nLooking for make/local file:\n")
  for (loc in potential_locations) {
    cat("Checking", loc, ":", file.exists(loc), "\n")
    if (file.exists(loc)) {
      cat("Contents of", loc, ":\n")
      cat(readLines(loc), sep = "\n")
    }
  }
  
  # Check for TBB_CXX_TYPE environment variable
  cat("\nChecking environment variables:\n")
  cat("TBB_CXX_TYPE:", Sys.getenv("TBB_CXX_TYPE"), "\n")
  cat("STAN_HAS_CXX17:", Sys.getenv("STAN_HAS_CXX17"), "\n")
  
  # Check R Makevars
  r_makevars_path <- file.path(Sys.getenv("HOME"), ".R", "Makevars")
  cat("\nChecking R Makevars:", file.exists(r_makevars_path), "\n")
  if (file.exists(r_makevars_path)) {
    cat("Contents of", r_makevars_path, ":\n")
    cat(readLines(r_makevars_path), sep = "\n")
  }
  
  # Try a simple Stan model compilation
  cat("\nTrying to compile a simple Stan model:\n")
  tryCatch({
    # Create a simple Stan model
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
    tempfile <- tempfile(fileext = ".stan")
    writeLines(stan_code, tempfile)
    
    # Try to compile it
    mod <- cmdstanr::cmdstan_model(tempfile, compile = TRUE, quiet = FALSE)
    cat("Model compilation succeeded!\n")
    
    # Clean up
    file.remove(tempfile)
  }, error = function(e) {
    cat("Model compilation failed:", conditionMessage(e), "\n")
    cat("For detailed error information, use traceback() in the interactive console.\n")
  })
  
} else {
  cat("cmdstanr is not installed.\n")
  
  # Try to install cmdstanr
  cat("\nAttempting to install cmdstanr:\n")
  tryCatch({
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }
    remotes::install_github("stan-dev/cmdstanr")
    cat("cmdstanr installation succeeded.\n")
  }, error = function(e) {
    cat("cmdstanr installation failed:", conditionMessage(e), "\n")
  })
}

cat("\nDiagnostics complete.\n") 