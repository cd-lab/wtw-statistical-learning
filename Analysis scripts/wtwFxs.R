# wtwFxs.R
# helper functions for analysis of WTW experiments. 

library('tcltk')
library('survival')

# Find the (parametric) 95% confidence interval around a mean
calcCI <- function(AUCvector, nGroup){
  mean <- mean(AUCvector, na.rm = TRUE)
  sd <- sd(AUCvector, na.rm = TRUE)
  standard_error <- sd / sqrt(nGroup)
  
  # Calculating lower bound and upper bound
  lower_bound <- mean - 1.96 * standard_error
  upper_bound <- mean + 1.96 * standard_error
  
  bothCIs <- list(lower_bound, upper_bound)
  return(bothCIs)
}

# Find the (parametric) 95% confidence interval around a mean
calcCIBoot <- function(AUCvector){
  
  set.seed(4444) # set a seed for replicability
  b1 <- boot(AUCvector,function(u,i) mean(u[i]),R=10000)
  cis <- boot.ci(b1,type=c("norm","basic","perc"))
 
  # Lower bound and upper bound
  lower_bound <- cis$normal[2]
  upper_bound <- cis$normal[3]
  
  bothCIs <- list(lower_bound, upper_bound)
  return(bothCIs)
}

# calculate Cohen's d for between-subject designs
cohensD <- function(m1, m2, sd1, sd2, n1, n2) {
  (m1 - m2) / (sqrt(((n1-1) * sd1^2 + (n2-1) * sd2^2) / (n1+n2 - 2))) 
}

# a function to help with plotting symmetrical error bands
errorBand <- function(xData, yData, yErr, bandColor) {
  # will plot yData +/- yErr as a function of xData
  polygon(x=c(xData, rev(xData)), 
          y=c(yData + yErr, rev(yData - yErr)),
          col=bandColor, border=NA)
}

# plot the distribution of scheduled delays (ECDF)
scheduledDelaysECDF <- function(blockData, study, id, dataSummary) {
  # depending on study, assign the delays 
  if (study == "2a"){
    bkDelays = as.numeric(blockData$designatedWait)
    if (blockData$blockNum[1] == 1){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 1, dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    } else if (blockData$blockNum[1] == 2){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 2, dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
    }
  } else if (study == "2b"){
    bkDelays = as.numeric(blockData$n_scheduled_delay)
    if (blockData$n_block[1] == 1){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 1, dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    } else if (blockData$n_block[1] == 2){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 2, dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
    }
  } else if ( study == "3a" | study == "1"){
    bkDelays = as.numeric(blockData$designatedWait)
    title <- sprintf('%s, Condition: %s', id, dataSummary$cbalAsFactor[which(dataSummary$IDs == id)])
  } else if (study == "2b"){
    bkDelays = as.numeric(blockData$ScheduledDelay)
    title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
  } else if ( study == "3b"){
    bkDelays = as.numeric(blockData$n_scheduled_delay)
    title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
  }
  
  # empirical cumulative distribution of scheduled delays
  fn <- ecdf(bkDelays)
  
  plot(fn, main = title, bty='n',
       xlab='Scheduled delay (s)', ylab='Cumulative proportion', xlim=c(0,32))
}

# plot the distribution of scheduled delays (ACF)
scheduledDelaysACF <- function(blockData, study, id, dataSummary) {
  # depending on study, assign the delays 
  if (study == "2a"){
    bkDelays = as.numeric(blockData$designatedWait)
    if (blockData$blockNum[1] == 1){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 1, dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    } else if (blockData$blockNum[1] == 2){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 2, dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
    }
  } else if (study == "2b"){
    bkDelays = as.numeric(blockData$n_scheduled_delay)
    if (blockData$n_block[1] == 1){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 1, dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    } else if (blockData$n_block[1] == 2){
      title <- sprintf('%s, block: %d, Timing condition: %s', id, 2, dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
    }
  } else if ( study == "3a" | study == "1"){
    bkDelays = as.numeric(blockData$designatedWait)
    title <- sprintf('%s, Condition: %s', id, dataSummary$cbalAsFactor[which(dataSummary$IDs == id)])
  } else if (study == "2b"){
    bkDelays = as.numeric(blockData$ScheduledDelay)
    title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
  } else if ( study == "3b"){
    bkDelays = as.numeric(blockData$n_scheduled_delay)
    title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
  }
  
  # empirical cumulative distribution of scheduled delays
  fn <- ecdf(bkDelays)

  acfOutput <- acf(bkDelays, lag.max=20, main = title)
}

# plot post-outcome response times
outcomeRT <- function(blockData, study, id, dataSummary) {
  # depending on study, assign the delays 
  if (study == "2a"){
    rt_all = as.numeric(na.omit(blockData$RT))
    Expired <- TRUE
  } else if (study == "2b"){
    rt_all = as.numeric(na.omit(blockData$RT))
    if (blockData$n_block[1] == 1){
      expired <- dataSummary$b1_prop_expired[which(dataSummary$IDs == id)]
    } else if (blockData$n_block[1] == 2){
      expired <- dataSummary$b2_prop_expired[which(dataSummary$IDs == id)]
    }
    Expired <- TRUE
  } else if ( study == "3a" | study == "1" ){
    rt_all = as.numeric(na.omit(blockData$RT))
    Expired <- FALSE
  } else if ( study == "3b"){
    rt_all = as.numeric(na.omit(blockData$RT))
    Expired <- FALSE
  }
  
  rtCeil = 2
  
  medianStr = sprintf('median = %1.2f', median(rt_all, na.rm = TRUE))
  
  
  # overall ecdf
  if (Expired){
    expired <- round(as.numeric(dataSummary$b1_prop_expired[which(dataSummary$IDs == id)]), 2)
    titleStr = sprintf('All RTs, %s\nProportion expired: %s', medianStr, expired)
  } else {
    outliers = rev(sort(round(rt_all[rt_all > rtCeil], digits=1)))
    outlierStr = 'none'
    if (length(outliers)>0) {
      outlierStr = paste(outliers, collapse=', ')
    }
    titleStr = sprintf('All RTs, %s\nOutliers: %s', medianStr, outlierStr)
  }
  
  plot(ecdf(rt_all), main=titleStr, bty='n', xlim=c(0,rtCeil), ylim=c(0,1),
       xlab='Outcome RT (s)', ylab='Cumulative proportion')
}

# plot single-participant trialwise responses in detail
trialPlots <- function(blockData, study, id, dataSummary) {
  
  if (study == "2a"){
    waitDuration = blockData$latency
    trialDelayScheduled = blockData$designatedWait
    tMax <- max(as.numeric(trialDelayScheduled))
    blockBoundary = which(blockData$blockNum ==2)[1] - 0.5
    title <- sprintf('%s, block 1: %s, block 1: %s', id, dataSummary$b1_timingCond[which(dataSummary$IDs == id)], dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
    blockBoundaryIndex <- TRUE
  } else if (study == "2b"){
      waitDuration = blockData$n_time_waited
      trialDelayScheduled = blockData$n_scheduled_delay
      tMax <- max(as.numeric(trialDelayScheduled))
      blockBoundary = which(blockData$n_block ==2)[1] - 0.5
      title <- sprintf('%s, block 1: %s, block 1: %s', id, dataSummary$b1_timingCond[which(dataSummary$IDs == id)], dataSummary$b2_timingCond[which(dataSummary$IDs == id)])
      blockBoundaryIndex <- TRUE
  } else if (study == "3a" | study == "1"){
      waitDuration = blockData$latency
      trialDelayScheduled = blockData$designatedWait
      tMax <- max(as.numeric(trialDelayScheduled))
      title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
      blockBoundaryIndex <- FALSE
  } else if (study == "3b"){
      waitDuration = blockData$n_time_waited
      trialDelayScheduled = blockData$n_scheduled_delay
      tMax <- max(as.numeric(trialDelayScheduled))
      title <- sprintf('%s, Timing condition: %s', id, dataSummary$timingCond[which(dataSummary$IDs == id)])
      blockBoundaryIndex <- FALSE
  } 
  
  # trial indexing vector
  idxQuit = blockData$idxQuit # 1 refers to a quit event
  # values to be plotted
  nTrials = nrow(blockData)
  trialNumber = 1:nTrials # cumulative trial number
  
  # plot the axes
  plot(1, type='n', xlim=c(1,nTrials), ylim=c(0,tMax), bty='n',
       xlab='Trial', ylab='Trial duration (s)', main= title)
  # plot block boundary (if needed)
  if (blockBoundaryIndex){
    lines(c(blockBoundary, blockBoundary), c(-1, tMax), type='l', col='gray', lwd=5)
  }
  # plot the obtained outcomes
  thisIdx = !idxQuit
  lines(trialNumber[thisIdx], waitDuration[thisIdx], type='o', col='blue', lwd=2, pch=16)
  # plot quit trials
  thisIdx = as.logical(idxQuit)
  lines(trialNumber[thisIdx], waitDuration[thisIdx], type='o', col='black', lwd=2, pch=17)
  # plot the scheduled times of non-obtained rewards
  lines(trialNumber[thisIdx], trialDelayScheduled[thisIdx], type='p', col='blue', pch=1)
  # add legend
  legend("topright", 
         legend=c('Quit', 'Obtained reward', 'Missed reward'),
         col=c('black', 'blue', 'blue'),
         pch=c(17, 16, 1))
}

# calculate kaplan-meier and area under the curve
kmsc <- function(blockData, study, id, dataSummary, scGrid) {
  
  if ( study == "1"){
    title <- sprintf('%s\n Condition: %s', dataSummary$IDs[which(dataSummary$IDs == id)], dataSummary$cbalAsFactor[which(dataSummary$IDs == id)])
    waitDuration = as.numeric(blockData$latency)
    tMax <- 30
  } else if ( study == "2a"){
    title <- sprintf('%s, Timing condition block 1: %s', dataSummary$IDs[which(dataSummary$IDs == id)], dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    waitDuration = as.numeric(blockData$latency)
    tMax <- 20
  } else if ( study == "2b"){
    title <- sprintf('%s\n Timing condition block 1: %s', dataSummary$IDs[which(dataSummary$IDs == id)], dataSummary$b1_timingCond[which(dataSummary$IDs == id)])
    waitDuration = as.numeric(blockData$n_time_waited)
    tMax <- 20
  } else if ( study == "3a"){
    title <- sprintf('%s\n Condition: %s', dataSummary$IDs[which(dataSummary$IDs == id)], dataSummary$cbalAsFactor[which(dataSummary$IDs == id)])
    waitDuration = as.numeric(blockData$latency)
    tMax <- 20
  } else if ( study == "3b"){
    title <- sprintf('%s\n Condition: %s', dataSummary$IDs[which(dataSummary$IDs == id)], dataSummary$cbalAsFactor[which(dataSummary$IDs == id)])
    waitDuration = as.numeric(blockData$n_time_waited)
    tMax <- 20
  }
  
  # pull data from derived columns
  idxQuit = blockData$idxQuit
  # fit the survival function
  kmfit <- survfit(Surv(waitDuration, idxQuit, type='right') ~ 1, 
                   type='kaplan-meier', conf.type='none', start.time=0, se.fit=FALSE)
  # extract elements of the survival curve object (?survfit.object)
  kmT = kmfit$time
  kmF = kmfit$surv
  # add a point at zero
  kmT = c(0, kmT)
  kmF = c(1, kmF)
  # keep only points up through tMax
  keepIdx = kmT<=tMax
  kmT <- kmT[keepIdx]
  kmF <- kmF[keepIdx]
  # extend the last value to exactly tMax
  kmT <- c(kmT, tMax)
  kmF <- c(kmF, tail(kmF,1))
  # calculate auc
  auc <- sum(diff(kmT) * head(kmF,-1))
  # plot if requested
  plot(kmT, kmF, type='s', frame.plot=FALSE, xlab='Delay (s)', ylab='Survival rate',
       main=title, ylim=c(0,1), xlim=c(0,tMax))
  # put the survival curve on a standard grid
  kmOnGrid = vector()
  for (gIdx in 1:length(scGrid)) {
    g = scGrid[gIdx]
    # use the last point where t is less than or equal to the current grid value
    kmOnGrid[gIdx] = kmF[max(which(kmT<=g))]
  }
  return(list(kmT=kmT, kmF=kmF, auc=auc, kmOnGrid=kmOnGrid))
}


# willingness to wait time-series
wtwTS <- function(blockData, tGrid, wtwCeiling) {
  
  if ( study == "2a"){
    blockData$ResponseClockTime = as.numeric(blockData$outcomeTime) 
    waitDuration = as.numeric(blockData$latency)
    idxQuit = as.logical(blockData$idxQuit)
  } else if ( study == "2b"){
    blockData$ResponseClockTime = as.numeric(blockData$n_sell_time) 
    waitDuration = as.numeric(blockData$n_time_waited)
    idxQuit = as.logical(blockData$idxQuit)
  } else if ( study == "3a" | study == "1"){
    blockData$ResponseClockTime = as.numeric(blockData$outcomeTime) 
    waitDuration = as.numeric(blockData$latency)
    idxQuit = as.logical(blockData$idxQuit)
  } else if ( study == "3b"){
    blockData$ResponseClockTime = as.numeric(blockData$n_sell_time) 
    waitDuration = as.numeric(blockData$n_time_waited)
    idxQuit = as.logical(blockData$idxQuit)
  }
  trialWTW = numeric(length = nrow(blockData)) # initialize the per-trial estimate of WTW
  ### find the longest time waited up through the first quit trial
  #   (or, if there were no quit trials, the longest time waited at all)
  #   that will be the WTW estimate for all trials prior to the first quit
  firstQuit = which(idxQuit)[1]
  if (is.na(firstQuit)) {firstQuit = nrow(blockData)} # if no quit, set to the last trial
  currentWTW = max(waitDuration[1:firstQuit])
  thisTrialIdx = firstQuit - 1
  trialWTW[1:thisTrialIdx] = currentWTW
  ### iterate through the remaining trials, updating currentWTW
  while (thisTrialIdx < nrow(blockData)) {
    thisTrialIdx = thisTrialIdx + 1
    if (idxQuit[thisTrialIdx]) {currentWTW = waitDuration[thisTrialIdx]}
    else {currentWTW = max(currentWTW, waitDuration[thisTrialIdx])}
    trialWTW[thisTrialIdx] = currentWTW
  }
  ### impose a ceiling value, since trial durations exceeding some value may be infrequent
  trialWTW = pmin(trialWTW, wtwCeiling)
  ### convert from per-trial to per-second over the course of the block
  timeWTW = numeric(length = length(tGrid)) # initialize output
  binStartIdx = 1
  thisTrialIdx = 0
  while (thisTrialIdx < nrow(blockData)) {
    thisTrialIdx = thisTrialIdx + 1
    binEndTime = blockData$ResponseClockTime[thisTrialIdx]
    binEndIdx = max(which(tGrid < binEndTime)) # last grid point that falls within this trial
    # this runs into an error when the binEndTime is less than 1, so we put a catch in here: 
    if (binEndIdx == -Inf){
      binEndIdx <- 1
    }
    timeWTW[binStartIdx:binEndIdx] = trialWTW[thisTrialIdx]
    binStartIdx = binEndIdx + 1
  }
  # extend the final value to the end of the vector
  timeWTW[binStartIdx:length(timeWTW)] = trialWTW[thisTrialIdx]
  
  return(timeWTW) 
}


# differences: Where should 2.8 seconds stretch to? 
# How are early quit trials treated?

