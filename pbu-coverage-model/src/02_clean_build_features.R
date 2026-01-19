# src/02_clean_build_features.R
#Clean raw data and build features for modeling

source("src/01_load_data.R")

#Create binary PBU indicator from play_description and annotate player credited with PBU
context_all <- raw_context %>%
  mutate(
    pbu = as.integer(str_detect(play_description,
                                regex("pass incomplete.*\\([A-Z]\\.[A-Za-z'\\-]+\\)", ignore_case = TRUE)
    )),
    defender_pbu = str_match(play_description,
                             regex("pass incomplete.*\\(([A-Z]\\.[A-Za-z'\\-]+)\\)", ignore_case = TRUE)
    )[,2]
  )


# Combine weekly inputs/outputs into single tables
input_all <- bind_rows(raw_inputs, .id = "week_str") %>%
  mutate(week = as.integer(week_str)) %>%
  select(-week_str)

output_all <- bind_rows(raw_outputs, .id = "week_str") %>%
  mutate(week = as.integer(week_str)) %>%
  select(-week_str)

# Map player roles for the player_to_predict rows (from input) onto output rows
role_map <- input_all %>%
  filter(player_to_predict) %>%
  group_by(game_id, play_id, nfl_id) %>%
  summarise(
    player_role = dplyr::first(player_role),
    .groups = "drop"
  )

output_all <- output_all %>%
  left_join(role_map, by = c("game_id", "play_id", "nfl_id"))

#Create helper function: Gets slope from simple Linear Regression of y~t
slope_lm <- function(y, t) {
  if (length(unique(t[!is.na(y)])) < 2L) return(NA_real_)
  coef(lm(y ~ t))[2]
}

#Select input data for players to predict (output data given)
pre_frames <- input_all %>%
  filter(player_to_predict,
         player_role %in% c("Targeted Receiver", "Defensive Coverage")) %>%
  select(game_id, play_id, week, nfl_id, player_role,
         frame_id, x, y, s, a, o, dir)

#Change names for Targeted Receiver(TR) and Defender(DEF) variables
tr_pre_frames <- pre_frames %>%
  filter(player_role == "Targeted Receiver") %>%
  select(game_id, play_id, frame_id,
         tr_x = x, tr_y = y,
         tr_s = s, tr_a = a, tr_o = o, tr_dir = dir)

def_pre_frames <- pre_frames %>%
  filter(player_role == "Defensive Coverage") %>%
  select(game_id, play_id, week,
         def_nfl_id = nfl_id,
         frame_id,
         def_x = x, def_y = y,
         def_s = s, def_a = a, def_o = o, def_dir = dir)

#Join TR and DEF pre-throw data and compute pre-throw features
pre_joined <- def_pre_frames %>%
  left_join(tr_pre_frames,
            by = c("game_id","play_id","frame_id")) %>%
  mutate(
    sep = sqrt((def_x - tr_x)^2 + (def_y - tr_y)^2)
  )

pre_summary <- pre_joined %>%
  group_by(game_id, play_id, def_nfl_id, week) %>%
  summarise(
    n_frames_pre   = n(),
    sep_pre_last   = sep[which.max(frame_id)],
    sep_pre_min    = min(sep, na.rm = TRUE),
    sep_pre_mean   = mean(sep, na.rm = TRUE),
    sep_pre_slope  = slope_lm(sep, frame_id),
    tr_s_pre_mean  = mean(tr_s, na.rm = TRUE),
    tr_s_pre_max   = max(tr_s, na.rm = TRUE),
    def_s_pre_mean = mean(def_s, na.rm = TRUE),
    def_s_pre_max  = max(def_s, na.rm = TRUE),
    .groups = "drop"
  )

#Join post-throw data for TR, DEF and ball coordinates (from input)
ball_info <- input_all %>%
  filter(player_to_predict) %>%
  distinct(game_id, play_id, ball_land_x, ball_land_y)


tr_post_frames <- output_all %>%
  filter(player_role == "Targeted Receiver") %>%
  select(game_id, play_id, frame_id,
         tr_x = x, tr_y = y)

def_post_frames <- output_all %>%
  filter(player_role == "Defensive Coverage") %>%
  select(game_id, play_id, def_nfl_id = nfl_id,
         frame_id,
         def_x = x, def_y = y)

post_joined <- def_post_frames %>%
  left_join(tr_post_frames,
            by = c("game_id","play_id","frame_id")) %>%
  left_join(ball_info,
            by = c("game_id","play_id")) %>%
  mutate(
    tr_ball_dist  = sqrt((tr_x  - ball_land_x)^2 + (tr_y  - ball_land_y)^2),
    def_ball_dist = sqrt((def_x - ball_land_x)^2 + (def_y - ball_land_y)^2),
    gap_ball      = tr_ball_dist - def_ball_dist
  )

#Create post-throw features 
post_summary <- post_joined %>%
  group_by(game_id, play_id, def_nfl_id) %>%
  summarise(
    n_frames_post     = n(),
    tr_ball_last      = tr_ball_dist[which.max(frame_id)],
    tr_ball_min       = min(tr_ball_dist, na.rm = TRUE),
    tr_ball_mean      = mean(tr_ball_dist, na.rm = TRUE),
    tr_ball_slope     = slope_lm(tr_ball_dist, frame_id),
    def_ball_last     = def_ball_dist[which.max(frame_id)],
    def_ball_min      = min(def_ball_dist, na.rm = TRUE),
    def_ball_mean     = mean(def_ball_dist, na.rm = TRUE),
    def_ball_slope    = slope_lm(def_ball_dist, frame_id),
    gap_ball_last     = gap_ball[which.max(frame_id)],
    gap_ball_min      = min(gap_ball, na.rm = TRUE),
    gap_ball_mean     = mean(gap_ball, na.rm = TRUE),
    gap_ball_slope    = slope_lm(gap_ball, frame_id),
    def_beats_tr_last = as.integer(def_ball_last < tr_ball_last),
    .groups = "drop"
  )

#Slice to only include one defender (closest to ball at final frame)
defender_features <- pre_summary %>%
  inner_join(post_summary,
             by = c("game_id", "play_id", "def_nfl_id"))

play_temporal_features <- defender_features %>%
  group_by(game_id, play_id) %>%
  slice_min(def_ball_last, n = 1, with_ties = FALSE) %>%
  ungroup()

#Create absolute yardline feature for context data
context_all <- context_all %>%
  mutate(
    absolute_yardline_number =
      case_when(
        is.na(yardline_side) & yardline_number == 50 ~ 50,
        yardline_side == possession_team ~ yardline_number,
        !is.na(yardline_side) & yardline_side != possession_team ~ 100 - yardline_number,
        TRUE ~ NA_real_
      )
  )

#Final Modeling Table 
model_temporal <- context_all %>%
  select(
    game_id, play_id,
    pbu,                   
    down, yards_to_go,
    absolute_yardline_number,
    pass_result,
    offense_formation,
    receiver_alignment,
    route_of_targeted_receiver,
    team_coverage_type,
    team_coverage_man_zone
  ) %>%
  inner_join(play_temporal_features,
             by = c("game_id", "play_id")) %>%
  mutate(
    pbu = as.integer(pbu)
  )
#Standardize missing values
model_temporal <- model_temporal %>%
  mutate(
    route_of_targeted_receiver = tidyr::replace_na(route_of_targeted_receiver, "Unknown"),
    team_coverage_type = tidyr::replace_na(team_coverage_type, "Unknown"),
    team_coverage_man_zone = tidyr::replace_na(team_coverage_man_zone, "Unknown")
  )

#Factors
model_temporal <- model_temporal %>%
  mutate(
    pbu = factor(pbu, levels = c(0, 1)),
    pass_result = factor(pass_result),
    offense_formation = factor(offense_formation),
    receiver_alignment = factor(receiver_alignment),
    route_of_targeted_receiver = factor(route_of_targeted_receiver),
    team_coverage_type = factor(team_coverage_type),
    team_coverage_man_zone = factor(team_coverage_man_zone)
  )

model_temporal <- model_temporal %>%
  select(-pass_result)

#Save dataset for modeling
write_csv(model_temporal, "data/model_temporal.csv")
