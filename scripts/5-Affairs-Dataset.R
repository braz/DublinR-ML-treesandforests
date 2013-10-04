# File-Name:				5-Affairs-Dataset.R
# Date:						2013-09-23
# Author:					Eoin Brazil
# Email:					eoin.brazil@gmail.com
# Purpose:					Format and explore the Affairs Dataset for use in ML
# Data Used:				Affairs from AER package
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
library(AER)
library(corrplot)
library(corrgram)
library(caret)
library(randomForest)
library(klaR)
library(pROC)

# Replace the path here with the appropriate one for your machine
myprojectpath = "/Users/eoinbrazil/Desktop/DublinR/TreesAndForests/DublinR-ML-treesandforests/"

# Set the working directory to the current location for the project files
setwd(myprojectpath)

# Replace the path here with the appropriate one for your machine
scriptpath = paste(myprojectpath, "scripts/", sep="")
datapath = paste(myprojectpath, "data/", sep="")
graphpath = paste(myprojectpath, "graphs/", sep="")


# Set the seed so comparisons can be later made between the methods
set.seed(2323)

# Load Affairs data
data(Affairs)

# Explore the first ten records of the dataset to take a peek
head(Affairs)

# Look to get a summary of the dataset for each variable in the dataframe
summary(Affairs)

# Add some additional fields to data to for the correlation analysis
Affairs$male <- mapvalues(Affairs$gender, from = c("female", "male"), to = c(0, 1))
Affairs$male <- as.integer(Affairs$male)
Affairs$male <- sapply(Affairs$male, function(x) x-1)
Affairs$kids <- mapvalues(Affairs$children, from = c("no", "yes"), to = c(0, 1))
Affairs$kids <- as.integer(Affairs$kids)
Affairs$kids <- sapply(Affairs$kids, function(x) x-1)

# Add a field to indicate if there was any affairs
Affairs$hadaffair[Affairs$affairs< 1] <- 'No'
Affairs$hadaffair[Affairs$affairs>=1] <- 'Yes'
Affairs$hadaffair <- as.factor(Affairs$hadaffair)
table(Affairs$hadaffair)

# Check that the fields are only numerical in the data frame
sapply(Affairs[, -c(2,5,12)], is.numeric)

# Explore the data set to identify and then we'll remove any moderately correlated variables (could change the correlation value from 0.65 to .9)
affairs.corr <- cor(Affairs[, -c(2,5,12)])
corrplot(affairs.corr, method = "number", tl.cex = 0.6)
affairs.variables.corr <- findCorrelation(affairs.corr, 0.65)
affairs.variables.corr.names <- colnames(affairs.corr[,affairs.variables.corr])

# The dataset requires defined training and test subsets so let's remove some of the variables that don't see to add to the value and create these
# in processing unwanted we also include the variables quality and color (13,15) as we want to remove these as well
trainIndices = createDataPartition(Affairs$hadaffair, p = 0.8, list = F)

unwanted = colnames(Affairs) %in% c("yearsmarried", "affairs")
affairs.df.train = Affairs[trainIndices, !unwanted] #remove affairs and yearsmarried
affairs.df.test = Affairs[!1:nrow(Affairs) %in% trainIndices, !unwanted]
table(affairs.df.test$hadaffair)

# The preProcess function helps determine values for predicator transforms on the training set and can be applied to this and future sets.
# This is important as nnets and svms can require scaled and/or centered data which this function supports
affairs.df.trainplot = predict(preProcess(affairs.df.train[,-c(1,3,10)], method="range"), affairs.df.train[,-c(1,3,10)])
# The featurePlot highlight 3 variable (alcohol content, volatile acidity and chlorides) that provide separation with regard to the 'good' classification
featurePlot(affairs.df.trainplot, affairs.df.train$good, "box")


cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
rf.opts = data.frame(.mtry=c(2:6))
results.rf = train(hadaffair~., data=affairs.df.train, method="rf", preProcess='range',trControl=cv.opts, tuneGrid=rf.opts, n.tree=1000)
results.rf

# Plot the
plot(results.rf, scales = list(x = list(log = 10)))

# Look at the results of the random forest based on the testing dataset for predicting new samples
rfPred <- predict(results.rf, affairs.df.test[,-10])
confusionMatrix(rfPred, affairs.df.test$hadaffair, positive="Yes")

# Explore the random forest using the class probabilities for different models and an ROC curve for predicting new samples
rfPredProb <- predict(results.rf, affairs.df.test[,-10], type='prob')
rfROC <- roc(affairs.df.test$hadaffair, rfPredProb[, "Yes"], levels = rev(affairs.df.test$hadaffair))
plot(rfROC, type = "S", print.thres = .5)

cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
results.nb = train(hadaffair~., data=affairs.df.train, method="nb", preProcess='range',trControl=cv.opts)
results.nb 

# Plot the
plot(results.nb)

# Look at the results of the naive bayes based on the testing dataset for predicting new samples
nbPred <- predict(results.nb, affairs.df.test[,-10])
confusionMatrix(nbPred, affairs.df.test$hadaffair, positive="Yes")

# Explore the random forest using the class probabilities for different models and an ROC curve for predicting new samples
nbPredProb <- predict(results.nb, affairs.df.test[,-10], type='prob')
nbROC <- roc(affairs.df.test$hadaffair, nbPredProb[, "Yes"], levels = rev(affairs.df.test$hadaffair))
plot(nbROC, type = "S", print.thres = .5)


# 
# 
# Compare the results from the various approaches and plot the results to help determine the better/best classifiers
# 
#
resultValues <- resamples(list(RF = results.rf, NB = results.nb))
summary(resultValues)

splom(resultValues, metric = "Kappa")
parallelplot(resultValues, metric = "Kappa")
dotplot(resultValues, metric = "Kappa")

plot(rfROC, type = "S", print.thres = .5, col="blue", main="ROC for Classifiers")
par(new=TRUE)
plot(nbROC, type = "S", print.thres = .5, col="green")
legend("topleft", inset=.05, title="Classifiers", c("Random Forest","NB"), fill=c("blue","green"), horiz=TRUE)

# 
# Save the classifiers and datasets for future use
# 
save(results.rf, file=(paste(datapath, "affairs_randomforest.RData", sep="")))
save(results.nb, file=(paste(datapath, "affairs_naivebayes.RData", sep="")))
save(affairs.df.train, file=(paste(datapath, "affairs_training.RData", sep="")))
save(affairs.df.test, file=(paste(datapath, "affairs_testing.RData", sep="")))
