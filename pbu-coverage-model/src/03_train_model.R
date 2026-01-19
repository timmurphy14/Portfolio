# src/03_train_models.R
# Train baseline and tree-based models for PBU prediction

source("src/00_load_packages.R")

# Load modeling dataset
model_temporal <- read_csv(
  "data/model_temporal.csv",
  show_col_types = FALSE
)

# Train / test split (stratified by PBU)
set.seed(123)

pbu_index <- model_temporal$pbu

train_idx <- unlist(
  tapply(seq_along(pbu_index), pbu_index,
         function(idx) sample(idx, length(idx) * 0.8))
)

train_data <- model_temporal[train_idx, ]
test_data  <- model_temporal[-train_idx, ]

# Check class balance
prop.table(table(train_data$pbu))
prop.table(table(test_data$pbu))

# Logistic regression (baseline, interpretable)
logit_formula <- pbu ~ . - game_id - play_id - def_nfl_id - week

logit_model <- glm(
  logit_formula,
  data = train_data,
  family = binomial(link = "logit")
)

summary(logit_model)

# XGBoost (nonlinear model)
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

train_idx <- which(all_data$set == "train")
test_idx  <- which(all_data$set == "test")

train_x <- X_all[train_idx, ]
test_x  <- X_all[test_idx, ]

train_y <- as.numeric(train_data$pbu) - 1
test_y  <- as.numeric(test_data$pbu) - 1

dtrain <- xgb.DMatrix(data = train_x, label = train_y)
dtest  <- xgb.DMatrix(data = test_x,  label = test_y)

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

# Save trained models for evaluation
saveRDS(logit_model, "data/logit_model.rds")
saveRDS(xgb_model,   "data/xgb_model.rds")
