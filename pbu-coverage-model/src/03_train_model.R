# src/03_train_model.R
# Train baseline and tree-based models for PBU prediction

source("src/00_load_packages.R")

# Load modeling dataset
model_temporal <- read_csv("data/model_temporal.csv", show_col_types = FALSE) %>%
  mutate(pbu = as.integer(pbu))

# Train / test split (stratified by PBU)
set.seed(123)

pbu_index <- model_temporal$pbu

train_idx <- unlist(
  tapply(seq_along(pbu_index), pbu_index,
         function(idx) sample(idx, length(idx) * 0.8))
)

# Save split for evaluation
saveRDS(train_idx, "data/train_idx.rds")

train_data <- model_temporal[train_idx, ]
test_data  <- model_temporal[-train_idx, ]

# Logistic regression
logit_formula <- pbu ~ . - game_id - play_id - def_nfl_id - week

logit_model <- glm(
  logit_formula,
  data = train_data,
  family = binomial(link = "logit")
)

# XGBoost
train_data$set <- "train"
test_data$set  <- "test"

all_data <- bind_rows(train_data, test_data)

all_data_xgb <- all_data %>%
  select(
    -pbu,
    -set,
    -team_coverage_man_zone,
    -game_id,
    -play_id,
    -def_nfl_id
  )

X_all <- model.matrix(~ . - 1, data = all_data_xgb)

train_rows <- which(all_data$set == "train")
test_rows  <- which(all_data$set == "test")

train_x <- X_all[train_rows, , drop = FALSE]
test_x  <- X_all[test_rows,  , drop = FALSE]

train_y <- train_data$pbu
test_y  <- test_data$pbu

dtrain <- xgb.DMatrix(train_x, label = train_y)
dtest  <- xgb.DMatrix(test_x,  label = test_y)

params <- list(
  objective = "binary:logistic",
  eval_metric = "logloss",
  eta = 0.05,
  max_depth = 5,
  subsample = 0.8,
  colsample_bytree = 0.8,
  scale_pos_weight = 9.416
)

set.seed(123)
xgb_model <- xgb.train(
  params = params,
  data = dtrain,
  nrounds = 500,
  watchlist = list(train = dtrain, test = dtest),
  early_stopping_rounds = 30,
  print_every_n = 50
)

# Save models and matrix for evaluation
saveRDS(logit_model, "data/logit_model.rds")
saveRDS(xgb_model,   "data/xgb_model.rds")

saveRDS(
  list(X_all = X_all, train_rows = train_rows, test_rows = test_rows),
  "data/xgb_matrix.rds"
)
