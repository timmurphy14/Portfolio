# 02_diagnostics.R
# Compute log returns and run diagnostic tests/plots

source("src/01_get_data.R")

dir.create("figures", showWarnings = FALSE)

# Price series
png("figures/wmt_adj_close.png", width = 800, height = 500)
chart_Series(adj.close, name = "WMT: Adjusted Close Prices")
dev.off()

# Log Returns
log.ret = diff(log(adj.close))[-1]

png("figures/wmt_log_returns.png", width = 800, height = 500)
chart_Series(log.ret, name = "WMT: Log Returns")
dev.off()

# Serial correlation and stationarity 
acf(log.ret)
Box.test(log.ret, type = "Ljung")
adf.test(log.ret)
kpss.test(log.ret)

# Volatility clustering 
acf(abs(log.ret))
acf(log.ret^2)
Box.test(abs(log.ret), type = "Ljung")
Box.test(log.ret^2, type = "Ljung")

