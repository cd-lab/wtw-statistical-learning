# Analysis script for Study 3a

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
dataDir <- "../study 3a/data"
setwd(dataDir)

# Higher level information per participant
headerInfo <- read.csv( "headerFileDiscrete.csv")

# Trial data
trialData <- read.csv("discreteData.csv")

# check the loaded data file and save out a summary
# data_summary: Should have basic information on each participant, such as
# ID, date of participation, condition, number of trials, duration, and a check for the inclusion criteria
IDs <- c()
numTrials <- c()
timingCond <- c()
earnings <- c()
date <- c()
manipulation <- c()
medianRT <- c()
file_name <- c()
maxScheduledDelay <- c()
cbal <- c()
cbalAsFactor <- c()
gut_explicit <- c()

large_df <- c()

for (d in unique(trialData$ID)){
  
  data <- subset(trialData, trialData$ID == d)
  header <- headerInfo[which(headerInfo$id == d), ]
  
  # three pilot data files are not in the header list, we skip those
  if (nrow(header) == 0){
    next
  }

  IDs <- c(IDs, d)
  numTrials <- c(numTrials, max(as.numeric(data$trialNum)))
  
  gut_explicit <- c(gut_explicit, header$explicit.gut)
  
  # Information on timing condition and manipulation
  if(as.numeric(header$cbal) == 1){
    cond <- "HP"
    manipu <- "standard"
    cbalAsFactor <- c(cbalAsFactor, "HPstandard")
  } else if (as.numeric(header$cbal) == 2){
    cond <- "LP"
    manipu <- "standard"
    cbalAsFactor <- c(cbalAsFactor, "LPstandard")
  } else if (as.numeric(header$cbal) == 3){
    cond <- "HP"
    manipu <- "discrete"
    cbalAsFactor <- c(cbalAsFactor, "HPdiscrete")
  } else if (as.numeric(header$cbal) == 4){
    cond <- "LP"
    manipu <- "discrete"
    cbalAsFactor <- c(cbalAsFactor, "LPdiscrete")
  }
  
  cbal <- c(cbal, as.character(header$cbal))

  timingCond <- c(timingCond, cond)
  earnings <- c(earnings, max(as.numeric(data$totalEarned)))
  manipulation <- c(manipulation, manipu)
  file_name <- c(file_name, as.character(header$dfname))
  maxScheduledDelay <- c(maxScheduledDelay, max(as.numeric(data$designatedWait)))
  
  # add quit index to each data set
  data$idxQuit <- rep(0, nrow(data))
  data$idxQuit[which(is.na(data$rwdOnsetTime))] <- 1
  
  # add RT
  data$RT <- as.numeric(data$latency) - as.numeric(data$rwdOnsetTime)  
  
  # Add to a large data file
  large_df <- rbind(large_df, data)
}

dataSummary <- as.data.frame(cbind(IDs, file_name, numTrials, earnings, timingCond, manipulation, maxScheduledDelay, cbal, cbalAsFactor, gut_explicit))

# figure out which participants should be excluded:
included_ids <- read.csv("included_participants.csv")

# Make sure that subject ids are in capital letters
allIDs = toupper(as.character(included_ids$included_participants)) # included IDs
n = length(allIDs)

# kn1134 is participant kn1139 and should be included
allIDs[which(allIDs == "KN1139")] <- "KN1134"
# op1113 is participant mn552 and should be included
allIDs[which(allIDs == "OP1113")] <- "MN552"
# ki3601 us outside of the outside of intended age range and should be excluded

length(allIDs) # 64

# exclude dfs that should be excluded from large_df and from dataSummary
large_df <- droplevels(large_df[large_df$ID %in% allIDs, ])
dataSummary <- droplevels(dataSummary[dataSummary$ID %in% allIDs, ])

# Preliminary data visualization
  # distribution of scheduled delays in each block (ECDF) 
  # distribution of scheduled delays in each block (autocorrelation plot)
  # reaction times 
  # trial-by-trial data

# Set figure directory
figDir <- "../output"
setwd(figDir)
study <- "3a"

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
figName = file.path(sprintf('indivs_n%d_RT.pdf', n)) 
pdf(figName, width=6, height=3*n, pointsize=14)
layout(matrix(1:n, n, 1))

for (id in dataSummary$ID) {
  blockData <-  subset(large_df, large_df$ID == id)
  outcomeRT(blockData, study, id, dataSummary)
}
dev.off()

# plot trial-by-trial data
figName = file.path( sprintf('indivs_n%d_trialPlots.pdf', n))
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
scGrid = seq(0, 20, by=0.1)
grpSurvCurves = matrix(nrow=n, ncol=length(scGrid), dimnames=list(dataSummary$ID, scGrid)) # initialize
figName = file.path(sprintf('indivs_n%d_survivalCurves.pdf', n))
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
table(AUCResults$cbalAsFactor) # 16 participants per group 
describeBy(AUCResults$AUC, AUCResults$cbalAsFactor) # descriptive information 

AUCResultsHP <- subset(AUCResults, AUCResults$cbalAsFactor == "HPstandard" | AUCResults$cbalAsFactor == "HPdiscrete")
AUCResultsLP <- subset(AUCResults, AUCResults$cbalAsFactor == "LPstandard" | AUCResults$cbalAsFactor == "LPdiscrete")

# Using bootstrapping
CIstandardHPBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "standard")])))
CIdiscreteHPBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "discrete")])))

# Using bootstrapping
CIstandardLPBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")])))
CIdiscreteLPBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")])))

# Anova: AUC means by timing condition and manipulation (discrete vs standard)
AUCanova <- aov(AUC ~ timingCond * manipulation, data = AUCResults)
summary(AUCanova)
etaSquared(AUCanova)

# HP t-test and Bayes factor
ttestHP <- t.test(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "standard")], AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "discrete")])
difinAUCHP <- cohensD(mean(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "standard")], na.rm = FALSE),
                    mean(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "discrete")], na.rm = FALSE), 
                    sd(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "standard")], na.rm = FALSE), 
                    sd(AUCResultsHP$AUC[which(AUCResultsHP$manipulation == "discrete")], na.rm = FALSE), 
                    16, 
                    16)

jsq::bttestIS(formula = AUC ~ cbalAsFactor, data = AUCResultsHP, hypothesis = "oneGreater", desc = TRUE)

# deviation from the optimal wait time (20 s)
AUCResultsHP$difto20 <-  AUCResultsHP$AUC - 20

# Using bootstrapping
CIstandardHPdifBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsHP$difto20[which(AUCResultsHP$manipulation == "standard")])))
CIdiscreteHPdifBoot <- calcCIBoot(as.numeric(na.omit(AUCResultsHP$difto20[which(AUCResultsHP$manipulation == "discrete")])))

mean(AUCResultsHP$difto20[which(AUCResultsHP$manipulation == "standard")], na.rm = TRUE)
mean(AUCResultsHP$difto20[which(AUCResultsHP$manipulation == "discrete")], na.rm = TRUE)

# LP t-test and Bayes factor
ttestLP <- t.test(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")])
difinAUCLP <- cohensD(mean(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], na.rm = FALSE),
                    mean(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")], na.rm = FALSE), 
                    sd(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], na.rm = FALSE), 
                    sd(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")], na.rm = FALSE), 
                    16, 
                    16)

jsq::bttestIS(formula = AUC ~ cbalAsFactor, data = AUCResultsLP, hypothesis = "twoGreater", desc = TRUE)

# compare behavior in LP to optimal behavior (selling just after 2.16)
t.test(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], mu = 2.16)
t.test(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")], mu = 2.16)

cohdeviation_standard <- (mean(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], na.rm = FALSE) - 2.16) / sd(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "standard")], na.rm = FALSE) 
cohdeviation_discrete <- (mean(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")], na.rm = FALSE) - 2.16) / sd(AUCResultsLP$AUC[which(AUCResultsLP$manipulation == "discrete")], na.rm = FALSE) 

# Mean survival curves by condition 
# set up colors for group plots
colHPStandard <- rgb(0, 0, 225, max = 255, alpha = 125)
colHPDiscrete <- rgb(48,213,200, max = 255, alpha = 125)
colHPStandard_transp = rgb(0, 0, 225, max = 255, alpha = 70)
colHPDiscrete_transp <- rgb(48,213,200, max = 255, alpha = 50)

colLPStandard <- rgb(225, 0, 0, max = 255, alpha = 125)
colLPDiscrete <- rgb(255,105,180, max = 255, alpha = 125)
colLPStandard_transp = rgb(225, 0, 0, max = 255, alpha = 70)
colLPDiscrete_transp <- rgb(255,105,180, max = 255, alpha = 50)
colGray = rgb(1/3, 1/3, 1/3)

HPstandardIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "HPstandard")]
HPdiscreteIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "HPdiscrete")]
LPstandardIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "LPstandard")]
LPdiscreteIDs <- AUCResults$IDs[which(AUCResults$cbalAsFactor == "LPdiscrete")]

# Output figure: between-subjects effect in Block 1
# Block 1 group mean survival curves
figName = file.path(figDir, sprintf('n%d_survivalByCondition.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# Save as tiff for paper
# figName = file.path(sprintf('n%d_survivalByCondition.tiff', n))
# tiff(figName, units="in", width=5, height=5, res=300)

# plot group mean survival curves for block 1 (w/ SEM)
survCurve_grpMean_LPStandard = colMeans2(grpSurvCurves[LPstandardIDs, ]) 
survCurve_grpSEM_LPStandard = colSds(grpSurvCurves[LPstandardIDs, ])/sqrt(length(LPstandardIDs))

survCurve_grpMean_LPDiscrete = colMeans2(grpSurvCurves[LPdiscreteIDs, ]) 
survCurve_grpSEM_LPDiscrete = colSds(grpSurvCurves[LPdiscreteIDs, ])/sqrt(length(LPdiscreteIDs))

survCurve_grpMean_HPStandard = colMeans2(grpSurvCurves[HPstandardIDs, ]) 
survCurve_grpSEM_HPStandard = colSds(grpSurvCurves[HPstandardIDs, ])/sqrt(length(HPstandardIDs))

survCurve_grpMean_HPDiscrete = colMeans2(grpSurvCurves[HPdiscreteIDs, ]) 
survCurve_grpSEM_HPDiscrete = colSds(grpSurvCurves[HPdiscreteIDs, ])/sqrt(length(HPdiscreteIDs))

plot('', bty='n', xlab='Elapsed time in trial (s)', xlim=c(0,20), xaxp=c(0, 20, 4),
     ylab='Survival rate', ylim=c(0,1), yaxp=c(0, 1, 2),
     main='Survival curves by condition', las=1, xaxt='n')
axis(side = 1, at=seq(0,20, 10), las=1)

# plot LP
errorBand(xData=scGrid, yData=survCurve_grpMean_LPStandard, yErr=survCurve_grpSEM_LPStandard, bandColor=colLPStandard_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_LPDiscrete, yErr=survCurve_grpSEM_LPDiscrete, bandColor=colLPDiscrete_transp)
lines(scGrid, survCurve_grpMean_LPStandard, type='l', lwd=3, col=colLPStandard)
lines(scGrid, survCurve_grpMean_LPDiscrete, type='l', lwd=3, col=colLPDiscrete)

# plot HP
errorBand(xData=scGrid, yData=survCurve_grpMean_HPStandard, yErr=survCurve_grpSEM_HPStandard, bandColor=colHPStandard_transp)
errorBand(xData=scGrid, yData=survCurve_grpMean_HPDiscrete, yErr=survCurve_grpSEM_HPDiscrete, bandColor=colHPDiscrete_transp)
lines(scGrid, survCurve_grpMean_HPStandard, type='l', lwd=3, col=colHPStandard)
lines(scGrid, survCurve_grpMean_HPDiscrete, type='l', lwd=3, col=colHPDiscrete)

# add a legend
legend('topright', 
       legend=c('HP standard', 'HP instructed', 'LP standard', 'LP instructed'),
       col=c(colHPStandard, colHPDiscrete, colLPStandard, colLPDiscrete), bty='n', lwd=c(2, 2))


# end figure
dev.off()

# Block 1 group AUC
figName = file.path(figDir, sprintf('n%d_survivalBybeeswarm.pdf', n))
pdf(figName, width=6, height=3, pointsize=9)
layout(matrix(1:2, 1, 2), widths=c(0.6, 0.4))

# beeswarm+box plot of group AUC results - between-subject effect for block 1
AUCList = list(
  standardHP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPstandard")],
  discreteHP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "HPdiscrete")],
  standardLP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPstandard")],
  discreteLP = AUCResults$AUC[which(AUCResults$cbalAsFactor == "LPdiscrete")])
boxplot(AUCList, outline=FALSE, boxwex=0.5, col=c(colHPStandard_transp, colHPDiscrete_transp, colLPStandard_transp, colLPDiscrete_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(0,30), yaxp=c(0, 30, 4), ylab='AUC (s)',
        main='AUC')
beeswarm(AUCList, pch=16, col=c(colHPStandard_transp, colHPDiscrete_transp, colLPStandard_transp, colLPDiscrete_transp), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

# end figure
dev.off()

# WTW time series, across both conditions
tGrid = 1:900
wtwCeiling=20 # for comparability across studies/conditions
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

for (this_cbal in c('LPStandard', 'LPDiscrete', 'HPStandard', 'HPDiscrete')) {
  if (this_cbal == "LPStandard"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPstandardIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPstandardIDs, ])/sqrt(length(LPstandardIDs))  
  }
  if (this_cbal == "LPDiscrete"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[LPdiscreteIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[LPdiscreteIDs, ])/sqrt(length(LPdiscreteIDs))  
  }
  if (this_cbal == "HPStandard"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[HPstandardIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[HPstandardIDs, ])/sqrt(length(HPstandardIDs))  
  }
  if (this_cbal == "HPDiscrete"){
    wtwTS_grpMean[[this_cbal]] = colMeans2(wtwTS_results[HPdiscreteIDs, ])
    wtwTS_grpSEM[[this_cbal]] = colSds(wtwTS_results[HPdiscreteIDs, ])/sqrt(length(HPdiscreteIDs))  
  }
}

figName = file.path(figDir, sprintf('n%d_wtwByConditionLP.pdf', n))
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
       legend=c('LP Standard', 'LP instructed'),
       col=c(colLPStandard, colLPDiscrete), bty='n', lwd=c(2, 2))
dev.off()

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
errorBand(xData=1:900, yData=wtwTS_grpMean$HPStandard, 
          yErr=wtwTS_grpSEM$HPStandard, bandColor=colHPStandard_transp)
errorBand(xData=1:900, yData=wtwTS_grpMean$HPDiscrete, 
          yErr=wtwTS_grpSEM$HPDiscrete, bandColor=colHPDiscrete_transp)
# add means
lines(1:900, wtwTS_grpMean$HPStandard, col=colHPStandard, type='l', lwd=2, lty='solid')
lines(1:900, wtwTS_grpMean$HPDiscrete, col=colHPDiscrete, type='l', lwd=2, lty='solid')

# add a legend
legend('topright', 
       legend=c('HP standard', 'HP instructed'),
       col=c(colHPStandard, colHPDiscrete), bty='n', lwd=c(2, 2))
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

dataSummaryHP <- subset(dataSummary, dataSummary$cbalAsFactor == "HPdiscrete" | dataSummary$cbalAsFactor == "HPstandard")
dataSummaryLP <- subset(dataSummary, dataSummary$cbalAsFactor == "LPdiscrete" | dataSummary$cbalAsFactor == "LPstandard")

# means
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")])
mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")])

# Bootstrap confidence interval for HP
CIstandardHPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")])
CIdiscreteHPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")])

# Bootstrap confidence interval for LP
CIstandardLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")])
CIdiscreteLPBoot <- calcCIBoot(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")])

# Anova: AUC means by timing condition and manipulation (discrete vs standard)
wtw_trendanova <- aov(wtw_trend ~ timingCond * manipulation, data = dataSummary)
summary(wtw_trendanova)
etaSquared(wtw_trendanova)

# HP t-test and Bayes factor
ttestHP <- t.test(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")], dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")])
difintrendHP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")], na.rm = FALSE),
                        mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")], na.rm = FALSE), 
                        16, 
                        16)

jsq::bttestIS(formula = wtw_trend ~ cbalAsFactor, data = dataSummaryHP, hypothesis = "oneGreater", desc = TRUE)
# HP discrete is higher than HP standard

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")], dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")])
difintrendLP <- cohensD(mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")], na.rm = FALSE),
                        mean(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")], na.rm = FALSE), 
                        sd(dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")], na.rm = FALSE), 
                        16, 
                        16)

jsq::bttestIS(formula = wtw_trend ~ cbalAsFactor, data = dataSummaryLP, hypothesis = "twoGreater", desc = TRUE)
# LP discrete is less than LP standard

figName = file.path(figDir, sprintf('indivs_n%d_coefficients.pdf', n)) 
pdf(figName, pointsize=14)

coefficientsList = list(
  standardHP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPstandard")],
  discreteHP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "HPdiscrete")],
  standardLP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPstandard")],
  discreteLP = dataSummary$wtw_trend[which(dataSummary$cbalAsFactor == "LPdiscrete")])

boxplot(coefficientsList, outline=FALSE, boxwex=0.5, col=c(colHPStandard_transp, colHPDiscrete_transp, colLPStandard_transp, colLPDiscrete_transp),
        frame.plot=FALSE, boxlty=c('solid', 'dashed'), whisklty='blank', staplelty='blank',
        boxcol=colGray, medcol=colGray,
        xlab='Manipulation', ylim=c(-0.05,0.05), ylab='Coefficient',
        main='Coefficient: wtw-trend')
abline(h = 0, lty = 2)
beeswarm(coefficientsList, pch=16, col=c(colHPStandard_transp, colHPDiscrete_transp, colLPStandard_transp, colLPDiscrete_transp), bty='n', cex=0.9, spacing=0.9, method='compactswarm',
         add=TRUE, axes=FALSE)

dev.off()


# Self-reported ideal maximum wait times
dataSummary$gut_explicit <- as.numeric(dataSummary$gut_explicit)
table(dataSummary$cbalAsFactor) # 16 participants per group 
describeBy(dataSummary$gut_explicit, dataSummary$cbalAsFactor) # descriptive information 

dataSummaryHP <- subset(dataSummary, dataSummary$cbalAsFactor == "HPstandard" | dataSummary$cbalAsFactor == "HPdiscrete")
dataSummaryLP <- subset(dataSummary, dataSummary$cbalAsFactor == "LPstandard" | dataSummary$cbalAsFactor == "LPdiscrete")

# Find the confidence interval (set to 95%) for HP
# Using bootstrapping
CIstandardHPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryHP$gut_explicit[which(dataSummaryHP$manipulation == "standard")])))
CIdiscreteHPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryHP$gut_explicit[which(dataSummaryHP$manipulation == "discrete")])))

# Find the confidence interval (set to 95%) for LP
# Using bootstrapping
CIstandardLPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryLP$gut_explicit[which(dataSummaryLP$manipulation == "standard")])))
CIdiscreteLPBoot <- calcCIBoot(as.numeric(na.omit(dataSummaryLP$gut_explicit[which(dataSummaryLP$manipulation == "discrete")])))

# Anova: gut means by timing condition and manipulation (discrete vs standard)
gutanova <- aov(gut_explicit ~ timingCond * manipulation, data = dataSummary)
summary(gutanova)
etaSquared(gutanova)

# HP t-test and Bayes factor
ttestHP <- t.test(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPstandard")], dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPdiscrete")])
difinAUCHP <- cohensD(mean(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPstandard")], na.rm = FALSE),
                      mean(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPdiscrete")], na.rm = FALSE), 
                      sd(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPstandard")], na.rm = FALSE), 
                      sd(dataSummaryHP$gut_explicit[which(dataSummaryHP$cbalAsFactor == "HPdiscrete")], na.rm = FALSE), 
                      20, 
                      20)

jsq::bttestIS(formula = gut_explicit ~ cbalAsFactor, data = dataSummaryHP, hypothesis = "oneGreater", desc = TRUE)

# LP t-test and Bayes factor
ttestLP <- t.test(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPstandard")], dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPdiscrete")])
difinAUCLP <- cohensD(mean(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPstandard")], na.rm = FALSE),
                      mean(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPdiscrete")], na.rm = FALSE), 
                      sd(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPstandard")], na.rm = FALSE), 
                      sd(dataSummaryLP$gut_explicit[which(dataSummaryLP$cbalAsFactor == "LPdiscrete")], na.rm = FALSE), 
                      20, 
                      22)

jsq::bttestIS(formula = gut_explicit ~ cbalAsFactor, data = dataSummaryLP, hypothesis = "twoGreater", desc = TRUE)
