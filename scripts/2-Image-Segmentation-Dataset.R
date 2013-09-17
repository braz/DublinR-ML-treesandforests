# File-Name:				2-Image-Segmentation-Dataset.R
# Date:						2013-09-17
# Author:					Eoin Brazil
# Email:					eoin.brazil@gmail.com
# Purpose:					Format and explore the Image Segmentation Dataset for use in ML
# Data Used:				segmentationData from AppliedPredictiveModeling package
# R version Used:			3.0.1 (2013-05-16)
# Packages Used:			
# Output Files:				
# Data Output:			

# Version:					1.0
# Change log:				Initial version

# Copyright (c) 2013, under the Simplified BSD License.  
# For more information on FreeBSD see: http://www.opensource.org/licenses/bsd-license.php
# All rights reserved.                                                         

# For data manipulation and visualization
library(AppliedPredictiveModeling)
library(caret)
library(doMC)
library(pROC)
library(rpart.plot)	# Fancy tree plot
library(rattle) # Nice tree plot from rattle - fancyRpartPlot
library(RColorBrewer)

# Replace this with the number of CPU cores on your machine (cores not CPUs!)
registerDoMC(2)

# Replace the path here with the appropriate one for your machine
myprojectpath = "/Users/eoinbrazil/Desktop/DublinR/TreesAndForests/DublinR-ML-treesandforests/"

# Set the working directory to the current location for the project files
setwd(myprojectpath)

# Replace the path here with the appropriate one for your machine
scriptpath = paste(myprojectpath, "scripts/", sep="")
datapath = paste(myprojectpath, "data/", sep="")
graphpath = paste(myprojectpath, "graphs/", sep="")


# Load Image Segmentation data
data(segmentationData)

# Remove the Cell identification data
segmentationData$Cell <- NULL

# The dataset already has defined training and test subsets, no need to subset
training <- subset(segmentationData, Case == "Train")
testing <- subset(segmentationData, Case == "Test")
# Remove the Case identification data
training$Case <- NULL
testing$Case <- NULL
str(training[,1:6])

# Use three repeats of 10–fold cross–validation to train the tree
# 10-fold CV can be noisy/over-fitted for small to moderate sample sizes but we'll risk it for higher performances
# The CART algorithm uses overall accuracy and the one standard–error rule to prune the tree, however we can also choose the tree complexity based on the largest absolute area under the ROC curve.
cvCtrl <- trainControl(method = "repeatedcv", repeats = 3, summaryFunction = twoClassSummary, classProbs = TRUE)
rpartTune <- train(Class ~ ., data = training, method = "rpart", tuneLength = 30, metric = "ROC", trControl = cvCtrl)

# Plot the
plot(rpartTune, scales = list(x = list(log = 10)))

# Look at the results of the tuned tree based on the testing dataset for predicting new samples
rpartPred <- predict(rpartTune, testing)
confusionMatrix(rpartPred, testing$Class, positive='WS')

# Explore the tuned tree using the class probabilities for different models and an ROC curve for predicting new samples
rpartProbs <- predict(rpartTune, testing, type = "prob")
rpartROC <- roc(testing$Class, rpartProbs[, "PS"], levels = rev(testing$Class))
plot(rpartROC, type = "S", print.thres = .5)

# A single tree can be influenced heavily by minor changes in the data, however ensemble methods can be used to fit and predict several trees then aggregate these results back across the trees. The three types of ensemble methods are bagging, boosting and random forests.

prp(rpartTune$finalModel)				# Will plot the tree
fancyRpartPlot(rpartTune$finalModel)