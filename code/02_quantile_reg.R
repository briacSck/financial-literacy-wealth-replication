################################################################################
# PROJECT: Financial Literacy and Wealth Accumulation
# AUTHOR:  Briac Sockalingum
# DATE:    Spring 2024
# PURPOSE: R implementation of Table 3 median regressions
################################################################################

# Load packages
library(haven)      # Read Stata files
library(dplyr)      # Data manipulation
library(quantreg)   # Quantile regression
library(DescTools)  # Winsorization
library(stargazer)  # Export tables

# Set working directory
# setwd("path/to/repo")

################################################################################
# 1. LOAD DATA
################################################################################

# Load datasets
pub <- read_dta("data/p19i6.dta") %>%
  rename_all(tolower) %>%
  select(y1, x8023, x42001)

weights <- read_dta("data/p19_rw1.dta") %>%
  rename_all(tolower)

scf <- read_dta("data/rscfp2019.dta") %>%
  rename_all(tolower) %>%
  select(yy1, y1, age, hhsex, edcl, racecl4, occat1, kids,
         finlit, income, networth, asset, fin, nfin)

# Merge
scf <- scf %>%
  left_join(weights, by = c("y1" = "y1")) %>%
  left_join(pub, by = "y1")

# Create implicate number
scf <- scf %>%
  mutate(implic = y1 - 10 * yy1)

################################################################################
# 2. DATA PREPARATION
################################################################################

# Winsorize function (5th to 95th percentile)
winsorize_vars <- function(data, vars, implic_val) {
  data_imp <- data %>% filter(implic == implic_val)
  
  for (var in vars) {
    data_imp[[var]] <- Winsorize(data_imp[[var]], probs = c(0.05, 0.95), 
                                   na.rm = TRUE)
  }
  
  return(data_imp)
}

# Apply winsorization to each implicate
wealth_vars <- c("networth", "asset", "fin", "nfin", "income")

scf_clean <- bind_rows(
  lapply(1:5, function(i) winsorize_vars(scf, wealth_vars, i))
)

# Create variables
scf_clean <- scf_clean %>%
  mutate(
    # Wealth ratio
    rwlth_incm = networth / income,
    
    # Demographics
    female = as.numeric(hhsex == 2),
    black = as.numeric(racecl4 == 2),
    hispanic = as.numeric(racecl4 == 3),
    raceoth = as.numeric(racecl4 == 4),
    
    # Education (ref: college+)
    ed_lshs = as.numeric(edcl == 1),
    ed_hs = as.numeric(edcl == 2),
    ed_sc = as.numeric(edcl == 3),
    
    # Marital status
    married = as.numeric(x8023 %in% c(1, 2)),
    widowed = as.numeric(x8023 == 5),
    ntmarried = as.numeric(x8023 == 6),
    
    # Employment
    slfemply = as.numeric(occat1 == 2),
    rtrddsbl = as.numeric(occat1 == 3),
    ntworkng = as.numeric(occat1 == 4),
    
    # Financial literacy
    finlit_3c = as.numeric(finlit == 3),
    
    # Rescale to $100k
    networth100k = networth / 100000,
    fin100k = fin / 100000,
    nfin100k = nfin / 100000,
    income100k = income / 100000
  )

# Winsorize wealth ratio
for (i in 1:5) {
  scf_clean$rwlth_incm[scf_clean$implic == i] <- 
    Winsorize(scf_clean$rwlth_incm[scf_clean$implic == i], 
              probs = c(0.05, 0.95), na.rm = TRUE)
}

# Keep first implicate
scf_final <- scf_clean %>% filter(implic == 1)

################################################################################
# 3. REGRESSIONS
################################################################################

# Control variables
controls <- c("age", "female", "black", "hispanic", "raceoth",
              "ed_lshs", "ed_hs", "ed_sc",
              "married", "widowed", "ntmarried", "kids",
              "slfemply", "rtrddsbl", "ntworkng", "income100k")

# Outcome variables
outcomes <- c("networth100k", "fin100k", "nfin100k", "rwlth_incm")

# Panel A: FinLit Index
models_finlit <- list()

for (outcome in outcomes) {
  formula <- as.formula(paste(outcome, "~ finlit +", 
                              paste(controls, collapse = " + ")))
  
  model <- rq(formula, data = scf_final, tau = 0.5, 
              weights = x42001)
  
  models_finlit[[outcome]] <- model
}

# Panel B: All Big Three Correct
models_big3 <- list()

for (outcome in outcomes) {
  formula <- as.formula(paste(outcome, "~ finlit_3c +", 
                              paste(controls, collapse = " + ")))
  
  model <- rq(formula, data = scf_final, tau = 0.5, 
              weights = x42001)
  
  models_big3[[outcome]] <- model
}

################################################################################
# 4. EXPORT RESULTS
################################################################################

# Panel A
stargazer(models_finlit,
          type = "text",
          out = "output/tables/table3a_R.txt",
          title = "Panel A: FinLit Index (0-3)",
          dep.var.labels = c("Net Worth", "Fin Assets", 
                             "Non-Fin Assets", "Wealth/Income"),
          covariate.labels = c("FinLit Score"),
          keep = c("finlit"),
          digits = 3)

# Panel B
stargazer(models_big3,
          type = "text",
          out = "output/tables/table3b_R.txt",
          title = "Panel B: All Big Three Correct",
          dep.var.labels = c("Net Worth", "Fin Assets", 
                             "Non-Fin Assets", "Wealth/Income"),
          covariate.labels = c("All Big Three Correct"),
          keep = c("finlit_3c"),
          digits = 3)

cat("\n========================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("========================================\n")
cat("Output saved to: output/tables/\n")