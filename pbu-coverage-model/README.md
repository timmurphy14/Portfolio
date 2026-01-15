# NFL Big Data Bowl – Pass Breakup (PBU) Prediction Model

## Overview

As part of the 2026 NFL Big Data Bowl (Analytics Track), participants were tasked with
describing player movement while the ball is in the air in a way that is accessible to
coaches and football fans. Working as part of a team, we analyzed how player movement
and contextual factors influence the probability that a pass breakup (PBU) occurs.

Pass breakups are a critical component of strong pass defense and play a major role in
limiting offensive success by preventing completions and keeping offenses behind the
sticks. Although PBUs are relatively rare events, our analysis identified several key
pre-throw and post-throw indicators associated with an increased likelihood of a pass
breakup.

This project focuses on translating high-resolution player tracking data into
interpretable features that help explain what successful pass coverage looks like.

---

## Data

**Source:**  
Publicly available NFL player tracking and contextual data released on Kaggle for the
2026 NFL Big Data Bowl competition.

**Time frame:**  
Weeks 1–18 of the 2023 NFL regular season.

**Unit of observation:**  
- Tracking data: player–frame level  
- Modeling data: pass-play level  

**Data types:**  
- **Pre-throw tracking data:** Full player–frame level information for all players on the
  field, including positional coordinates, speed, and movement direction prior to the
  pass being thrown.
- **Post-throw tracking data:** Positional coordinates only for players of interest
  (targeted receiver and nearest defenders) while the ball is in the air.
- **Play-level contextual data:** Game situation variables and pass outcomes.

**Access:**  
The data is publicly available via Kaggle as part of the NFL Big Data Bowl competition.
Raw data files are not included in this repository due to size, but all data processing,
feature engineering, and modeling code is provided.

---

## Methods

### Feature Engineering

Tracking data was transformed into interpretable spatial and temporal features designed
to capture defender positioning and movement relative to the targeted receiver.

Key feature groups included:
- Receiver–defender separation at key moments
- Closing speed and directional alignment
- Relative leverage and spatial positioning
- Game context controls (down, distance, coverage indicators)

Due to differences in data availability, velocity-based features were primarily derived
from pre-throw frames, while post-throw features emphasized spatial relationships.

---

### Modeling Approach

Given the rarity of PBUs, the task was framed as a binary classification problem with
class imbalance considerations.

Models explored included:
- Logistic Regression (baseline and interpretability)
- Tree-based models for capturing nonlinear relationships

Model performance was evaluated using classification metrics appropriate for rare
events, including ROC-AUC and precision-recall analysis.

---

## Results

The analysis revealed that both pre-throw positioning and post-throw spatial dynamics
play important roles in predicting pass breakups.

Key findings included:
- Defensive leverage and separation prior to the throw are strong predictors of PBUs
- Closing speed immediately before the throw carries meaningful signal
- Post-throw spatial positioning can meaningfully distinguish contested incompletions
  from clean pass breakups

These results suggest that PBUs are not solely reactive plays, but are often set up by
defender positioning and movement before the ball is released.

---

## Key Takeaways

- Player tracking data can be translated into interpretable coverage metrics
- Successful pass defense is influenced by both anticipation and reaction
- Rare defensive events like PBUs can be modeled effectively with careful feature design
- Data availability constraints meaningfully shape modeling choices

---

## Repository Structure

```text
pbu-pass-breakup-prediction/
│
├── README.md
├── data/ # Data dictionaries / derived features (no raw tracking data)
├── src/ # Feature engineering and modeling scripts
├── notebooks/ # Exploratory analysis and visualization
└── figures/ # Plots and visual outputs
```
---

## Tools & Technologies

- R
- tidyverse (dplyr, stringr)
- xgboost
- ggridges
- ggplot2

---

## Acknowledgments

This project was completed as part of the 2026 NFL Big Data Bowl competition using
publicly released NFL player tracking data.

