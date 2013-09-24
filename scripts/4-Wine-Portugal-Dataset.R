# File-Name:				4-Wine-Portugal-Dataset.R
# Date:						2013-09-18
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

# Set the seed so comparisons can be later made between the method
set.seed(2323)

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

# Explore the data set to identify and then we'll remove any moderately correlated variables (could change the correlation value from 0.65 to .9)
wine.corr <- cor(wine.df[, -c(13, 15)])
wine.variables.corr <- findCorrelation(wine.corr, 0.65)
wine.variables.corr.names <- colnames(wine.corr[,wine.variables.corr])

# The dataset requires defined training and test subsets so let's remove some of the variables that don't see to add to the value and create these
# in processing unwanted we also include the variables quality and color (13,15) as we want to remove these as well
trainIndices = createDataPartition(wine.df$good, p = 0.8, list = F)
unwanted = colnames(wine.df) %in% c("free.sulfur.dioxide", "density", "quality",
"color", "white")
wine.df.train = wine.df[trainIndices, !unwanted] #remove quality and color, as well as density and others
wine.df.test = wine.df[!1:nrow(wine.df) %in% trainIndices, !unwanted]

# The preProcess function helps determine values for predicator transforms on the training set and can be applied to this and future sets.
# This is important as nnets and svms can require scaled and/or centered data which this function supports
wine.df.trainplot = predict(preProcess(wine.df.train[,-10], method="range"), wine.df.train[,-10])
# The featurePlot highlight 3 variable (alcohol content, volatile acidity and chlorides) that provide separation with regard to the 'good' classification
featurePlot(wine.df.trainplot, wine.df.train$good, "box")

# There are a number of method's that can be supplied to preProcess - scale, PCA, center, spatialSign as well as range
wine.df.trainplot.2 =predict(preProcess(wine.df.train[,-10], method="scale"), wine.df.train[,-10])
featurePlot(wine.df.trainplot.2, wine.df.train$good, "box")

cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
rf.opts = data.frame(.mtry=c(2:6))
results.rf = train(good~., data=wine.df.train, method="rf", preProcess='range',trControl=cv.opts, tuneGrid=rf.opts, n.tree=1000)
results.rf

# Plot the
plot(results.rf, scales = list(x = list(log = 10)))

# Look at the results of the random forest based on the testing dataset for predicting new samples
rfPred <- predict(results.rf, wine.df.test[,-10])
confusionMatrix(rfPred, wine.df.test$good, positive='Good')

# Explore the random forest using the class probabilities for different models and an ROC curve for predicting new samples
rfPredProb <- predict(results.rf, wine.df.test[,-10], type='prob')
rfROC <- roc(wine.df.test$good, rfPredProb[, "Good"], levels = rev(wine.df.test$good))
plot(rfROC, type = "S", print.thres = .5)

# 
# 
# Explore the dataset using a K-nn approach
# 
#
cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
knn.opts = data.frame(.k=c(seq(3, 11, 2), 25, 51, 101)) #odd to avoid ties
results.knn = train(good~., data=wine.df.train, method="knn", preProcess="range", trControl=cv.opts, tuneGrid = knn.opts)

# Plot the
plot(results.knn)
results.knn

# Look at the results of the knn based on the testing dataset for predicting new samples
knnPred <- predict(results.knn, wine.df.test[,-10])
confusionMatrix(knnPred, wine.df.test$good, positive='Good')

# Explore the knn using the class probabilities for different models and an ROC curve for predicting new samples
knnPredProb <- predict(results.knn, wine.df.test[,-10], type='prob')
knnROC <- roc(wine.df.test$good, knnPredProb[, "Good"], levels = rev(wine.df.test$good))
plot(knnROC, type = "S", print.thres = .5)

# 
# 
# Explore the dataset using a neural net approach
# 
#
cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
# If you have setup for multiple process, you can increase the tuneLength parameter to 5 to improve the accuracy
results.nnet = train(good~., data=wine.df.train, method="avNNet", trControl=cv.opts, preProcess="range", tuneLength=3, trace=F, maxit=1000)

# Plot the
plot(results.nnet)
results.nnet

# Look at the results of the nnet based on the testing dataset for predicting new samples
nnetPred <- predict(results.nnet, wine.df.test[,-10])
confusionMatrix(nnetPred, wine.df.test$good, positive='Good')

# Explore the nnet using the class probabilities for different models and an ROC curve for predicting new samples
nnetPredProb <- predict(results.nnet, wine.df.test[,-10], type='prob')
nnetROC <- roc(wine.df.test$good, nnetPredProb[, "Good"], levels = rev(wine.df.test$good))
plot(nnetROC, type = "S", print.thres = .5)


# 
# 
# Explore the dataset using a svm approach
# 
#

cv.opts = trainControl(method="cv", number=10, classProbs = TRUE)
# If you have setup for multiple process, you can increase the tuneLength parameter to 5 to improve the accuracy
results.svm = train(good~., data=wine.df.train, method="svmLinear", preProcess="range", trControl=cv.opts, tuneLength=5)

# Plot the
plot(results.svm)
results.svm

# Look at the results of the svm based on the testing dataset for predicting new samples
svmPred <- predict(results.svm, wine.df.test[,-10])
confusionMatrix(svmPred, wine.df.test$good, positive='Good')

# Explore the svm using the class probabilities for different models and an ROC curve for predicting new samples
svmPredProb <- predict(results.svm, wine.df.test[,-10], type='prob')
svmROC <- roc(wine.df.test$good, svmPredProb[, "Good"], levels = rev(wine.df.test$good))
plot(svmROC, type = "S", print.thres = .5)

# 
# 
# Compare the results from the various approaches and plot the results to help determine the better/best classifiers
# 
#
resultValues <- resamples(list(RF = results.rf, KNN = results.knn, NNET= results.nnet, SVM = results.svm))
summary(resultValues)

splom(resultValues, metric = "Accuracy")
parallelplot(resultValues, metric = "Accuracy")
dotplot(resultValues, metric = "Accuracy")

accrDiffs <- diff(resultValues, metric = "Accuracy")
dotplot(accrDiffs, metric = "Accuracy")

plot(rfROC, type = "S", print.thres = .5, col="red", main="ROC for Classifiers")
par(new=TRUE)
plot(knnROC, type = "S", print.thres = .5, col="blue")
par(new=TRUE)
plot(nnetROC, type = "S", print.thres = .5, col="green")
par(new=TRUE)
plot(svmROC, type = "S", print.thres = .5, col="purple")
legend("bottomright", inset=.05, title="Classifiers", c("Random Forest","kNN","Neural Net","SVM"), fill=c("red","blue","green","purple"), horiz=TRUE)

# 
# 
# Save the randomForst (best in this case) model to use for deployment
# 
#
save(results.rf, file=(paste(datapath, "goodwine_randomforest.RData", sep="")))
save(wine.df.train, file=(paste(datapath, "goodwine_training.RData", sep="")))
save(wine.df.test, file=(paste(datapath, "goodwine_testing.RData", sep="")))
