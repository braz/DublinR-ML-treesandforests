# File-Name:				1-Car-Dataset.R
# Date:						2013-09-17
# Author:					Eoin Brazil
# Email:					eoin.brazil@gmail.com
# Purpose:					Format and explore the Car Dataset for use in ML
# Data Used:				car.csv
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
library(party)
library(rpart)
library(caret)

# Replace the path here with the appropriate one for your machine
myprojectpath = "/Users/eoinbrazil/Desktop/DublinR/TreesAndForests/DublinR-ML-treesandforests/"

# Set the working directory to the current location for the project files
setwd(myprojectpath)

# Replace the path here with the appropriate one for your machine
scriptpath = paste(myprojectpath, "scripts/", sep="")
datapath = paste(myprojectpath, "data/", sep="")
graphpath = paste(myprojectpath, "graphs/", sep="")

# Load the Car dataset into a dataframe for processing
car.df = read.csv(paste(datapath, "car.csv", sep=""))

# Explore the first ten records of the dataset to take a peek
head(car.df)

# Look to get a summary of the dataset for each variable in the dataframe
summary(car.df)

# The key variable we are interested in deteriming is claim or 'clm' with 0 = no claim and 1 = a claim
# Determine what the other variables are from the carDataSetDescription.txt file to see which are potential predictors

predictors.to.clm.var = clm ~ veh_value + veh_body + veh_age + gender + area + agecat

# A quick single tree using the full dataset to see what are the potential splits
SingleTree = ctree(predictors.to.clm.var, data = car.df)
plot(SingleTree, type="simple")

# Partitioning the data set into training and testing sets
inTrainIndexes <- createDataPartition(y = car.df$clm, p=.8, list = FALSE)
car.df.train = car.df[inTrainIndexes,]
car.df.test = car.df[-inTrainIndexes,]

ClaimModel.ctree <- ctree(predictors.to.clm.var, data=car.df.train)
plot(ClaimModel.ctree, type="simple")
summary(ClaimModel.ctree)