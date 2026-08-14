# responsible-insurance-analytics-r
Responsible Insurance Analytics in R
# Responsible Insurance Analytics in R

This repository contains the data, R code and final report for an actuarial data science project on responsible insurance analytics. The project combines data science ethics, insurance data wrangling, principal component analysis, linear regression and deep neural network modelling.

## Recommended Repository Name

`responsible-insurance-analytics-r`

## Project Overview

The aim of this project is to apply statistical and machine-learning methods to insurance datasets while also considering responsible and ethical use of algorithms in insurance.

The project has four main parts:

1. A discussion of regulations and data science ethics in insurance.
2. Data manipulation and wrangling using travel insurance loss data.
3. Principal Component Analysis (PCA) and linear regression using property insurance data.
4. Deep neural network modelling for motor insurance claim frequency.

The project demonstrates how classical actuarial methods and modern machine-learning techniques can be used together in an insurance analytics workflow.

## Files in This Repository

| File                    | Description                                                                                                                                                                                                     |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `travel_insurance.xlsx` | Travel insurance dataset used for data manipulation and wrangling. It includes claimant-level information such as age, gender, attorney involvement, accident type and claim loss.                              |
| `property.xlsx`         | Property insurance dataset used for PCA and principal-component regression. It includes variables such as property value, property age, distance, duration, claim count and claim cost.                         |
| `freMTPL2freq.csv`      | Motor insurance dataset used for deep neural network claim frequency modelling. It includes policy-level risk attributes, exposure and claim counts.                                                            |
| `Coursework.R`          | Main R script for the project. It loads the data, performs data cleaning, applies Box–Cox transformation, creates age bands, runs PCA, fits principal-component regression and trains a Poisson neural network. |
| `Report.pdf`         | Final report explaining the project background, methodology, results, model interpretation and conclusions.                                                                                                     |
| `Exercise.pdf`          | Original coursework brief describing the required tasks for ethics, data wrangling, PCA/regression and neural-network modelling.                                                                                |

## What the Exercise Does

This project applies actuarial data science methods to three insurance datasets.

First, the project discusses key ethical and regulatory principles for algorithmic decision-making in insurance. These include privacy, fairness, transparency, human oversight and solidarity. This provides the governance context for the modelling work.

Second, the travel insurance dataset is cleaned and analysed. The work includes checking the structure of the dataset, identifying outliers in the loss variable, removing invalid or negative losses, applying a Box–Cox transformation and creating age bands for claimants. The purpose is to prepare claim loss data for reliable analysis and interpretation.

Third, the property insurance dataset is used for Principal Component Analysis and linear regression. PCA is applied to reduce dimensionality and handle relationships between variables such as property value, property age, distance and duration. A regression model is then fitted using selected principal components, and the model is used to predict claim cost for a new policy.

Fourth, the motor insurance dataset is used to build a deep neural network for claim frequency modelling. Continuous variables are scaled, categorical variables are represented using embedding layers, and exposure is included using a log-exposure offset. The network is trained using Poisson deviance loss, which is suitable for claim count modelling.

## Main Methods Used

* Insurance data ethics and regulatory discussion
* Data cleaning and summary statistics
* Outlier detection using percentiles
* Removal of negative claim values
* Box–Cox transformation
* Mean loss comparison by gender
* Age band construction
* Correlation analysis
* Principal Component Analysis
* Principal-component regression
* New policy claim cost prediction
* Min-max scaling
* Neural-network embeddings for categorical variables
* Poisson neural network for claim frequency
* Poisson deviance loss
* Model assessment using training and testing loss

## Software

The project is implemented in R. The main packages used include:

* `tidyverse`
* `readxl`
* `ggplot2`
* `dplyr`
* `magrittr`
* `MASS`
* `keras3`
* `reticulate`

A random seed is set in the R code to improve reproducibility.

## Main Learning Outcomes

This project shows how insurance datasets can be analysed using both traditional actuarial modelling techniques and modern machine-learning methods. It highlights the importance of careful data preparation, model interpretability and responsible algorithmic use.

The project also demonstrates that advanced modelling methods, such as neural networks, should be used alongside ethical principles and actuarial judgement. In insurance, predictive performance is important, but models should also remain transparent, fair and suitable for practical decision-making.
