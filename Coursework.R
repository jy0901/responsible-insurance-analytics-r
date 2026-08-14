############################################################
# File: 00_setup.R
# Author: YOUR NAME
# Date: 2025-11-09
# R version: 4.5.1 
# Packages: tidyverse, readxl, ggplot2, dplyr, magrittr, keras3, reticulate
# Purpose: Global setup, reproducibility, and I/O helpers
# Inputs: travel_insurance.xlsx, property.xlsx, freMTPL2freq.csv
# Outputs: cleaned tibbles and model objects in memory
############################################################

rm(list = ls())

# ---- Packages ----
suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(ggplot2)
  library(dplyr)
  library(magrittr)
  library(keras3)       # keras v3 R package
  library(reticulate)
  library(MASS)         # box-cox transformation
})

set.seed(100)               # R seed

# ---- Paths ----
# setwd("...")  # set if needed
data_dir <- getwd()

# ---- Load data ----
df  <- readxl::read_excel(file.path(data_dir, "travel_insurance.xlsx"))
property <- readxl::read_excel(file.path(data_dir, "property.xlsx"))
dat    <- read.csv(file.path(data_dir, "freMTPL2freq.csv"))

# Quick structure (Part 2a, Part 4a)
str(df); str(property); str(dat)
############################################################
# File: 10_part2_travel_wrangle.R
# Author: YOUR NAME
# Date: 2025-11-09
# Purpose: Clean & transform travel_insurance per coursework
# Inputs: travel tibble
# Outputs: travel_clean with Box-Cox column and summaries
############################################################

#(a) Display structure and compute summary statistics
# Inspect the structure of the dataset
str(df)

# Compute summary statistics for each column
summary(df)


#(b) Range, IQR, 0.5 & 99.5 percentiles, outlier detection and replacement with NA
# Compute range and IQR for loss
options(scipen = 999)
loss_range <- range(df$loss, na.rm = TRUE)
loss_range_value <- diff(range(df$loss, na.rm = TRUE))
loss_iqr <- IQR(df$loss, na.rm = TRUE)

# Compute 0.5 and 99.5 percentiles
loss_quantiles <- quantile(df$loss, probs = c(0.005, 0.995), na.rm = TRUE)

loss_range
loss_range_value
loss_iqr
loss_quantiles

# Identify obvious outliers beyond 0.5 and 99.5 percentile
outlier_index <- which(df$loss < loss_quantiles[1] | df$loss > loss_quantiles[2])
length(outlier_index)
outlier_index

# Replace outlier loss values with NA
df$loss[outlier_index] <- NA

#(c) Remove rows with outlying (now NA) or negative loss values
# Remove rows where loss is NA (due to outliers)
df <- df %>% filter(!is.na(loss))

# Remove negative loss values
df <- df %>% filter(loss >= 0)

#(d) Perform a Box–Cox transformation on loss
# Box-Cox requires strictly positive values
# (after step (c), loss >= 0; to avoid zero issues, we can add a small constant)
df <- df %>% mutate(loss_pos = ifelse(loss == 0, 0.0001, loss))

df2 <- as.data.frame(df)

# Fit a linear model (Box–Cox works on lm objects)
bc_model <- lm(loss_pos ~ 1, data = df2)  # intercept-only model
bc_model


# Determine optimal lambda
bc_result <- boxcox(bc_model, lambda = seq(-2, 2, 0.1))
bc_result
lambda_opt <- bc_result$x[which.max(bc_result$y)]
lambda_opt

# Apply Box–Cox transformation
if (abs(lambda_opt) < 1e-6) {
  df2$loss_boxcox <- log(df2$loss_pos)
} else {
  df2$loss_boxcox <- (df2$loss_pos^lambda_opt - 1) / lambda_opt
}
# (e) Mean claim by gender (1=male, 2=female)
# Convert claimantGender to factor for clarity
df2$claimantGender <- factor(df2$claimantGender, levels = c(1, 2), labels = c("Male", "Female"))

# Group by gender and compute mean loss
mean_by_gender <- df2 %>%
  group_by(claimantGender) %>%
  summarise(mean_loss = mean(loss, na.rm = TRUE))

mean_by_gender

# (f) Age bands
df2 <- df2 %>%
  mutate(age_group = case_when(
    claimantAge <= 25 ~ "≤25",
    claimantAge >= 26 & claimantAge <= 35 ~ "26–35",
    claimantAge >= 36 & claimantAge <= 42 ~ "36–42",
    claimantAge >= 43 & claimantAge <= 72 ~ "43–72",
    claimantAge >= 73 ~ "≥73",
    TRUE ~ NA_character_
  ))

# Convert to factor with ordered levels
df2$age_group <- factor(df2$age_group,
                       levels = c("≤25", "26–35", "36–42", "43–72", "≥73"),
                       ordered = TRUE)

# Check distribution
table(df2$age_group)
############################################################
# File: 20_part3_pca_regression.R
# Author: YOUR NAME
# Date: 2025-11-09
# Purpose: PCA on predictors and PC regression for claimCost
# Inputs: property tibble
# Outputs: pca object, lm model, prediction for new policy
############################################################

# Choose predictors to match the new policy fields in the question
predictors <- c("propertyVal", "propertyAge", "distance", "duration")
X <- property %>% dplyr::select(all_of(predictors)) %>% as.matrix()
y <- property$claimCost

# (a) Most correlated pair (in full numeric set for completeness)
corr_all <- cor(property %>% dplyr::select(where(is.numeric)))
print(corr_all)

# (b) PCA (center/scale), retain >= 80% variation
pca <- princomp(X, cor = TRUE)
cumvar <- cumsum(pca$sdev^2) / sum(pca$sdev^2)
cumvar
n_pc <- which(cumvar >= 0.80)[1]
n_pc

# (c) PCA plot (biplot for first two PCs)
# Extract scores (Y) and loadings (V) from PCA
Y <- pca$scores         # observation coordinates
V <- pca$loadings       # variable loadings

# Create the biplot
biplot(Y[,1:2], V[,1:2],
       expand = 2.5,                          # stretch arrows for clarity
       xlab = "1st principal component",    # x-axis label
       ylab = "2nd principal component",    # y-axis label
       main = "PCA Biplot (PC1 vs PC2)",    # title
       cex = c(0.4, 0.4),                   # smaller points, larger text for variables
       xlim = c(-7, 7), ylim = c(-7, 7))    # control axis limits

# (d) PC regression: claimCost ~ first n_pc PCs
Z <- pca$scores[, 1:n_pc, drop = FALSE]
df_reg <- data.frame(y = y, Z)
fit <- lm(y ~ ., data = df_reg)
summary(fit)

# (e) Predict new policy
new_policy <- data.frame(
  propertyVal = 22,
  propertyAge = 14.5,
  distance    = 25,
  duration    = 10
)
# Step 1: Standardise using PCA parameters
new_scaled <- scale(as.matrix(new_policy),
                    center = pca$center,
                    scale  = pca$scale)

# Step 2: Project into PC space
new_scores <- new_scaled %*% pca$loadings[, 1:n_pc, drop = FALSE]
colnames(new_scores) <- paste0("Comp.", 1:n_pc)
rownames(new_scores) <- "pred_claimCost"
# Step 3: Predict claim cost
pred_claimCost <- predict(fit, newdata = as.data.frame(new_scores))
pred_claimCost
############################################################
# File: 30_part4_dnn_freq_keras3.R
# Author: YOUR NAME
# Date: 2025-11-09
# Purpose: Keras v3 model with embeddings, tanh, offset log(Exposure)
# Inputs: freMTPL2freq tibble
# Outputs: trained model
############################################################

# Coerce character -> factor
for (i in seq_along(dat)) {
  if (is.character(dat[[i]])) dat[[i]] <- factor(dat[[i]])
}

# Caps as per your spec
dat$ClaimNb  <- pmin(dat$ClaimNb,  4)
dat$Exposure <- pmin(dat$Exposure, 1)

# ====================== 2) Split =============================
set.seed(100)               # reproducible split
learn_idx <- sample(1:nrow(dat), round(0.9*nrow(dat)), replace = FALSE)
learn <- dat[learn_idx, ]
test  <- dat[-learn_idx, ]

# ====================== 3) Design matrices & offset ======================
# Safe min-max scaling to [-1, 1]
MM_scaling <- function(x){ 2*(x-min(x))/(max(x)-min(x)) - 1}

dat_NN <- data.frame(ClaimNb = dat$ClaimNb)
dat_NN$DriveAge <- MM_scaling(dat$DrivAge)
dat_NN$BonusMalus <- MM_scaling(dat$BonusMalus)
dat_NN$Area <- MM_scaling(as.integer(dat$Area))
dat_NN$VehPower <- MM_scaling(as.numeric(dat$VehPower))
dat_NN$VehAge <- MM_scaling(as.numeric(dat$VehAge))
dat_NN$Density <- MM_scaling(dat$Density)
dat_NN$VehGas <- MM_scaling(as.integer(dat$VehGas))

# ====================== 4) Learn Test Split ======================
learn_NN <- dat_NN[learn_idx, ]
test_NN  <- dat_NN[-learn_idx, ]

Design_learn <- as.matrix(learn_NN[, -1, drop = FALSE])
Design_test  <- as.matrix(test_NN[,  -1, drop = FALSE])

# Categorical inputs (use global levels, 0-based indices)
Br_learn <- as.matrix(as.integer(learn$VehBrand)) - 1
Br_test  <- as.matrix(as.integer(test$VehBrand))  - 1

Re_learn <- as.matrix(as.integer(learn$Region)) - 1
Re_test  <- as.matrix(as.integer(test$Region))  - 1

# Offset (log of Exposure)
Vol_learn <- as.matrix(learn$Exposure)
Vol_test  <- as.matrix(test$Exposure)
LogVol_learn <- log(Vol_learn)
LogVol_test <- log(Vol_test)

# Responses
Y_learn <- matrix(learn$ClaimNb, ncol = 1)
Y_test  <- matrix(test$ClaimNb,  ncol = 1)

# ====================== 4) Model (keras3) ================================
# Hyperparameters
q1 <- 32; q2 <- 24; q3 <- 16
qEmb <- 2
epochs <- 200
batchsize <- 10000

# Input layers
Design <- layer_input(shape = ncol(Design_learn), dtype = 'float32', name = 'Design')

# Input layer for categorical features

Br_ndistinct <- length(unique(learn$VehBrand)) # number of vehicle brands = 11
Re_ndistinct <- length(unique(learn$Region)) # number of regions = 21

VehBrand <- layer_input(shape = 1, dtype = 'int32', name = 'VehBrand')
Region <- layer_input(shape = 1, dtype = 'int32', name = 'Region')

# Input layer for Exposure (as the offset)
LogVol <- layer_input(shape = 1, dtype = 'float32', name = 'LogVol')
Vol <- layer_input(shape = 1, dtype = 'float32', name = 'Vol')


# Create embedding layer for categorical predictors (dimension: qEmb = 2)
# Vehicle Brand: 11 -> 2
# Region: 21 -> 2

BrEmb = VehBrand %>%
  layer_embedding(input_dim = Br_ndistinct, output_dim = qEmb, input_length = 1, name = 'BrEmb') %>%
  layer_flatten(name = 'Br_flat')
ReEmb = Region %>%
  layer_embedding(input_dim = Re_ndistinct, output_dim = qEmb, input_length = 1, name = 'ReEmb') %>%
  layer_flatten(name = 'Re_flat')




# Main architecture with 3 hidden layers
Network <- layer_concatenate(name = "concate")(list(Design, BrEmb, ReEmb)) |>

  # 1st hidden layer
  layer_dense(units = q1, activation = "tanh",   name = "hidden1") |>

  # 2nd hidden layer
  layer_dense(units = q2, activation = "tanh",   name = "hidden2") |>

  # 3rd hidden layer
  layer_dense(units = q3, activation = "tanh",   name = "hidden3") |>

  # provide one neuron in the output layer
  layer_dense(units = 1,  activation = "linear", name = "Network")
# Concatenate the three tensors — pass an UNNAMED list to the callable

 
  



# Output layer to combine the main architecture and the offset layer (Exposure)
Response = (Network + LogVol) %>%
  
  # give the response
  layer_dense(
    units = 1,
    activation = "exponential",
    name = "Response",
    trainable = FALSE,
    kernel_initializer = initializer_constant(1),
    bias_initializer   = initializer_constant(0)
  )
# ------------------ Step 2.5: Model configuration and fitting ------------------------------------

# Model assembly
model <- keras_model(inputs = c(Design, VehBrand, Region, LogVol), outputs = c(Response))

summary(model)

# Model configuration

model %>% compile(
  loss = 'poisson', # set poisson deviance loss function as the objective loss function
  optimizer = 'nadam'
)

# ====================== 5) Fit ================================
# Model fitting by running gradient descent method to minimize the objective loss function
{ 
  
  t1 <- proc.time()
  
  fit <- model %>% fit(
    
    list(Design_learn, Br_learn, Re_learn, LogVol_learn), # all predictors
    Y_learn, # response
    
    verbose = 1, # verbose = 0 silences the progress bar for the process
    # verbose = 1 shows the fitting process, incl. learning loss and validation loss, epoch by epoch
    
    epochs = epochs, # epochs = 1,000
    
    batch_size = batchsize, # batchsize = 10,000
    
    validation_split = 0.2 # 20% as validation set
    
  )
  
  print(proc.time()-t1)
}

# ====================== 6) Predict & deviance =================
# Predicted value of the claim numbers
learn$nn0 <- as.vector(model %>% predict(list(Design_learn, Br_learn, Re_learn, LogVol_learn)))
test$nn0 <- as.vector(model %>% predict(list(Design_test, Br_test, Re_test, LogVol_test)))

dev.loss <- function(y, mu, density.func) {
  logL.tilde <- log(density.func(y, y))
  logL.hat <- log(density.func(y, mu))
  2 * mean(logL.tilde - logL.hat)
}

dev.loss(y = learn$ClaimNb, mu = learn$nn0, dpois)



dev.loss(y = test$ClaimNb, mu = test$nn0, dpois)

