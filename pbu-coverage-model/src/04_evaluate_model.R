# src/04_evaluate_model.R
# Evaluate trained models and generate figures

source("src/00_load_packages.R")

# Load data and models
model_temporal <- read_csv("data/model_temporal.csv", show_col_types = FALSE)

logit_model <- readRDS("data/logit_model.rds")
xgb_model   <- readRDS("data/xgb_model.rds")

train_idx <- readRDS("data/train_idx.rds")

test_data <- model_temporal[-train_idx, ]
test_y    <- as.integer(test_data$pbu)

# Logistic regression predictions
test_data$logit_prob <- predict(
  logit_model,
  newdata = test_data,
  type = "response"
)

# XGBoost predictions
xgb_obj <- readRDS("data/xgb_matrix.rds")

X_test <- xgb_obj$X_all[xgb_obj$test_rows, , drop = FALSE]
dtest  <- xgb.DMatrix(X_test, label = test_y)

test_data$xgb_prob <- predict(xgb_model, dtest)

# Confusion matrices
threshold <- 0.20

test_data <- test_data %>%
  mutate(
    logit_pred = ifelse(logit_prob > threshold, 1, 0),
    xgb_pred   = ifelse(xgb_prob   > threshold, 1, 0)
  )

table(Logit_Actual = test_y, Logit_Pred = test_data$logit_pred)
table(XGB_Actual   = test_y, XGB_Pred   = test_data$xgb_pred)

# Logistic regression odds ratios 
coef_df <- as.data.frame(coef(summary(logit_model))) 
coef_df$term <- rownames(coef_df) 
rownames(coef_df) <- NULL 
names(coef_df) <- c("Estimate", "StdError", "z", "p", "term") 

coef_df <- coef_df %>% 
  mutate( OR = exp(Estimate), 
          OR_low = exp(Estimate - 1.96 * StdError), 
          OR_high = exp(Estimate + 1.96 * StdError) 
          ) 
keep_terms <- c( 
  "sep_pre_mean", 
  "sep_pre_slope",
  "gap_ball_last", 
  "gap_ball_min", 
  "def_ball_min", 
  "tr_ball_mean" 
  ) 
coef_plot <- coef_df %>% 
  filter(term %in% keep_terms) %>% 
  mutate(term = factor(term, levels = rev(keep_terms))) 

p_or <- ggplot(coef_plot, aes(term, OR)) +
  geom_point(size = 3, color = "#1f77b4") +
  geom_errorbar(
    aes(ymin = OR_low, ymax = OR_high),
    width = 0.2,
    color = "#1f77b4"
  ) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  scale_y_log10() +
  coord_flip() +
  labs(
    title = "Logistic Regression Odds Ratios",
    x = "Feature",
    y = "Odds Ratio (log scale)"
  ) +
  theme_minimal() 

ggsave(
  "figures/logit_odds_ratios.png", 
  p_or, 
  width = 7, 
  height = 5, 
  dpi = 300,
  bg = "white"
  )



# ROC curves
roc_df <- function(y, p) {
  ord <- order(p, decreasing = TRUE)
  y <- y[ord]
  
  P <- sum(y == 1)
  N <- sum(y == 0)
  
  tibble(
    fpr = cumsum(y == 0) / N,
    tpr = cumsum(y == 1) / P
  )
}

roc_logit <- roc_df(test_y, test_data$logit_prob)
roc_xgb   <- roc_df(test_y, test_data$xgb_prob)

p_roc <- ggplot() +
  geom_line(data = roc_logit, aes(fpr, tpr), color = "blue") +
  geom_line(data = roc_xgb,   aes(fpr, tpr), color = "red") +
  geom_abline(linetype = "dashed") +
  theme_minimal() +
  labs(
    title = "ROC Curves",
    x = "False Positive Rate",
    y = "True Positive Rate"
  )

ggsave(
  "figures/roc_curves.png", 
  p_roc, 
  width = 7, 
  height = 5, 
  dpi = 300,
  bg = "white"
)

# Precision–Recall curves
pr_df <- function(y, p) {
  ord <- order(p, decreasing = TRUE)
  y <- y[ord]
  
  tp <- cumsum(y == 1)
  fp <- cumsum(y == 0)
  
  tibble(
    recall = tp / sum(y == 1),
    precision = tp / (tp + fp)
  )
}

pr_logit <- pr_df(test_y, test_data$logit_prob)
pr_xgb   <- pr_df(test_y, test_data$xgb_prob)

p_pr <- ggplot() +
  geom_line(data = pr_logit, aes(recall, precision), color = "blue") +
  geom_line(data = pr_xgb,   aes(recall, precision), color = "red") +
  theme_minimal() +
  labs(
    title = "Precision–Recall Curves",
    x = "Recall",
    y = "Precision"
  )

ggsave(
  "figures/pr_curves.png", 
  p_pr, 
  width = 7, 
  height = 5, 
  dpi = 300,
  bg = "white"
)

# Feature importance
imp <- xgb.importance(model = xgb_model)
write_csv(imp, "data/xgb_feature_importance.csv")

top20 <- imp %>%
  slice_head(n = 20) %>%
  mutate(Feature = factor(Feature, levels = rev(Feature)))

p_imp <- ggplot(top20, aes(Feature, Gain)) +
  geom_col() +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "XGBoost Feature Importance (Top 20)",
    x = "Feature",
    y = "Gain"
  )

ggsave(
  "figures/xgb_feature_importance.png", 
  p_imp, 
  width = 7, 
  height = 5, 
  dpi = 300,
  bg = "white"
)

# Save predictions
preds_out <- test_data %>%
  select(game_id, play_id, def_nfl_id, week, pbu, logit_prob, xgb_prob)

write_csv(preds_out, "data/test_set_predictions.csv")
