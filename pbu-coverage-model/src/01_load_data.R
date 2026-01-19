# src/01_load_data.R
# Load raw contextual and weekly tracking data

source("src/00_load_packages.R")

#Contextual data
raw_context <- read_csv("data/supplementary_data.csv", show_col_types = FALSE)

#Weeks to load
weeks <- sprintf("%02d", 1:18)

#Initialize storage
raw_inputs  <- list()
raw_outputs <- list()

#Load weekly tracking data
for (w in weeks) {
  raw_inputs[[w]]  <- read_csv(
    paste0("data/input_2023_w", w, ".csv"), 
    show_col_types = FALSE
    )
  
  raw_outputs[[w]] <- read_csv(
    paste0("data/output_2023_w", w, ".csv"), 
    show_col_types = FALSE
    )
}
