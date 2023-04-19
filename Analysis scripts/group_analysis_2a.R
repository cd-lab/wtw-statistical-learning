# Analysis script for Study 2a

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
library("lmerTest")
library("boot")
library("jsq")
library("dplyr")

# Set data directory
dataDir <- "../study 2a/data"
setwd(dataDir)

# Higher level information per participant
headerInfo <- read.csv("headerFileImplicit.csv")

# Trial data
trialData <- read.csv("implicitData.csv")

# check the loaded data files and save out a summary
# data_summary: Should have basic information on each participant, such as
# ID, date of participation, condition, number of trials, duration, and a check for the inclusion criteria
nblocks <- 2
IDs <- c()

b1_numTrials <- c()
b2_numTrials <- c()

earnings <- c()
date <- c()
manipulation <- c()
file_name <- c()
maxScheduledDelay <- c()
cbal <- c()
cbalAsFactor <- c()
cbalAsFactoradd <- c()

b1_timingCond <- c()
b2_timingCond <- c()

b1_prop_expired <- c()
b2_prop_expired <- c()

large_df <- c()
gut_explicit <- c()


for (d in unique(trialData$ID)){
  
  data <- subset(trialData, trialData$ID == d)
  header <- headerInfo[which(headerInfo$id == d), ]
  
  # We skip data files that are not in the header.list, this removes participant "BX8427"
  if (nrow(header) == 0){
    next
  }
  
  b1_data <- subset(data, blockNum == 1)
  b2_data <- subset(data, blockNum == 2)
  
  IDs <- c(IDs, as.character (header$id))
  
  b1_numTrials <- c(b1_numTrials, max(as.numeric(b1_data$trialNum)))
  b2_numTrials <- c(b2_numTrials, max(as.numeric(b2_data$trialNum)))
  
  gut_explicit <- c(gut_explicit, header$explicit.gut)
  
  # Information on timing condition 
  if(as.numeric(header$cbal) == 1){
    b1_cond <- "HP"
    b2_cond <- "HP"
    cbalAsFactoradd <- "HPcongruent"
  } else if (as.numeric(header$cbal) == 2){
    b1_cond <- "HP"
    b2_cond <- "LP"
    cbalAsFactoradd <- "LPincongruent"
  } else if (as.numeric(header$cbal) == 3){
    b1_cond <- "LP"
    b2_cond <- "HP"
    cbalAsFactoradd <- "HPincongruent"
  } else if (as.numeric(header$cbal) == 4){
    b1_cond <- "LP"
    b2_cond <- "LP"
    cbalAsFactoradd <- "LPcongruent"
  }
  
  cbalAsFactor <- c(cbalAsFactor, cbalAsFactoradd)
  cbal <- c(cbal, as.character(header$cbal))
  
  b1_timingCond <- c(b1_timingCond, b1_cond)
  b2_timingCond <- c(b2_timingCond, b2_cond)
  
  # out of all tokens that matured
  b1numMaturedTokens <- sum(!is.na(b1_data$rwdOnsetTime))
  b2numMaturedTokens <- sum(!is.na(b2_data$rwdOnsetTime))
  
  # how many expired
  b1numExpiredTokens <- sum(is.na(b1_data$latency))
  b2numExpiredTokens <- sum(is.na(b2_data$latency))
  
  b1_prop_expired <- c(b1_prop_expired, b1numExpiredTokens/b1numMaturedTokens)
  b2_prop_expired <- c(b2_prop_expired, b2numExpiredTokens/b2numMaturedTokens)
  
  earnings <- c(earnings, max(as.numeric(data$totalEarned)))
  file_name <- c(file_name, as.character(header$dfname))
  maxScheduledDelay <- c(maxScheduledDelay, max(as.numeric(data$designatedWait)))
  
  # add RT
  data$RT <- as.numeric(data$latency) - as.numeric(data$rwdOnsetTime)  
  data$ID <- rep(as.character(header$id), nrow(data))
  
  # If the token expired, RT should be NAN 
  if (sum(as.numeric(data$trialExpired)) > 0){
    data$RT[which(data$trialExpired == 1)] <- NaN
  }
  
  # add quit index to each data set
  data$idxQuit <- rep(0, nrow(data))
  data$idxQuit[which(is.na(data$rwdOnsetTime))] <- 1
  # Note that expired tokens should be considered wait trials
  
  data$cbalAsFactor <- rep(cbalAsFactoradd, dim = c(1, nrow(data)))
  
  # Add to a large data file
  large_df <- rbind(large_df, data)
}

dataSummary <- as.data.frame(cbind(IDs, file_name, b1_numTrials, b2_numTrials, earnings, b1_timingCond, b2_timingCond, maxScheduledDelay, cbal, cbalAsFactor, gut_explicit))

# Confirm that we are including the correct participants
included_ids <- read.csv("included_participants.csv")

# Included participants (lines up with included_ids)
allIDs = unique(large_df$ID)
n = length(allIDs)

# Preliminary data visualization
# distribution of scheduled delays in each block (ECDF) 
# distribution of scheduled delays in each block (autocorrelation plot)
# reaction times 
# trial-by-trial data

# set figure directory
figDir <- "../output"
setwd(figDir)
study <- "2a"

# plot the distribution of scheduled delays in each block (ECDF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysECDF.pdf', n)) # adjust ECDF
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  
  data <-  subset(large_df, large_df$ID == id)
  b1_data <- subset(data, blockNum == 1)
  b2_data <- subset(data, blockNum == 2)
  
  for (b in 1:nblocks){
    if (b == 1){
      blockData <- b1_data
    } else if (b == 2){
      blockData <- b2_data
    }
    
    scheduledDelaysECDF(blockData, study, id, dataSummary) 
  }
}
dev.off()

# plot the distribution of scheduled delays in each block (ACF)
figName = file.path(sprintf('indivs_n%d_scheduledDelaysACF.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  
  data <-  subset(large_df, large_df$ID == id)
  b1_data <- subset(data, blockNum == 1)
  b2_data <- subset(data, blockNum == 2)
  
  for (b in 1:nblocks){
    if (b == 1){
      blockData <- b1_data
    } else if (b == 2){
      blockData <- b2_data
    }
    
    scheduledDelaysACF(blockData, study, id, dataSummary) 
  }
}
dev.off()

# reaction time plot
figName = file.path(sprintf('indivs_n%d_RT.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  data <-  subset(large_df, large_df$ID == id)
  b1_data <- subset(data, blockNum == 1)
  b2_data <- subset(data, blockNum == 2)
  
  for (b in 1:nblocks){
    if (b == 1){
      blockData <- b1_data
    } else if (b == 2){
      blockData <- b2_data
    }
    outcomeRT(blockData, study, id, dataSummary)
  }
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
grpAUC = data.frame(rownames=allIDs, IDs=allIDs, bk2=numeric(n),
                    row.names='rownames', stringsAsFactors=FALSE) # initialize group results
scGrid = seq(0, 20, by=0.1)
grpSurvCurves = matrix(nrow=n, ncol=length(scGrid), dimnames=list(dataSummary$ID, scGrid)) # initialize
figName = file.path(figDir, sprintf('indivs_n%d_survivalCurves.pdf', n))
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:(n*2), n, 2, byrow=TRUE))

for (id in dataSummary$ID) {
  
  blockData <-  subset(large_df, large_df$ID == id & blockNum == 2 )
  
  # calculate kaplan-meier survival curve and area under the curve
  output <- kmsc(blockData, study, id, dataSummary, scGrid) 
  
  grpAUC$AUC[which(grpAUC$IDs == id)] = output$auc 
  grpSurvCurves[id, ] = output$kmOnGrid
  
}
dev.off()

# save group AUC results
outFileName = file.path(sprintf('grp_n%d_groupAUC.csv', n))
write.csv(grpAUC, file=outFileName, row.names=FALSE)

AUCResults <- merge(grpAUC, dataSummary, by.x = "IDs")
table(AUCResults$cbalAsFactor)
describeBy(AUCResults$AUC, AUCResults$cbalAsFactor)

AUCResultsHP <- subset(AUCResults, AUCResults$cbalAsFactor == "HPcongruent" | AUCResults$cbalAsFactor == "HPincongruent")
AUCResultsLP <- subset(AUCResults, AUCResults$cbalAsFactor == "LPcongruent" | AUCResults$cbalAsFactor == "LPincongruent")

# Bootstrap confidence interval for HP
CIcongruentHPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPcongruent")])
CIincongruentHPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPincongruent")])

# Bootstrap confidence interval for LP
CIcongruentLPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPcongruent")])
CIincongruentLPBoot <- calcCIBoot(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPincongruent")])

# Create factors for ANOVA
AUCResults$congruency <- rep(NA, dim = c(1,nrow(AUCResults)))
AUCResults$congruency[which(AUCResults$cbalAsFactor == "LPcongruent" | AUCResults$cbalAsFactor == "HPcongruent")] <- "congruent"
AUCResults$congruency[which(AUCResults$cbalAsFactor == "LPincongruent" | AUCResults$cbalAsFactor == "HPincongruent")] <- "incongruent"

# Anova: AUC means by timing condition and manipulation (discrete vs standard)
AUCanova <- aov(AUC ~ b2_timingCond * congruency, data = AUCResults)
summary(AUCanova)
etaSquared(AUCanova)

# HP t-test and Bayes factor
ttestHP <- t.test(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPcongruent")], AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPincongruent")])
difinAUCHP <- cohensD(mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPcongruent")], na.rm = FALSE),
                      mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPcongruent")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                      20, 
                      20)

jsq::bttestIS(formula = AUC ~ cbalAsFactor, data = AUCResultsHP, hypothesis = "oneGreater", desc = TRUE)
# directional test would check whether HP congruent is higher than HP incongruent

# deviation from the optimal wait time (20 s)
AUCResultsHP$difto20 <-  AUCResultsHP$AUC - 20

CIcongruentHPdifBoot <- calcCIBoot(AUCResultsHP$difto20[which(AUCResultsHP$cbalAsFactor == "HPcongruent")])
CIincongruentHPdifBoot <- calcCIBoot(AUCResultsHP$difto20[which(AUCResultsHP$cbalAsFactor == "HPincongruent")])

mean(AUCResultsHP$difto20[which(AUCResultsHP$cbalAsFactor == "HPcongruent")], na.rm = TRUE)
mean(AUCResultsHP$difto20[which(AUCResultsHP$cbalAsFactor == "HPincongruent")], na.rm = TRUE)

# LP t-test and Bayes factor
ttestLP <- t.test(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPcongruent")], AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPincongruent")])
difinAUCLP <- cohensD(mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPcongruent")], na.rm = FALSE),
                      mean(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPcongruent")], na.rm = FALSE), 
                      sd(AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                      20, 
                      22)

jsq::bttestIS(formula = AUC ~ cbalAsFactor, data = AUCResultsLP, hypothesis = "twoGreater", desc = TRUE)
# directional test would check whether LP congruent is lower than LP incongruent

# compare behavior in LP to optimal behavior (selling just after 2.16)
t.test(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPcongruent")], mu = 2.16)
t.test(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPincongruent")], mu = 2.16)

cohdeviation_congruent <- (mean(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPcongruent")], na.rm = FALSE) - 2.16) / sd(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPcongruent")], na.rm = FALSE) 
cohdeviation_incongruent <- (mean(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPincongruent")], na.rm = FALSE) - 2.16) / sd(AUCResultsLP$AUC[which(AUCResultsLP$cbalAsFactor == "LPincongruent")], na.rm = FALSE) 

# Mean survival curves by condition 
# set up colors for group plots
colHPcongruent <- rgb(0, 0, 225, max = 255, alpha = 125)
colHPincongruent <- rgb(48,213,200, max = 255, alpha = 125)
colHPcongruent_transp = rgb(0, 0, 225, max = 255, alpha = 70)
colHPincongruent_transp <- rgb(48,213,200, max = 255, alpha = 50)

colLPcongruent <- rgb(225, 0, 0, max = 255, alpha = 125)
colLPincongruent <- rgb(255,105,180, max = 255, alpha = 125)
colLPcongruent_transp = rgb(225, 0, 0, max = 255, alpha = 70)
colLPincongruent_transp <- rgb(255,105,180, max = 255, alpha = 50)
colGray = rgb(1/3, 1/3, 1/3)

# Output figure: between-subjects effect in Block 1
#   panel A = Block 1 group mean survival curves
#   panel B = Block 1 group AUC

figName = file.path(figDir, sprintf('n%d_survivalByCondition.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# figName = file.path(sprintf('n%d_survivalByCondition.tiff', n))
# tiff(figName, units="in", width=5, height=5, res=300)

HPcongruentIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "HPcongruent")]
LPcongruentIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "LPcongruent")]
HPincongruentIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "HPincongruent")]
LPincongruentIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "LPincongruent")]

# plot group mean survival curves for block 1 (w/ SEM)
survCurve_grpMean_idxHPcongruent = colMeans2(grpSurvCurves[HPcongruentIDs, ]) 
survCurve_grpSEM_idxHPcongruent = colSds(grpSurvCurves[HPcongruentIDs, ])/sqrt(length(HPcongruentIDs))

survCurve_grpMean_idxHPincongruent = colMeans2(grpSurvCurves[HPincongruentIDs, ]) 
survCurve_grpSEM_idxHPincongruent = colSds(grpSurvCurves[HPincongruentIDs, ])/sqrt(length(HPincongruentIDs))

survCurve_grpMean_idxLPcongruent = colMeans2(grpSurvCurves[LPcongruentIDs, ]) 
survCurve_grpSEM_idxLPcongruent = colSds(grpSurvCurves[LPcongruentIDs, ])/sqrt(length(LPcongruentIDs))

survCurve_grpMean_idxLPincongruent = colMeans2(grpSurvCurves[LPincongruentIDs, ]) 
survCurve_grpSEM_idxLPincongruent = colSds(grpSurvCurves[LPincongruentIDs, ])/sqrt(length(LPincongruentIDs))

plot('', bty='n', xlab='Elapsed time in trial (s)', xlim=c(0,20), xaxp=c(0, 20, 4),
     ylab='Survival rate', ylim=c(0,1), yaxp=c(0, 1, 2),
     main='Survival curves by condition', las=1, xaxt='n')
axis(side = 1, at=seq(0,20, 10), las=1)

# plot HP
errorBand(xData=scGrid, yData=survCurve_grpMean_idxHPcongruent, yErr=survCurve_grpSEM_idxHPcongruent, bandColor=colHPcongruent_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_idxHPincongruent, yErr=survCurve_grpSEM_idxHPincongruent, bandColor=colHPincongruent_transp)
lines(scGrid, survCurve_grpMean_idxHPcongruent, type='l', lwd=3, col=colHPcongruent)
lines(scGrid, survCurve_grpMean_idxHPincongruent, type='l', lwd=3, col=colHPincongruent)

# plot LP
errorBand(xData=scGrid, yData=survCurve_grpMean_idxLPcongruent, yErr=survCurve_grpSEM_idxLPcongruent, bandColor=colLPcongruent_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_idxLPincongruent, yErr=survCurve_grpSEM_idxLPincongruent, bandColor=colLPincongruent_transp)
lines(scGrid, survCurve_grpMean_idxLPcongruent, type='l', lwd=3, col=colLPcongruent)
lines(scGrid, survCurve_grpMean_idxLPincongruent, type='l', lwd=3, col=colLPincongruent)

# add a legend
legend('bottomleft', 
       legend=c('HP congruent', 'HP incongruent', 'LP congruent', 'LP incongruent'),
       col=c(colHPcongruent, colHPincongruent, colLPcongruent, colLPincongruent), bty='n', lwd=c(2, 2))

dev.off()

# Block 1 group AUC
figName = file.path(figDir, sprintf('n%d_survivalByBeeswarm.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)

# beeswarm+box plot of group AUC results - between-subject effect for block 1
AUCList = list(
  HPcongruent = AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPcongruent")],
  HPincongruent = AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPincongruent")],
  LPcongruent = AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPcongruent")],
  LPincongruent = AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPincongruent")])
boxplot(AUCList, outline=FALSE, boxwex=0.5, col=c(colHPcongruent, colHPincongruent, colLPcongruent, colLPincongruent),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(0,30), yaxp=c(0, 30, 4), ylab='AUC (s)',
        main='AUC')
beeswarm(AUCList, pch=16, col=c(colHPcongruent, colHPincongruent, colLPcongruent, colLPincongruent), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

# end figure
dev.off()

# WTW time series, across both conditions
tGrid = 1:900
wtwTS_results = matrix(data=NA, nrow=n, ncol=length(tGrid), dimnames=list(allIDs))
wtwCeiling=20 # For comparison, we limit this to 20 seconds

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id & large_df$blockNum == 2)
  # calculate willingness to wait time-series
  wtwTS_results[id, ] <- wtwTS(blockData, tGrid, wtwCeiling)
}

# plot the mean WTW function by counterbalance group
tValues = list(1:900)
# obtain mean and SEM for each counterbalance group
wtwTS_grpMean = list()
wtwTS_grpSEM = list()

for (this_cbal in c('HPcongruent', 'HPincongruent', 'LPcongruent', 'LPincongruent')) {
  if (this_cbal == "HPcongruent"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[HPcongruentIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[HPcongruentIDs, ])/sqrt(length(HPcongruentIDs))  
  }
  if (this_cbal == "HPincongruent"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[HPincongruentIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[HPincongruentIDs, ])/sqrt(length(HPincongruentIDs)) 
  }
  if (this_cbal == "LPcongruent"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPcongruentIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPcongruentIDs, ])/sqrt(length(LPcongruentIDs))
  }
  if (this_cbal == "LPincongruent"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPincongruentIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPincongruentIDs, ])/sqrt(length(LPincongruentIDs))  
  }
}

figName = file.path(figDir, sprintf('n%d_wtwByConditionHP.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)

# figName = file.path(sprintf('n%d_wtwByConditionHP.tiff', n))
# tiff(figName, units="in", width=10, height=5, res=300)

# initialize the plot
plot('', type='n', xlim=c(0, 900), bty='n', ylim=c(0, 20), yaxp=c(0, 20, 4),
     xlab='Time elapsed in block (min)', ylab='WTW (s)',
     main='Local willingness-to-wait estimates', yaxt='n', xaxt='n')
axis(side = 2, at=seq(0,30, 10), las=1)
axis(side = 1, at=seq(0, 960, 120), las=1, labels = seq(0, 16, 2))

# add error bands, one block at a time
errorBand(xData=1:900, yData=wtwTS_grpMean$HPcongruent, 
          yErr=wtwTS_grpSEM$HPcongruent, bandColor=colHPcongruent_transp)
errorBand(xData=1:900, yData=wtwTS_grpMean$HPincongruent, 
          yErr=wtwTS_grpSEM$HPincongruent, bandColor=colHPincongruent_transp)

# add means
lines(1:900, wtwTS_grpMean$HPcongruent, col=colHPcongruent, type='l', lwd=2, lty='solid')
lines(1:900, wtwTS_grpMean$HPincongruent, col=colHPincongruent, type='l', lwd=2, lty='solid')

# add a legend
legend(670,22, 
       legend=c('HP congruent', 'HP incongruent'),
       col=c(colHPcongruent, colHPincongruent), bty='n', lwd=c(2, 2))
dev.off()

figName = file.path(figDir, sprintf('Fig2_n%d_wtwByConditionLP.pdf', n))
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
errorBand(xData=1:900, yData=wtwTS_grpMean$LPcongruent, 
          yErr=wtwTS_grpSEM$LPcongruent, bandColor=colLPcongruent_transp)
errorBand(xData=1:900, yData=wtwTS_grpMean$LPincongruent, 
          yErr=wtwTS_grpSEM$LPincongruent, bandColor=colLPincongruent_transp)

# add means
lines(1:900, wtwTS_grpMean$LPcongruent, col=colLPcongruent, type='l', lwd=2, lty='solid')
lines(1:900, wtwTS_grpMean$LPincongruent, col=colLPincongruent, type='l', lwd=2, lty='solid')

# add a legend
legend('topright', 
       legend=c('LP congruent', 'LP incongruent'),
       col=c(colLPcongruent, colLPincongruent), bty='n', lwd=c(2, 2))
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

describeBy(dataSummary$wtw_trend, dataSummary$cbalAsFactor)

dataSummaryHP <- subset(dataSummary, dataSummary$cbalAsFactor == "HPcongruent" | dataSummary$cbalAsFactor == "HPincongruent")
dataSummaryLP <- subset(dataSummary, dataSummary$cbalAsFactor == "LPcongruent" | dataSummary$cbalAsFactor == "LPincongruent")

# means
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")])

# Bootstrap confidence interval for HP
CIcongruentHPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")])
CIincongruentHPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")])

# Bootstrap confidence interval for LP
CIcongruentLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")])
CIincongruentLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")])

# Create factors for ANOVA
dataSummary$congruency <- rep(NA, dim = c(1,nrow(dataSummary)))
dataSummary$congruency[which(dataSummary$cbalAsFactor == "LPcongruent" | dataSummary$cbalAsFactor == "HPcongruent")] <- "congruent"
dataSummary$congruency[which(dataSummary$cbalAsFactor == "LPincongruent" | dataSummary$cbalAsFactor == "HPincongruent")] <- "incongruent"

# Anova: AUC means by timing condition and manipulation (discrete vs standard)
wtw_trendanova <- aov(wtw_trend ~ b2_timingCond * congruency, data = dataSummary)
summary(wtw_trendanova)
etaSquared(wtw_trendanova)

# HP t-test and Bayes factor
ttestHP <- t.test(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")], dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")])
difintrendHP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")], na.rm = FALSE),
                        mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                        20, 
                        20)

jsq::bttestIS(formula = wtw_trend ~ cbalAsFactor, data = dataSummaryHP, hypothesis = "oneGreater", desc = TRUE)
# HP congruent is higher than HP incongruent

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")], dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")])
difintrendLP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")], na.rm = FALSE),
                        mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                        20, 
                        22)

jsq::bttestIS(formula = wtw_trend ~ cbalAsFactor, data = dataSummaryLP, hypothesis = "twoGreater", desc = TRUE)
# LP congruent is less than LP incongruent

figName = file.path(figDir, sprintf('indivs_n%d_coefficients.pdf', n)) 
pdf(figName, pointsize=14)

coefficientsList = list(
  HPcongruent = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPcongruent")],
  HPincongruent = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPincongruent")],
  LPcongruent = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPcongruent")],
  LPincongruent = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPincongruent")])

boxplot(coefficientsList, outline=FALSE, boxwex=0.5, col=c(colHPcongruent_transp, colHPincongruent_transp, colLPcongruent_transp, colLPincongruent_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(-0.05,0.05), ylab='Coefficient',
        main='Coefficient: wtw-trend')
abline(h = 0, lty = 2)
beeswarm(coefficientsList, pch=16, col=c(colHPcongruent_transp, colHPincongruent_transp, colLPcongruent_transp, colLPincongruent_transp), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

dev.off()

# Response time analysis
### Check whether learning occurred in the reaction times during the passive exposure block
# Analyses restricted to the second half of the block (450 plus seconds) and to trials that lasted less than 20 seconds

large_df$length_delay <- rep(0, nrow(large_df))
large_df$length_delay[which(as.numeric(large_df$designatedWait) < 3)] <- "less3"
large_df$length_delay[which(as.numeric(large_df$designatedWait) >= 3 & as.numeric(large_df$designatedWait) < 6)] <- "3to6"
large_df$length_delay[which(as.numeric(large_df$designatedWait) >= 6 & as.numeric(large_df$designatedWait) < 9)] <- "6to9"
large_df$length_delay[which(as.numeric(large_df$designatedWait) >= 9 & as.numeric(large_df$designatedWait) < 15)] <- "9to15"
large_df$length_delay[which(as.numeric(large_df$designatedWait) >= 15 & as.numeric(large_df$designatedWait) <= 20)] <- "15to20"
large_df$length_delay[which(as.numeric(large_df$designatedWait) > 20)] <- "exclude"

large_df$copydesignatedWait <- large_df$designatedWait # to check

dflmer <- c()
for (id in dataSummary$ID) {
  
  data <-  subset(large_df, large_df$ID == id & large_df$blockNum == 1)
  
  data$secondHalf <- rep(0, nrow(data))
  startSecondHalf <- (ceiling(nrow(data)/2)+1)
  data$secondHalf[startSecondHalf:nrow(data)] <- 1
  
  # create DV:The dependent variable is the RT on each trial after subtracting the grand median RT for each participant (across all trials in the first block). 
  data$medianRT <- rep(median(data$RT, na.rm = TRUE), nrow(data))
  data$RTMinusMedianRT <- data$RT - data$medianRT
  
  dflmer <- rbind(dflmer, data)
}

dflmer$n_latency <- as.numeric(dflmer$latency)
dflmer$n_RTMinusMedianRT <- as.numeric(dflmer$RTMinusMedianRT)
dflmer$n_designatedWait <- as.numeric(dflmer$designatedWait)

# only use second half for analysis
dflmer_incl <- subset (dflmer, dflmer$secondHalf == 1 & dflmer$designatedWait <= 20)
dflmer <- dflmer_incl

# Participants who experienced HP in block 1
dflmer_HP <- subset(dflmer, dflmer$cbalAsFactor == "HPcongruent" | dflmer$cbalAsFactor == "LPincongruent")
dflmer_LP <- subset(dflmer, dflmer$cbalAsFactor == "LPcongruent" | dflmer$cbalAsFactor == "HPincongruent")

# Model
model_HP <- lmer(n_RTMinusMedianRT ~ n_designatedWait + (1 + n_designatedWait | ID), data =  dflmer_HP, control = lmerControl(optimizer = c("bobyqa")))
summary(model_HP)
model_LP <- lmer(n_RTMinusMedianRT ~ n_designatedWait + (1 + n_designatedWait | ID), data =  dflmer_LP, control = lmerControl(optimizer = c("bobyqa")))
summary(model_LP)

# CIs around the beta estimates
upperCIHP <- -0.0018931 + 1.96 * 0.0006232
lowerCIHP <- -0.0018931 - 1.96 * 0.0006232

upperCILP <- 0.001739 + 1.96 * 0.000393
lowerCILP <- 0.001739 - 1.96 * 0.000393

# Plot mean reaction times (on y-axis) by token maturation time during the second half of the passive exposure block
# Derive mean per person per delay category
summary_file <- dflmer %>% group_by(ID, length_delay) %>%
  summarise(meanRTperPerson=mean(RTMinusMedianRT, na.rm = T))

addCondition <- select(dataSummary, IDs, b1_timingCond)
colnames(addCondition) <- c('ID', 'cond')

summaryFileWithCondition <- merge(addCondition, summary_file )

plottingFile <- summaryFileWithCondition %>% group_by(length_delay, cond) %>%
  summarise(meanPerDelayByGroup=mean(meanRTperPerson, na.rm = T), 
            sdPerDelayByGroup = sd(meanRTperPerson, na.rm = T))

plottingFile$semPerDelayByGroup <- rep(NA, nrow(plottingFile))

plottingFile$semPerDelayByGroup[which(plottingFile$cond == "HP")] <- plottingFile$sdPerDelayByGroup[which(plottingFile$cond == "HP")] / sqrt(42)
plottingFile$semPerDelayByGroup[which(plottingFile$cond == "LP")] <- plottingFile$sdPerDelayByGroup[which(plottingFile$cond == "LP")] / sqrt(40)

# 42 participants in HP block 1 (20 in HP congruent and 22 in LP incongruent)
# 40 participants in LP block 1 (20 in LP congruent and 20 in HP incongruent)

plottingFile <- as.data.frame(plottingFile)
plottingFile$f_delay <- factor(plottingFile$length_delay, ordered = TRUE, 
                               levels = c("less3","3to6", "6to9", "9to15", "15to20"))

figName = file.path(figDir, sprintf('n%d_RTplot.pdf', n)) 
pdf(figName, pointsize=14)

# figName = file.path(sprintf('n%d_RT.tiff', n))
# tiff(figName, units="in", width=7.5, height=5, res=300)

ggplot(data = plottingFile, aes(x = f_delay, y = meanPerDelayByGroup, colour = cond, group = cond)) +
  geom_point() +
  geom_errorbar(aes(ymin=meanPerDelayByGroup-semPerDelayByGroup, ymax=meanPerDelayByGroup+semPerDelayByGroup), color = "grey", width = 0.2) +
  geom_line() +
  scale_color_manual(values=c("blue" ,"red")) +
  xlab("Token maturation time") +
  ylab("Mean RTs (s)") +
  ggtitle("Reaction times in passive block (Second half)") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.position = c(0.85, 0.85)) +
  scale_x_discrete(labels=c("less3" = "< 3", "3to6" = "3-6", "6to9" = "6-9",  "9to15" = "9-15", "15to20" = "15-20")) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank(), 
    legend.position = c(0.8, 0.8),
    legend.text = element_text(size = 16),
    legend.margin = margin(t = 5, l = 5, r = 5, b = 5),
    legend.key = element_rect(color = NA, fill = NA),
    plot.margin = unit(c(1, 1, 1, 1), "cm"),
    plot.title = element_text(size = 16,
                              hjust = 0.5,
                              margin = margin(b = 16)),
    axis.line = element_line(color = "black", size = .5),
    axis.title = element_text(size = 16, color = "black"),
    axis.text = element_text(size = 16, color = "black"),
    axis.text.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    axis.ticks = element_line(size = .5)
  ) +
  labs(colour = "") 

dev.off()

# Self-reported ideal maximum wait times
dataSummary$gut_explicit <- as.numeric(dataSummary$gut_explicit)
describeBy(dataSummary$gut_explicit, dataSummary$cbalAsFactor) # descriptive information 

dataSummaryHP <- subset(dataSummary, dataSummary$cbalAsFactor == "HPcongruent" | dataSummary$cbalAsFactor == "HPincongruent")
dataSummaryLP <- subset(dataSummary, dataSummary$cbalAsFactor == "LPcongruent" | dataSummary$cbalAsFactor == "LPincongruent")

# Find the confidence interval (set to 95%) for HP
# Using bootstrapping
CIcongruentHPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPcongruent")])))
CIincongruentHPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPincongruent")])))

# Find the confidence interval (set to 95%) for LP
# Using bootstrapping
CIcongruentLPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPcongruent")])))
CIincongruentLPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPincongruent")])))

# Anova: AUC means by timing condition and manipulation (discrete vs standard)
gutanova <- aov(gut_explicit ~ b2_timingCond * congruency, data = dataSummary)
summary(gutanova)
etaSquared(gutanova)

# HP t-test and Bayes factor
ttestHP <- t.test(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPcongruent")], dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPincongruent")])
difinAUCHP <- cohensD(mean(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPcongruent")], na.rm = FALSE),
                      mean(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                      sd(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPcongruent")], na.rm = FALSE), 
                      sd(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPincongruent")], na.rm = FALSE), 
                      20, 
                      20)

jsq::bttestIS(formula = gut_explicit ~ cbalAsFactor, data = dataSummaryHP, hypothesis = "oneGreater", desc = TRUE)

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPcongruent")], dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPincongruent")])
difinAUCLP <- cohensD(mean(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPcongruent")], na.rm = FALSE),
                      mean(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                      sd(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPcongruent")], na.rm = FALSE), 
                      sd(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPincongruent")], na.rm = FALSE), 
                      20, 
                      22)

jsq::bttestIS(formula = gut_explicit ~ cbalAsFactor, data = dataSummaryLP, hypothesis = "twoGreater", desc = TRUE)
