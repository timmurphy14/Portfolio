# 03_fit_models.R
# Fit ARIMA-GARCH models, validate residuals, and forecast volatility

source("src/02_diagnostics.R")

# Mean model selection
auto.arima(log.ret)

# ARMA-GARCH with Gaussian innovations
model = garchFit(formula = ~ arma(0, 1) + garch(1, 1), 
                 data = log.ret, trace = FALSE)

model.sum = summary(model) 
model.sum$ics["AIC"] 
model.sum$ics["BIC"] 

capture.output(model.sum, file = "data/garch_normal_summary.txt")

# Residual diagnostics

res = residuals(model, standardize = T)
acf(res)
acf(res^2)
acf(abs(res))

qqnorm(res); qqline(res) 
ks.test(res, "pnorm")

# GARCH with Student-t innovations
kurtosis(log.ret)

model2 = garchFit(formula = ~ garch(1, 1), 
                  data = log.ret, 
                  trace = FALSE, 
                  cond.dist = "std")

model2.sum = summary(model2)
model2.sum$ics["AIC"]
model2.sum$ics["BIC"]

capture.output(model2.sum, file = "data/garch_student_summary.txt")

# Residual diagnostics
res2 = residuals(model2, standardize = T)
acf(res2)
acf(res2^2)
acf(abs(res2))

set.seed(10)
x = rstd(1000, mean = 0, sd = 1, nu = 3.482)
ks.test(res2, x)

# Volatility forecast
png("figures/garch_vol_forecast.png", width = 1000, height = 700)
predict(model2, n.ahead = 10, plot = TRUE)
dev.off()

