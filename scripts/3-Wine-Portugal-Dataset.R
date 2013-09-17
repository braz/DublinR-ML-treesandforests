# File-Name:				3-Wine-Portugal-Dataset.R
# Date:						2013-09-17
# Author:					Eoin Brazil
# Email:					eoin.brazil@gmail.com
# Purpose:					Format and explore the Wine Dataset for use in ML
# Data Used:				goodwine.csv
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
library(corrplot)
library(caret)
library(randomForest)
library(rpart.plot)	# Fancy tree plot
library(rattle) # Nice tree plot from rattle - fancyRpartPlot
library(RColorBrewer)
library(pROC)
library(corrgram)

# Replace the path here with the appropriate one for your machine
myprojectpath = "/Users/eoinbrazil/Desktop/DublinR/TreesAndForests/DublinR-ML-treesandforests/"

# Set the working directory to the current location for the project files
setwd(myprojectpath)

# Replace the path here with the appropriate one for your machine
scriptpath = paste(myprojectpath, "scripts/", sep="")
datapath = paste(myprojectpath, "data/", sep="")
graphpath = paste(myprojectpath, "graphs/", sep="")

# Load wine dataset into a dataframe for processing
wine.df = read.csv(paste(datapath, "goodwine.csv", sep=""))

# Explore the first ten records of the dataset to take a peek
head(wine.df)

# Look to get a summary of the dataset for each variable in the dataframe
summary(wine.df)
# Plot the correlation excluding color and goodness variable to see if any variables are largely captured by other variables
# Looks like density, suggested color and either sulfur dioxide are largely captured by the other variables.
corrplot(cor(wine.df[, -c(13, 15)]), method = "number", tl.cex = 0.5)
# We can also use corrgram package
corrgram(cor(wine.df[, -c(13, 15)]),  order=NULL, lower.panel=panel.shade, upper.panel=NULL, text.panel=panel.txt, main="Wine Data (unsorted)")

# The dataset requires defined training and test subsets so let's remove some of the variables that don't see to add to the value and create these
trainIndices = createDataPartition(wine.df$good, p = 0.8, list = F)
unwanted = colnames(wine.df) %in% c("free.sulfur.dioxide", "density", "quality",
"color", "white")
wine.df.train = wine.df[trainIndices, !unwanted] #remove quality and color, as well as density and others
wine.df.test = wine.df[!1:nrow(wine.df) %in% trainIndices, !unwanted]

wine.df.trainplot = predict(preProcess(wine.df.train[,-10], method="range"), wine.df.train[,-10])
# The featurePlot highlight 3 variable (alcohol content, volatile acidity and chlorides) that provide separation with regard to the 'good' classification
featurePlot(wine.df.trainplot, wine.df.train$good, "box")

cv.opts = trainControl(method="cv", number=10)
rf.opts = data.frame(.mtry=c(2:6))
results.rf = train(good~., data=wine.df.train, method="rf", preProcess='range',trControl=cv.opts, tuneGrid=rf.opts, n.tree=1000)
results_rf

# Plot the
plot(results.rf, scales = list(x = list(log = 10)))

# Look at the results of the random forest based on the testing dataset for predicting new samples
rfPred <- predict(results.rf, wine.df.test[,-10])
confusionMatrix(rfPred, wine.df.test$good, positive='Good')

# Explore the random forest using the class probabilities for different models and an ROC curve for predicting new samples
rfPredProb <- predict(results.rf, wine.df.test[,-10], type='prob')
rfROC <- roc(wine.df.test$good, rfPredProb[, "Good"], levels = rev(wine.df.test$good))
plot(rfROC, type = "S", print.thres = .5)
