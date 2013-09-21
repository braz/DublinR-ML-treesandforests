# File-Name:				4-Marketing-Survey-Dataset.R
# Date:						2013-09-22
# Author:					Eoin Brazil
# Email:					eoin.brazil@gmail.com
# Purpose:					Format and explore the Marketing Survey Dataset for use in ML
# Data Used:				ElemStatLearn - marketing
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
library(arules)
library(arulesViz)
library(ElemStatLearn)
library(car)

# Replace the path here with the appropriate one for your machine
myprojectpath = "/Users/eoinbrazil/Desktop/DublinR/TreesAndForests/DublinR-ML-treesandforests/"

# Set the working directory to the current location for the project files
setwd(myprojectpath)

# Replace the path here with the appropriate one for your machine
scriptpath = paste(myprojectpath, "scripts/", sep="")
datapath = paste(myprojectpath, "data/", sep="")
graphpath = paste(myprojectpath, "graphs/", sep="")

# Load and take a look at the data
data(marketing)
head(marketing)
summary(marketing)

# Change the data to ensure it can be used as only categorical
marketing.income <- recode(marketing$Income,"1='<$10,000'; 2='$10,000 to $14,999'; 3='$15,000 to $19,999'; 4='$20,000 to $24,999'; 5='$25,000 to $29,999'; 6='$30,000 to $39,999'; 7='$40,000 to $49,999'; 8='$50,000 to $74,999'; 9='$75,000+'")
marketing.sex <- recode(marketing$Sex,"1='Male'; 2='Female'")
marketing.martial <- recode(marketing$Martial, "1='Married'; 2='Living together, not married'; 3='Divorced or separated'; 4='Windowed'; 5='Single, never married'; else='Unknown'")
marketing.age <- recode(marketing$Age, "1='14-17'; 2='18-24'; 3='25-34'; 4='35-44'; 5='45-54'; 6='55-64'; 7='65+' ")
marketing.edu <- recode(marketing$Edu, "1='Grade 8 or less'; 2='Grades 9 to 11'; 3='Graduated high school'; 4='1 to 3 years of college'; 5='College graduate'; 6='Postgraduate study'; else='Unknown'")
marketing.occupation <- recode(marketing$Occupation, "1='Professional/Managerial'; 2='Sales Worker'; 3='Factory Worker/Laborer/Driver'; 4='Clerical/Service Worker'; 5='Homemaker'; 6='Student, HS or College'; 7='Military'; 8='Retired'; 9='Unemployed'; else='Unknown'")
marketing.lived <- recode(marketing$Lived, "1='Less than a year'; 2='One to three years'; 3='Four to six years'; 4='Seven to ten years'; 5='More than ten year'; else='Unknown'")
marketing.dualincome <- recode(marketing$Dual_Income, "1='Not married'; 2='Yes'; 3='No'")
marketing.householdsize <- recode(marketing$Household, "1='1'; 2='2'; 3='3'; 4='4'; 5='5'; 6='6'; 7='7'; 8='8'; 9='9'; else='Unknown'")
marketing.householdsizeunder18years <- recode(marketing$Householdu18, "1='1'; 2='2'; 3='3'; 4='4'; 5='5'; 6='6'; 7='7'; 8='8'; 9='9'; else='Unknown'")
marketing.status <- recode(marketing$Status, "1='Own'; 2='Rent'; 3='Live with Parents/Family'; else='Unknown'")
marketing.hometype <- recode(marketing$Home_Type, "1='House'; 2='Condominium'; 3='Apartment'; 4='Mobile Home'; 5='Other'; else='Unknown'")
marketing.ethnic <- recode(marketing$Ethnic, "1='American Indian'; 2='Asian'; 3='Black'; 4='East Indian'; 5='Hispanic'; 6='Pacific Islander'; 7='White'; 8='Other'; else='Unknown'")
marketing.language <- recode(marketing$Language, "1='English'; 2='Spanish'; 3='Other'; else='Unknown'")

# Create a new dataframe and removed the earlier variables to clean up space
marketing.df <- data.frame(marketing.income, marketing.sex, marketing.martial, marketing.age, marketing.edu, marketing.occupation, marketing.lived, marketing.dualincome, marketing.householdsize, marketing.householdsizeunder18years, marketing.status, marketing.hometype, marketing.ethnic, marketing.language)
rm(marketing.income, marketing.sex, marketing.martial, marketing.age, marketing.edu, marketing.occupation, marketing.lived, marketing.dualincome, marketing.householdsize, marketing.householdsizeunder18years, marketing.status, marketing.hometype, marketing.ethnic, marketing.language)

# Transform the data frame to a transactions object
marketing.transactions <- as(marketing.df, "transactions")
# Run the apriori algorithm on the data
marketing.rules <- apriori(marketing.transactions, parameter = list(support=0.05, confidence=0.95))
summary(marketing.rules)

# Investigate the rules with the highest life
subset(marketing.rules, subset=lift>2.5)
inspect(subset(marketing.rules, subset=lift>2.5)[1:5])
plot(marketing.rules)
head(quality(marketing.rules))
plot(marketing.rules, method="grouped", control=list(k=50))

# Visually explore the 10 rules that return the best lift
marketing.subrules <- head(sort(marketing.rules, by="lift"),10)
plot(marketing.subrules, method="matrix", measure=c("lift","confidence") , control=list(reorder=TRUE))
plot(marketing.subrules, method="paracoord", control=list(reorder=TRUE))
