# 01_get_data.R
# Retrieve adjusted closing prices for Walmart (WMT)

source("src/00_load_packages.R")

dir.create("data", showWarnings = FALSE)

getSymbols("WMT", from = "2020-01-01", to = "2025-12-07", src = "yahoo")
adj.close <- Ad(WMT)

# Save adjusted prices for reproducibility
write.zoo(adj.close, file = "data/wmt_adj_close.csv", sep = ",")
