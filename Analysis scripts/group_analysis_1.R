# Analysis script for Study 1

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
library("jsq")
library("boot")

# Set data directory
dataDir <- "../study 1/data"
setwd(dataDir)

# Higher level information per participant
headerInfo <- read.csv("headerFileinfo.csv")

# Trial data
trialData <- read.csv("infoData.csv")

# check the loaded data file and save out a summary
# data_summary: Should have basic information on each participant, such as
# ID, date of participation, condition, number of trials, duration, and a check for the inclusion criteria
IDs <- c()
numTrials <- c()
timingCond <- c()
earnings <- c()
date <- c()
medianRT <- c()
file_name <- c()
maxScheduledDelay <- c()
cbalAsFactor <- c()

large_df <- c()

for (d in unique(trialData$ID)){
  
  data <- subset(trialData, trialData$ID == d)
  header <- headerInfo[which(headerInfo$id == d), ]
  
  IDs <- c(IDs, d)
  numTrials <- c(numTrials, max(as.numeric(data$trialNum)))
  
  # Information on manipulation
  if(as.numeric(header$cbal) == 1){
    manipu <- "noInfo"
    cbalAsFactor <- c(cbalAsFactor, "noInfo")
  } else if (as.numeric(header$cbal) == 2){
    manipu <- "Info"
    cbalAsFactor <- c(cbalAsFactor, "Info")
  } 
  
  timingCond <- c(timingCond, "LP")
  earnings <- c(earnings, max(as.numeric(data$totalEarned)))
  file_name <- c(file_name, as.character(header$dfname))

  # add quit index to each data set
  data$idxQuit <- rep(0, nrow(data))
  data$idxQuit[which(is.na(data$rwdOnsetTime))] <- 1
  
  # add RT
  data$RT <- as.numeric(data$latency) - as.numeric(data$rwdOnsetTime)  
  
  # Add to a large data file
  large_df <- rbind(large_df, data)
}

dataSummary <- as.data.frame(cbind(IDs, file_name, numTrials, earnings, timingCond, cbalAsFactor))

# all data files should be included: 
included_ids <- read.csv("included_IDs.csv")

# Make sure that subject ids are in capital letters
allIDs = as.character(dataSummary$IDs) # included IDs
n = length(allIDs)

length(allIDs) # 40

# Preliminary data visualization
# distribution of scheduled delays in each block (ECDF) 
# distribution of scheduled delays in each block (autocorrelation plot)
# reaction times 
# trial-by-trial data

# Set figure directory
figDir <- "../output"
setwd(figDir)
study <- "1"

# plot the distribution of scheduled delays in each block (ECDF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysECDF.pdf', n)) # adjust ECDF
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  scheduledDelaysECDF(blockData, study, id, dataSummary) 
}
dev.off()

# plot the distribution of scheduled delays in each block (ACF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysACF.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  scheduledDelaysACF(blockData, study, id, dataSummary) 
}
dev.off()

# reaction time plot
figName = file.path(figDir, sprintf('indivs_n%d_RT.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  outcomeRT(blockData, study, id, dataSummary)
}
dev.off()

# plot trial-by-trial data
figName = file.path(sprintf('indivs_n%d_trialPlots.pdf', n))
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  trialPlots(blockData, study, id, dataSummary)
  
}
dev.off()

# survival curve and AUC
grpAUC = data.frame(rownames=dataSummary$ID, IDs=dataSummary$ID, AUC=numeric(n), 
                    row.names='rownames', stringsAsFactors=FALSE) # initialize group results
scGrid = seq(0, 30, by=0.1)
grpSurvCurves = matrix(nrow=n, ncol=length(scGrid), dimnames=list(dataSummary$ID, scGrid)) # initialize
figName = file.path(figDir, sprintf('indivs_n%d_survivalCurves.pdf', n))
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  
  # calculate kaplan-meier survival curve and area under the curve
  output <- kmsc(blockData, study, id, dataSummary, scGrid) 
  
  grpAUC$AUC[which(grpAUC$IDs == id)] = output$auc 
  grpSurvCurves[id, ] = output$kmOnGrid
}
dev.off()

# save group AUC results
outFileName = file.path(sprintf('grp_n%d_groupAUC.csv', n))
write.csv(grpAUC, file=outFileName, row.names=FALSE)

# AUC analyses as reported in the paper
AUCResults <- merge(grpAUC, dataSummary, by.x = "IDs")
table(AUCResults$cbalAsFactor) # 20 participants per group 
describeBy(AUCResults$AUC, AUCResults$cbalAsFactor) # descriptive information 

# Find the confidence interval (set to 95%) for LP using bootstrapping
CIInfoLPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")])
CInoInfoLPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")])

# LP t-test and Bayes factor
ttestLP <- t.test(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")])
difinAUCLP <- cohensD(mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], na.rm = FALSE),
                      mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")], na.rm = FALSE), 
                      20, 
                      20)

jsq::bttestIS(formula = AUC ~ cbalAsFactor, data = AUCResults, hypothesis = "twoGreater", desc = TRUE)

# compare behavior in LP to optimal behavior (selling just after 2.16)
t.test(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], mu = 2.16)
t.test(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")], mu = 2.16)

cohdeviation_info <- (mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], na.rm = FALSE) - 2.16) / sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")], na.rm = FALSE) 
cohdeviation_noinfo <- (mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")], na.rm = FALSE) - 2.16) / sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")], na.rm = FALSE) 


# Mean survival curves by condition 
# set up colors for group plots

colLPnoInfo <- rgb(225, 0, 0, max = 255, alpha = 125)
colLPInfo <- rgb(255,105,180, max = 255, alpha = 125)
colLPnoInfo_transp = rgb(225, 0, 0, max = 255, alpha = 70)
colLPInfo_transp <- rgb(255,105,180, max = 255, alpha = 50)
colGray = rgb(1/3, 1/3, 1/3)

LPInfoIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "Info")]
LPnoInfoIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "noInfo")]

# Output figure: between-subjects effect in Block 1
#  Block 1 group mean survival curves
figName = file.path(figDir, sprintf('n%d_survivalByCondition.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# Save as tiff for paper
# figName = file.path(sprintf('n%d_survivalByCondition.tiff', n))
# tiff(figName, units="in", width=5, height=5, res=300)

# plot group mean survival curves for block 1 (w/ SEM)
survCurve_grpMean_LPInfo = colMeans2(grpSurvCurves[LPInfoIDs, ]) 
survCurve_grpSEM_LPInfo = colSds(grpSurvCurves[LPInfoIDs, ])/sqrt(length(LPInfoIDs))

survCurve_grpMean_LPnoInfo = colMeans2(grpSurvCurves[LPnoInfoIDs, ]) 
survCurve_grpSEM_LPnoInfo = colSds(grpSurvCurves[LPnoInfoIDs, ])/sqrt(length(LPnoInfoIDs))

plot('', bty='n', xlab='Elapsed time in trial (s)', xlim=c(0,30), xaxp=c(0, 30, 4),
     ylab='Survival rate', ylim=c(0,1), yaxp=c(0, 1, 2),
     main='Survival curves by condition', las=1, xaxt='n')
axis(side = 1, at=seq(0,30, 10), las=1)

# plot LP
errorBand(xData=scGrid, yData=survCurve_grpMean_LPInfo, yErr=survCurve_grpSEM_LPInfo, bandColor=colLPInfo_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_LPnoInfo, yErr=survCurve_grpSEM_LPnoInfo, bandColor=colLPnoInfo_transp)
lines(scGrid, survCurve_grpMean_LPInfo, type='l', lwd=3, col=colLPInfo)
lines(scGrid, survCurve_grpMean_LPnoInfo, type='l', lwd=3, col=colLPnoInfo)

# add a legend
legend('topright', 
       legend=c('LP Standard', 'LP Fictive Information'),
       col=c(colLPnoInfo, colLPInfo), bty='n', lwd=c(2, 2))

# end figure
dev.off()

# Block 1 group AUC
figName = file.path(figDir, sprintf('n%d_survivalByBeeswarm.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)

# beeswarm+box plot of group AUC results - between-subject effect for block 1
AUCList = list(
  infoLP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "Info")],
  noInfoLP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "noInfo")])
boxplot(AUCList, outline=FALSE, boxwex=0.5, col=c(colLPInfo_transp, colLPnoInfo_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(0,30), yaxp=c(0, 30, 4), ylab='AUC (s)',
        main='AUC')
beeswarm(AUCList, pch=16, col=c(colLPInfo_transp, colLPnoInfo_transp), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

# end figure
dev.off()

# WTW time series, across both conditions
tGrid = 1:900
wtwCeiling=30 # for comparability across studies/conditions
wtwTS_results = matrix(data=NA, nrow=n, ncol=length(tGrid), dimnames=list(allIDs))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  # calculate willingness to wait time-series
  wtwTS_results[id, ] <- wtwTS(blockData, tGrid, wtwCeiling)
}

# plot the mean WTW function by group
tValues = list(1:900)
# obtain mean and SEM for each group
wtwTS_grpMean = list()
wtwTS_grpSEM = list()

for (this_cbal in c('LPInfo', 'LPnoInfo')) {
  if (this_cbal == "LPInfo"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPInfoIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPInfoIDs, ])/sqrt(length(LPInfoIDs))  
  }
  if (this_cbal == "LPnoInfo"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPnoInfoIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPnoInfoIDs, ])/sqrt(length(LPnoInfoIDs))  
  }
}

figName = file.path(sprintf('n%d_wtwByConditionLP.pdf', n))
pdf(figName, width=, height=3, pointsize=9)

# figName = file.path(sprintf('n%d_wtwByConditionLP.tiff', n))
# tiff(figName, units="in", width=10, height=5, res=300)

# initialize the plot
plot('', type='n', xlim=c(0, 900), bty='n', ylim=c(0, 30), yaxp=c(0, 30, 4),
     xlab='Time elapsed in block (min)', ylab='WTW (s)',
     main='Local willingness-to-wait estimates', yaxt='n', xaxt='n')
axis(side = 2, at=seq(0,30, 10), las=1)
axis(side = 1, at=seq(0, 960, 120), las=1, labels = seq(0, 16, 2))

# add error bands, one block at a time
errorBand(xData=1:900, yData=wtwTS_grpMean$LPInfo, 
          yErr=wtwTS_grpSEM$LPInfo, bandColor=colLPInfo_transp)
errorBand(xData=1:900, yData=wtwTS_grpMean$LPnoInfo, 
          yErr=wtwTS_grpSEM$LPnoInfo, bandColor=colLPnoInfo_transp)

# add means
lines(1:900, wtwTS_grpMean$LPInfo, col=colLPInfo, type='l', lwd=2, lty='solid')
lines(1:900, wtwTS_grpMean$LPnoInfo, col=colLPnoInfo, type='l', lwd=2, lty='solid')

# add a legend
legend('topright', 
       legend=c('LP Standard', 'LP Fictive Information'),
       col=c(colLPnoInfo, colLPInfo), bty='n', lwd=c(2, 2))
dev.off()

# regression model predicting WTW per second by seconds elapsed for each individual, then compare coefficients using a t-test
dataSummary$wtw_trend <- rep(NA, nrow(dataSummary))

for (id in dataSummary$ID) {
  
  data <-  subset(large_df, large_df$ID == id)
  
  wtwTS_vector <- wtwTS_results[id, ]
  dat <- as.data.frame(cbind(1:900, wtwTS_vector))
  colnames(dat) <- c("second", "wtw") 
  
  model <- lm(wtw ~ second, data = dat) 
  
  dataSummary$wtw_trend[which(dataSummary$IDs == id)] <- as.numeric(model$coefficients[2])
}

figName = file.path(figDir, sprintf('indivs_n%d_coefficients.pdf', n)) 
pdf(figName, pointsize=14)

coefficientsList = list(
  InfoLP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "Info")],
  noInfoLP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "noInfo")])
boxplot(coefficientsList, outline=FALSE, boxwex=0.5, col=c(colLPInfo_transp, colLPnoInfo_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(-0.05,0.05), ylab='Coefficient',
        main='Coefficient: wtw-trend')
abline(h = 0, lty = 2)
beeswarm(coefficientsList, pch=16, col=c(colLPInfo_transp, colLPnoInfo_transp), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

dev.off()

# trend analyses as reported in the paper
describeBy(dataSummary$wtw_trend, dataSummary$cbalAsFactor) # descriptive information 

mean(dataSummary$wtw_trend[which(AUCResults$cbalAsFactor == "Info")])
mean(dataSummary$wtw_trend[which(AUCResults$cbalAsFactor == "noInfo")])

# Find the confidence interval (set to 95%) for LP using bootstrapping
CIInfoLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "Info")])
CInoInfoLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "noInfo")])

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "Info")], dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "noInfo")])
difinAUCLP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "Info")], na.rm = FALSE),
                      mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "noInfo")], na.rm = FALSE), 
                      sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "Info")], na.rm = FALSE), 
                      sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "noInfo")], na.rm = FALSE), 
                      20, 
                      20)

jsq::bttestIS(formula = wtw_trend ~ cbalAsFactor, data = dataSummary, hypothesis = "twoGreater", desc = TRUE)
