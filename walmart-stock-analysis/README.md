# Walmart Stock Analysis

## Overview

This project analyzes the time-series behavior of Walmart (WMT) stock returns using standard techniques from financial econometrics. The focus is on understanding return dynamics, testing for stationarity and dependence, identifying volatility clustering, and applying GARCH models for conditional variance forecasting.

Rather than attempting to predict stock prices directly, the analysis emphasizes proper diagnostic testing and realistic modeling assumptions consistent with the Efficient Market Hypothesis.

---

## Data

Daily **adjusted closing price data** for Walmart (WMT) was obtained programmatically using the `quantmod` package. Adjusted prices account for dividends and stock splits and are standard for return-based financial modeling.

Prices were transformed into **log returns**, which exhibit more stable statistical properties and are appropriate for time-series analysis.

---

## Methods

### Return Diagnostics and Stationarity

The return series was examined using:

- Autocorrelation functions (ACF)
- Ljung–Box tests for serial correlation
- Stationarity checks on log returns

While raw prices exhibited strong non-stationarity, log returns were approximately stationary, confirming their suitability for modeling.

---

### Volatility Diagnostics

To assess volatility structure, the following diagnostics were conducted:

- ACF of absolute log returns
- ACF of squared log returns

Both diagnostics revealed persistent autocorrelation, indicating volatility clustering — a common feature of financial return series.

---

### Mean Process Modeling

An ARIMA model was initially fit to the return series using automated order selection (`auto.arima`) to capture any remaining linear dependence in the conditional mean.

Model diagnostics showed minimal improvement over a zero-mean specification. Consequently, the ARIMA component was removed to simplify the mean equation prior to volatility modeling.

---

### Volatility Modeling

A **GARCH(1,1)** model was fit to the return series to capture time-varying conditional variance.

Model adequacy was evaluated using:
- Residual diagnostics
- ACF of standardized residuals
- ACF of squared standardized residuals

The GARCH model successfully removed remaining volatility dependence, indicating a well-specified variance process.

---

### Forecasting

The finalized GARCH model was used to generate **out-of-sample volatility forecasts**. These forecasts reflect expected variability rather than directional price movement, aligning with empirical evidence that volatility is more predictable than returns.

---

## Results

Key findings include:
- Log returns are approximately stationary
- Limited serial dependence in returns
- Strong volatility clustering in absolute and squared returns
- GARCH models effectively capture conditional variance dynamics
- Volatility forecasts exhibit persistence consistent with financial theory

---

## Key Takeaways

- Financial price levels must be transformed before modeling
- Diagnostic testing is critical before model selection
- Volatility is more predictable than returns
- Separating mean and variance processes improves model clarity
- GARCH models remain a practical tool for financial risk analysis

---

## Tools & Technologies

- R
- quantmod
- tseries
- forecast
- fBasics
- fGarch
- ggplot2

---

## Notes

This project is intended to demonstrate sound financial time-series methodology rather than serve as a trading strategy. Emphasis is placed on diagnostics, model validation, and realistic expectations regarding predictability in financial markets.
