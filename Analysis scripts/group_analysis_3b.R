# Analysis script for Study 3b

# Working directory should automatically be set to file location, if not: Specify using setwd()

# Load libraries
library('tcltk')
library('survival')
library('lattice')
library('ggplot2')
library('psych')
library('jtools')
source('wtwFxs.R')
library('matrixStats')
library('beeswarm')
library("jtools")
library("lme4")
library("lsr")
library("BayesFactor")
library("here")

# Set data directory
dataDir <- "../study 3b/data"
setwd(dataDir)

# select and load all data files
file.names <- list.files(pattern = "*_data.csv")

# will load all data files in a list named "df,list"- each file can be accessed using df.list[[d]]
df.list <- lapply(file.names, function(file.name)
{
  df           <- read.csv(file.name)
  df$file.name <- file.name
  return(df)
})

length(df.list) # number of participants in the list

# check the loaded data files and save out a summary
# data_summary: Should have basic information on each participant, such as
  # ID, date of participation, condition, number of trials, duration, and a check for the inclusion criteria
IDs <- c()
numTrials <- c()
timingCond <- c()
lastSellTime <- c() # last token sold in the block
earnings <- c()
date <- c()
manipulation <- c()
medianRT <- c()
RTSumAboveOne <- c()
maxSchedueldDelay <- c()
medianRTCheck <- c()
RTSumAboveOneCheck <- c()
lastSellTimeCheck <- c()
file_name <- c()

for (d in 1:length(df.list)){
  
  data <- df.list[[d]]
  
  IDs <- c(IDs, data$subject_id[1])
  numTrials <- c(numTrials, as.numeric(max(data$n_trialIdx)))
  timingCond <- c(timingCond, data$f_timing_condition[1])
  lastSellTime <- c(lastSellTime, max(data$n_sell_time))
  earnings <- c(earnings, max(data$n_total_earnings))
  manipulation <- c(manipulation, data$condition[1])
  date <- c(date, substr(data$file_name[1], start = 42, stop = 51))
  file_name <- c(file_name, data$file_name[1])
  medianRT <- c(medianRT, median( data$RT, na.rm = T))
  maxSchedueldDelay <- c(maxSchedueldDelay, max(data$n_scheduled_delay))
  
  # Prepare for check of exclusion criteria
  ### Participants will be excluded if they fail to complete the entire WTW task.
  if (lastSellTime[d] <= 900 - 60){
    lastSellTimeCheck <- c(lastSellTimeCheck, 0)
    print("Warning: This participant did not complete the whole task.")
  } else if (lastSellTime[d] > 900 - 60){
    lastSellTimeCheck <- c(lastSellTimeCheck, 1)
  }
  
  ### Participants will be excluded if they were too slow to sell tokens that had matured and delivered rewards. We will calculate the per-session median response time (RT) to sell rewarded tokens (combining both task blocks in the session). The participant’s WTW task data will be excluded if the median RT exceeds a threshold of 1.25 s
  
  if (medianRT[d] >= 1.25){
    medianRTCheck <- c(medianRTCheck, 0)
    print("Warning: This participants median RT is equal to or higher than 1.25.")
  } else if (medianRT[d] < 1.25){
    medianRTCheck <- c(medianRTCheck, 1)
  }
  
  ### Participants will be excluded on the basis of a cumulative measure of “off-task time” per block. Off-task time will include time in excess of 1 s on a given trial between the delivery of a reward (a matured token) and the participant’s “sell” response to collect the reward. For example, selling a rewarded token with an RT of 2 s would add 1 s to the block’s off-task time, and selling a rewarded token with an RT of 500 ms would have no effect on the block’s off-task time. A participant’s WTW task data will be excluded if they accumulate 180 s or more of off-task time during the 15-minute block (more than 20% off-task time). 
  # investigate all RTs that are longer than 1 second
  idx <- which(data$RT > 1)
  
  if (length(idx) == 0){
    RTSumAboveOneValue <- 0
    RTSumAboveOne <- c(RTSumAboveOne, RTSumAboveOneValue)
  }  else {
    exceeded_1s <- data$RT[idx] - 1
    RTSumAboveOneValue <- sum(exceeded_1s)
    
    if (as.numeric(RTSumAboveOneValue) >= 180){
      RTSumAboveOne <- c(RTSumAboveOne, RTSumAboveOneValue)
    } else {
      RTSumAboveOne <- c(RTSumAboveOne, RTSumAboveOneValue)
    }
  }
  
  if (RTSumAboveOne[d] >= 180){
    RTSumAboveOneCheck <- c(RTSumAboveOneCheck, 0)
    print("Warning: This participant spend more than 180s off-task.")
  } else if (RTSumAboveOne[d] < 180){
    RTSumAboveOneCheck <- c(RTSumAboveOneCheck, 1)
  }
  
  # add quit index to each data set, 1 refers to a quit
  df.list[[d]]$idxQuit <- rep(0, nrow(df.list[[d]]))
  df.list[[d]]$idxQuit[which(is.na(df.list[[d]]$n_rewarded_time))] <- 1

}

dataSummary <- as.data.frame(cbind(IDs, date, file_name, numTrials, earnings, timingCond, manipulation, maxSchedueldDelay, lastSellTime, lastSellTimeCheck, medianRT, medianRTCheck, RTSumAboveOne, RTSumAboveOneCheck))
  
# turn df.list into a data file - easier for processing below
large_df <- do.call(rbind.data.frame, df.list)

# explore exclusion criteria
exclusion_data <- as.data.frame(cbind(dataSummary$IDs, dataSummary$lastSellTime, dataSummary$lastSellTimeCheck, dataSummary$medianRT, dataSummary$medianRTCheck, dataSummary$RTSumAboveOne, dataSummary$RTSumAboveOneCheck))

colnames(exclusion_data) <- c("IDs", "lastSellTimeC", "lastSellTimeCheck", "medianRT", "medianRTCheck", "RTSumAboveOne", "RTSumAboveOneCheck")
exclusion_data$lastSellTimeCheck <- as.numeric(exclusion_data$lastSellTimeCheck)
exclusion_data$medianRTCheck <- as.numeric(exclusion_data$medianRTCheck)
exclusion_data$RTSumAboveOneCheck <- as.numeric(exclusion_data$RTSumAboveOneCheck)

sum(exclusion_data$lastSellTimeCheck)
sum(exclusion_data$medianRTCheck)
sum(exclusion_data$RTSumAboveOneCheck)

# Exclude using criteria
exclusion_data <- subset (exclusion_data,
                            exclusion_data$RTSumAboveOneCheck == 1 &
                            exclusion_data$medianRTCheck == 1 & 
                            exclusion_data$lastSellTimeCheck == 1)

# Exclude the two last participants that were collected in discrete (please find further information at the end of this script)
exclusion_data <- subset (exclusion_data, exclusion_data$IDs != "R_2WBau1gIw3CxKHC" & exclusion_data$IDs != "R_3EWM6hxYK9WZmCf")

# number of included data sets
nrow(exclusion_data)

# preliminary stuff
allIDs = exclusion_data$IDs # included IDs
n = length(allIDs)

# remove excluded participants from data files
dataSummary <- droplevels(dataSummary[dataSummary$ID %in% allIDs, ])
large_df <- droplevels(large_df[large_df$subject_id %in% allIDs, ])

# Preliminary data visualization
# distribution of scheduled delays in each block (ECDF) 
# distribution of scheduled delays in each block (autocorrelation plot)
# reaction times 
# trial-by-trial data

# Set figure directory
figDir <- "../output"
setwd(figDir)
study <- "3b"

# plot the distribution of scheduled delays in each block (ECDF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysECDF.pdf', n)) # adjust ECDF
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  scheduledDelaysECDF(blockData, study, id, dataSummary) 
}
dev.off()

# plot the distribution of scheduled delays in each block (ACF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysACF.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  scheduledDelaysACF(blockData, study, id, dataSummary) 
}
dev.off()

# reaction time plot
figName = file.path(sprintf('indivs_n%d_RT.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  outcomeRT(blockData, study, id, dataSummary)
}
dev.off()

# plot trial-by-trial data
figName = file.path(sprintf('indivs_n%d_trialPlots.pdf', n))
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  trialPlots(blockData, study, id, dataSummary)
}
dev.off()

# survival curve and AUC
grpAUC = data.frame(rownames=dataSummary$ID, IDs=dataSummary$ID, AUC=numeric(n), 
                    row.names='rownames', stringsAsFactors=FALSE) # initialize group results
scGrid = seq(0, 20, by=0.1)
grpSurvCurves = matrix(nrow=n, ncol=length(scGrid), dimnames=list(dataSummary$ID, scGrid)) # initialize
figName = file.path(figDir, sprintf('indivs_n%d_survivalCurves.pdf', n))
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  
  # calculate kaplan-meier survival curve and area under the curve
  output <- kmsc(blockData, study, id, dataSummary, scGrid) 
  
  grpAUC$AUC[which(grpAUC$IDs == id)] = output$auc 
  grpSurvCurves[id, ] = output$kmOnGrid
}
dev.off()

# save group AUC results
outFileName = file.path(figDir, sprintf('grp_n%d_groupAUC.csv', n))
write.csv(grpAUC, file=outFileName, row.names=FALSE)

# AUC analyses as reported in the paper
AUCResults <- merge(grpAUC, dataSummary, by.x = "IDs")

#### To exclude participants with AUC smaller than 2.16, use the following few lines
# AUCResults$smaller216 <- rep(0, nrow(AUCResults))
# AUCResults$smaller216[which(AUCResults$AUC < 2.16)] <- 1
# dataSummary$smaller216 <- AUCResults$smaller216
# dataSummary$AUC <- AUCResults$AUC
# AUCResults$check <- AUCResults$AUC
# AUCResults <- subset(AUCResults, AUCResults$smaller216 == 0)

table(AUCResults$manipulation) # 80 participants per group 
describeBy(AUCResults$AUC, AUCResults$manipulation) # descriptive information 

AUCResultsStandard <- subset(AUCResults, AUCResults$manipulation == "standard")
AUCResultsDiscrete <- subset(AUCResults, AUCResults$manipulation == "discrete")

# Find the confidence interval (set to 95%) using bootstrapping
CIstandardBoot <- calcCIBoot(AUCResultsStandard$AUC)
CIdiscreteBoot <- calcCIBoot(AUCResultsDiscrete$AUC)

# T-test and Bayes factor
ttest <- t.test(AUCResults$AUC ~ AUCResults$manipulation)
difinAUC <- cohensD(mean(AUCResultsStandard$AUC, na.rm = FALSE),
                      mean(AUCResultsDiscrete$AUC, na.rm = FALSE), 
                      sd(AUCResultsStandard$AUC, na.rm = FALSE), 
                      sd(AUCResultsDiscrete$AUC, na.rm = FALSE), 
                      80, 
                      80)

jsq::bttestIS(formula = AUC ~ manipulation, data = AUCResults, hypothesis = "twoGreater", desc = TRUE)

# compare behavior to optimal behavior (selling just after 2.16)
t.test(AUCResultsStandard$AUC, mu = 2.16)
t.test(AUCResultsDiscrete$AUC, mu = 2.16)

cohdeviation_standard <- (mean(AUCResultsStandard$AUC, na.rm = FALSE) - 2.16) / sd(AUCResultsStandard$AUC, na.rm = FALSE) 
cohdeviation_discrete <- (mean(AUCResultsDiscrete$AUC, na.rm = FALSE) - 2.16) / sd(AUCResultsDiscrete$AUC, na.rm = FALSE) 

# Mean survival curves by condition 
# set up colors for group plots
colLPStandard <- rgb(225, 0, 0, max = 255, alpha = 125)
colLPDiscrete <- rgb(255,105,180, max = 255, alpha = 125)
colLPStandard_transp = rgb(225, 0, 0, max = 255, alpha = 70)
colLPDiscrete_transp <- rgb(255,105,180, max = 255, alpha = 50)
colGray = rgb(1/3, 1/3, 1/3)

# Output figure: between-subjects effect in Block 1
# Block 1 group mean survival curves
figName = file.path(figDir, sprintf('n%d_survivalByCondition.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# Save as tiff for paper
# figName = file.path(sprintf('n%d_survivalByCondition.tiff', n))
# tiff(figName, units="in", width=5, height=5, res=300)

standard_ids <- AUCResults$IDs[which(AUCResults$manipulation == "standard")]
discrete_ids <- AUCResults$IDs[which(AUCResults$manipulation == "discrete")]

# plot group mean survival curves for block 1 (w/ SEM)
survCurve_grpMean_LPStandard = colMeans2(grpSurvCurves[standard_ids, ])
survCurve_grpSEM_LPStandard = colSds(grpSurvCurves[standard_ids, ])/sqrt(length(standard_ids))
survCurve_grpMean_LPDiscrete = colMeans2(grpSurvCurves[discrete_ids, ])
survCurve_grpSEM_LPDiscrete = colSds(grpSurvCurves[discrete_ids, ])/sqrt(length(discrete_ids))

plot('', bty='n', xlab='Elapsed time in trial (s)', xlim=c(0,20), xaxp=c(0, 20, 4),
     ylab='Survival rate', ylim=c(0,1), yaxp=c(0, 1, 2),
     main='Survival curves by condition', las=1, xaxt='n')
axis(side = 1, at=seq(0,20, 10), las=1)

errorBand(xData=scGrid, yData=survCurve_grpMean_LPStandard, yErr=survCurve_grpSEM_LPStandard, bandColor=colLPStandard_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_LPDiscrete, yErr=survCurve_grpSEM_LPDiscrete, bandColor=colLPDiscrete_transp)
lines(scGrid, survCurve_grpMean_LPStandard, type='l', lwd=3, col=colLPStandard)
lines(scGrid, survCurve_grpMean_LPDiscrete, type='l', lwd=3, col=colLPDiscrete)

# add a legend
legend('topright', 
       legend=c('LP standard', 'LP instructed'),
       col=c(colLPStandard, colLPDiscrete), bty='n', lwd=c(2, 2))

# end figure
dev.off()

# Block 1 group AUC
figName = file.path(figDir, sprintf('n%d_survivalBybeeswarm.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# beeswarm+box plot of group AUC results - between-subject effect for block 1
AUCList = list(
  standard = AUCResults$AUC[which(AUCResults$manipulation == "standard")],
  discrete = AUCResults$AUC[which(AUCResults$manipulation == "discrete")])
boxplot(AUCList, outline=FALSE, boxwex=0.5, col=c(colLPStandard_transp, colLPDiscrete_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(0,20), yaxp=c(0, 20, 4), ylab='AUC (s)',
        main='AUC')
beeswarm(AUCList, pch=20, col=c(colLPStandard, colLPDiscrete), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

# end figure
dev.off()

# WTW time series, across both conditions
tGrid = 1:900
wtwCeiling=20 # for comparability across studies/conditions
wtwTS_results = matrix(data=NA, nrow=n, ncol=length(tGrid), dimnames=list(allIDs))
wtwTS_slope = data.frame(ID=allIDs, Block1=rep(NA,n), LP=rep(NA,n), 
                         row.names=allIDs, stringsAsFactors=FALSE)


for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$subject_id == id)
  # calculate willingness to wait time-series
  wtwTS_results[id, ] <- wtwTS(blockData, tGrid, wtwCeiling)
}

# plot the mean WTW function by counterbalance group
tValues = list(1:900)
# obtain mean and SEM for each counterbalance group
wtwTS_grpMean = list()
wtwTS_grpSEM = list()

for (this_cbal in c('LPStandard', 'LPDiscrete')) {
  if (this_cbal == "LPStandard"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[standard_ids, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[standard_ids, ])/sqrt(length(standard_ids))  
  }
  if (this_cbal == "LPDiscrete"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[discrete_ids, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[discrete_ids, ])/sqrt(length(discrete_ids))  
  }
}

figName = file.path(figDir, sprintf('n%d_wtwByCondition.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)

# figName = file.path(sprintf('n%d_wtwByConditionLP.tiff', n))
# tiff(figName, units="in", width=10, height=5, res=300)

# initialize the plot
plot('', type='n', xlim=c(0, 900), bty='n', ylim=c(0, 20), yaxp=c(0, 20, 4),
     xlab='Time elapsed in block (min)', ylab='WTW (s)',
     main='Local willingness-to-wait estimates', yaxt='n', xaxt='n')
axis(side = 2, at=seq(0,30, 10), las=1)
axis(side = 1, at=seq(0, 960, 120), las=1, labels = seq(0, 16, 2))

# add error bands, one block at a time
errorBand(xData=1:900, yData=wtwTS_grpMean$LPStandard, 
          yErr=wtwTS_grpSEM$LPStandard, bandColor=colLPStandard_transp)
errorBand(xData=1:900, yData=wtwTS_grpMean$LPDiscrete, 
          yErr=wtwTS_grpSEM$LPDiscrete, bandColor=colLPDiscrete_transp)

# add means
lines(1:900, wtwTS_grpMean$LPStandard, col=colLPStandard, type='l', lwd=2, lty='solid')
lines(1:900, wtwTS_grpMean$LPDiscrete, col=colLPDiscrete, type='l', lwd=2, lty='solid')

# add a legend
legend('topright', 
       legend=c('LP standard', 'LP instructed'),
       col=c(colLPStandard, colLPDiscrete), bty='n', lwd=c(2, 2))
dev.off()

# regression model predicting WTW per second by seconds elapsed for each individual, then compare coefficients using a t-test
dataSummary$wtw_trend <- rep(NA, nrow(dataSummary))

for (id in dataSummary$ID) {
  
  data <-  subset(large_df, large_df$subject_id == id)
  
  wtwTS_vector <- wtwTS_results[id, ]
  dat <- as.data.frame(cbind(1:900, wtwTS_vector))
  colnames(dat) <- c("second", "wtw") 
  
  model <- lm(wtw ~ second, data = dat) 
  
  dataSummary$wtw_trend[which(dataSummary$IDs == id)] <- as.numeric(model$coefficients[2])
}

figName = file.path(figDir, sprintf('indivs_n%d_coefficients.pdf', n)) 
pdf(figName, pointsize=14)

coefficientsList = list(
  standard = dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")],
  discrete = dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")])
boxplot(coefficientsList, outline=FALSE, boxwex=0.5, col=c(colLPStandard_transp, colLPDiscrete_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(-0.05,0.05), ylab='Coefficient',
        main='Coefficient: wtw-trend')
abline(h = 0, lty = 2)
beeswarm(coefficientsList, pch=16, col=c(colLPStandard, colLPDiscrete), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

dev.off()

# to exclude participants with AUCs under 2.16
# dataSummary <- subset(dataSummary, dataSummary$smaller216 == 0)

describeBy(dataSummary$wtw_trend, dataSummary$manipulation)

# means
mean(dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")])
mean(dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")])

# Bootstrap confidence interval for LP
CIstandardLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")])
CIdiscreteLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")])

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")], dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")])
difintrendLP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")], na.rm = FALSE),
                        mean(dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$manipulation == "standard")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$manipulation == "discrete")], na.rm = FALSE), 
                        80, 
                        80)

jsq::bttestIS(formula = wtw_trend ~ manipulation, data = dataSummary, hypothesis = "twoGreater", desc = TRUE)
# LP discrete is less than LP standard


#### Exclusion of two extra participants
# I recruited 80 eligible participant for the standard condition but 82 for the discrete condition, so I should remove the
# two last collected data sets in the discrete condition

# dataSummary_incl_discr_12_24 <- subset (dataSummary_incl, dataSummary_incl$date == "2022-12-24" & dataSummary_incl$manipulation == "discrete")
#dataSummary_incl_discr_12_24$IDs # ids of the last 10 discrete participants recruited on 2022-12-24
# check file name of these to see which two participants were recruited last
# these should be removed (I do that above in this case): 
# wtw-lempert-cb_R_2WBau1gIw3CxKHC_SESSION_2022-12-24_15h24.16.664.csv
# wtw-lempert-cb_R_3EWM6hxYK9WZmCf_SESSION_2022-12-24_05h07.48.256.csv

