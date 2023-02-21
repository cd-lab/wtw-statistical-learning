/*
 *
 PExample plugin template
 */

jsPsych.plugins["wtw-standard-expire-block"] = (function(){

  var plugin = {};

  plugin.info = {
    name: "wtw-standard-expire-block",
    description: 'Plugin for run a WTW trial.',
    parameters: {
      iti:{
        type: jsPsych.plugins.parameterType.INT,
        description: 'Length of time (ms) between trials.',
      },
      feedback_time: {
        type: jsPsych.plugins.parameterType.INT,
        default: 500,
        description: 'Length of time (ms) to display the feedback'
      },
      maturation_value: {
        type: jsPsych.plugins.parameterType.INT,
        description: 'Maturation value'
      },
      condition: {
        type: jsPsych.plugins.parameterType.STRING,
        default: "LP",
        description: 'Task condition'
      },
      block_time: {
        type: jsPsych.plugins.parameterType.INT,
        description: 'Length of time (ms) of a block'
      },
      check_interval: {
        type: jsPsych.plugins.parameterType.INT,
        default: 500,
        description: 'Time interval to check the keypress'
      },
      initialEarnings: {
        type: jsPsych.plugins.parameterType.INT,
        default: 0,
        description: 'Earnings earned from previous blocks'
      },
      cb: {
        type: jsPsych.plugins.parameterType.STRING,
        default: "standard",
        description: "Counterbalance group"
      }
    }
  }

  plugin.trial = function(display_element, trial){
    /********************************************************************/
    /* helper functions */
    /********************************************************************/
    // functions to kill the handlers and the listener
    // function to display stimuli

    var kill_listeners = function(listener_id){
      if(listener_id !== 'undefined'){
        jsPsych.pluginAPI.cancelAllKeyboardResponses(listener_id)
      }
    }
    var kill_timers = function(){
      for (var i = 0; i < timeoutHandlers.length; i++) {
        clearTimeout(timeoutHandlers[i])
      }
    }

    var display_stim = function(stim_name){
      // default setting
      var tokenColor = "grey"
      var tokenBorderColor = "grey"
      var soldText = ""
      var centText = ""
      var centTextRight = 55 + "px"
      var expiredText = ""


      // determine token color
      var LP_immature_color = "green" // dark purple
      var LP_mature_color = "blue" // blue

      if(stim_name == "LP_immature_token"){
        tokenColor = LP_immature_color
        tokenBorderColor = "white"
        centText = "0&cent"
        centTextRight = 80 + "px"
      }

      if(stim_name == "LP_mature_token"){
        tokenColor = LP_mature_color
        tokenBorderColor = "white"
        centText = trial.maturation_value + "&cent"
        centTextRight = 55 + "px"
      }

      if(stim_name == "LP_immature_sold"){
        tokenColor = LP_immature_color
        tokenBorderColor = "white"
        soldText = "SOLD"
        centText = "0&cent"
        centTextRight = 80 + "px"
      }

      if(stim_name == "LP_mature_sold"){
        tokenColor = LP_mature_color
        tokenBorderColor = "white"
        centText = trial.maturation_value + "&cent"
        soldText = "SOLD"
        centTextRight = 55 + "px"
      }

      if(stim_name == "expired"){
        tokenColor = "blue"
        tokenBorderColor = "white"
        centText = trial.maturation_value + "&cent"
        expiredText = "EXPIRED"
        centTextRight = 55 + "px"
      }

      // update stimulus properties based on the input
      var token = document.getElementById("jspsych-wtw-token")
      token.style.background = tokenColor
      token.style.borderColor = tokenBorderColor

      var sold_text = document.getElementById("jspsych-wtw-sold-text")
      sold_text.innerHTML = soldText

      var expired_text = document.getElementById("jspsych-wtw-expired-text")
      expired_text.innerHTML = expiredText

      var cent_text = document.getElementById("jspsych-wtw-cent-text")
      cent_text.innerHTML = centText

      // update the total earnings
      var total_text = document.getElementById("jspsych-wtw-total")
      var earningsCountToDisplay = (Math.round(earningsCount) / 100).toFixed(2);
      total_text.innerHTML  = "Earned: $" + earningsCountToDisplay
      //console.log(earningsCount)
      //console.log(earningsCountToDisplay)

    }

    var updateBar = function(){
      // read the current time
      var current_time = new Date()
      // update the progress bar
      var elapsedTime_trial =  current_time.getTime() - current_trial_start_time.getTime()
      //console.log(current_trial_start_time.getTime())
      var width = elapsedTime_trial / 32000 * 100
      elem = document.getElementById("jspsych-wtw-bar")
      elem.style.width = Math.min(Math.max(2*width, 1), 200) + "%";
      //console.log(width)
    }

    var updateTime = function(){
      // read the current time
      var current_time = new Date()
      // update time
      var elapsedTime_block =  current_time.getTime() - block_start_time.getTime()
      var timeinSeconds = parseInt((trial.block_time + 1000 - elapsedTime_block) / 1000)
      var timeInNewFormat = new Date(timeinSeconds * 1000).toISOString().substr(11, 8);
      var minSec = timeInNewFormat.slice(3,8)
      var total_time = document.getElementById("jspsych-wtw-left-time")
      total_time.innerHTML  = "Time left: " + minSec

    }

    var end_of_trial = function(){
      kill_listeners(keyboardListener)
      kill_listeners(keyboardListenerMatured)
      kill_timers(timeoutHandlers)

      if(new Date() - block_start_time < trial.block_time){
        unit_trial()
      }else{
        terminate_block()
      }
    }

    var terminate_block = function(){
      document.documentElement.removeEventListener('fullscreenchange', log_fullscreenchang)
      console.log(screenEnterTime)
      console.log(screenExitTime)
      kill_listeners(keyboardListener)
      kill_listeners(keyboardListenerMatured)
      kill_timers(timeoutHandlers)
      clearInterval(barHandler)
      clearInterval(timeHandler)

      display_element.innerHTML = ""
      trial_data = {
        "trialIdx": trialIdx,
        "condition": condition,
        "scheduledDelay": scheduledDelay,
        "trialStartTime": trialStartTime,
        "RT": RT,
        "trialEarnings": trialEarnings,
        "totalEarnings": totalEarnings,
        "timeWaited": timeWaited,
        "sellTime": sellTime,
        "rewardedTime": rewardedTime,
        "screenExitTime": screenExitTime,
        "screenEnterTime": screenEnterTime

      }
      jsPsych.finishTrial(trial_data)
    }



    var callback = function(sell_timing){
      kill_timers()
      kill_listeners(keyboardListener)
      kill_listeners(keyboardListenerMatured)

      var empty_bar = document.getElementById("jspsych-wtw-empty-progress")
      empty_bar.style.background = "grey"

      // update the global variables, trialCount and earningCount
      if(sell_timing == "immature"){
        earningsCount += 0
        console.log()
      }else{
        earningsCount += trial.maturation_value
      }

      // save action-dependent data
      var current_time = new Date()
      if(sell_timing == "immature"){
        trialEarnings.push(0)
      }
      else{
        trialEarnings.push(trial.maturation_value)
      }
      totalEarnings.push(earningsCount)
      if(sell_timing == "immature"){
        RT.push(Number.NaN)
      }
      else{
        RT.push(current_time.getTime() - current_rewarded_time.getTime())
      }
      sellTime.push(current_time.getTime() - block_start_time.getTime())
      timeWaited.push(current_time.getTime() - current_trial_start_time.getTime())
      if(sell_timing == "immature"){
        rewardedTime.push(Number.NaN)
      }
      else{
        rewardedTime.push(current_rewarded_time.getTime() - block_start_time.getTime())
      }

      // show the feedback
      if(sell_timing == "immature"){
        display_stim(trial.condition + "_immature_sold")
      }
      else{
        display_stim(trial.condition + "_mature_sold")
      }

      // clear the screen for the iti period
      var handle_iti = jsPsych.pluginAPI.setTimeout(function(){
        display_stim("iti")
      }, trial.feedback_time); timeoutHandlers.push(handle_iti)

      // exit the trial
      var handle_end_of_trial = jsPsych.pluginAPI.setTimeout(function(){
        end_of_trial(sell_timing)
      },
        trial.feedback_time + trial.iti); timeoutHandlers.push(handle_end_of_trial)
    }

    /**********************/
    /* callback functions */
    /**********************/
    var keypressCheck = function(){
    /* Create a keyboardListener which will terminate itself if
    /(1) the spacebar is pressed (if so, sell the token, show feedback, save data and move to the next trial)
    /(2) and the token matures (if so, change the token color, update the global variable rewardedTime, and trigger keypressCheckMatured)
    */

      keyboardListener = jsPsych.pluginAPI.getKeyboardResponse({
        callback_function: function () {
          callback("immature")
        },
        valid_responses: [32],
        rt_method: 'performance',
        persist: false
      })

      // if the token matures
      var handle_token_mature = jsPsych.pluginAPI.setTimeout(function(){
        kill_listeners(keyboardListener)
        kill_timers()
        var current_time = new Date()

        display_stim(trial.condition + "_mature_token")


        // save rewarded time
        current_rewarded_time = current_time

        // start to check keypress again
        var keyboardListenerMatured = jsPsych.pluginAPI.getKeyboardResponse({
          callback_function: function(){
            callback("mature")
          },
          valid_responses: [32],
          rt_method: 'performance',
          persist: false
        })

        var handleExpired = jsPsych.pluginAPI.setTimeout(function(){


          if (keepGoing == "yes"){
            kill_listeners(keyboardListener)
            kill_listeners(keyboardListenerMatured)


            display_stim("expired")
            var current_time = new Date()

            var elapsedTime_trial =  current_time.getTime() - current_trial_start_time.getTime()

            // update variables
            earningsCount = earningsCount
            trialEarnings.push(0)
            totalEarnings.push(earningsCount)
            RT.push("NA_expired")
            sellTime.push("NA_expired")
            timeWaited.push(current_time.getTime() - current_trial_start_time.getTime())
            rewardedTime.push(current_rewarded_time.getTime() - block_start_time.getTime())

            // clear the screen for the iti period
            var handle_iti = jsPsych.pluginAPI.setTimeout(function(){
              display_stim("iti")
            }, trial.feedback_time); timeoutHandlers.push(handle_iti)

            // exit the trial
            var handle_end_of_trial = jsPsych.pluginAPI.setTimeout(function(){
              end_of_trial("mature")
            },
            trial.feedback_time + trial.iti); timeoutHandlers.push(handle_end_of_trial)
          }
        }, 1000); timeoutHandlers.push(handleExpired)

      }, currentDelay); timeoutHandlers.push(handle_token_mature)
    }

    /**********************************************************************/
    /* function to run a unit trial  */
    /**********************************************************************/
    var unit_trial = function(){

      keepGoing = "yes"

      // update the global variable, current_trial_start_time
      current_trial_start_time = new Date()
      trialStartTime.push(current_trial_start_time.getTime() - block_start_time.getTime())

      // update the global variable, current delay
      currentDelay = scheduledDelays[trialCount]
      //console.log(currentDelay/1000)

      // save input data
      scheduledDelay.push(scheduledDelays[trialCount])
      condition.push(trial.condition)
      trialIdx.push(trialCount + 1)

      jsPsych.pluginAPI.setTimeout(function(){
        var empty_bar = document.getElementById("jspsych-wtw-empty-progress")
        empty_bar.style.background = "transparent"
      }, 101);

      // update the global variable, trialCount (I keep it global since I can't pass arguments to the callback functions)
      trialCount += 1
      // console.log(trialCount)

      // update the stimuli
      display_stim(trial.condition+"_immature_token")

      // start check the keypress
      keypressCheck()


    }


    /**********************************************************************/
    /* randomize delay sequence (LP) */
    /**********************************************************************/
    //  we always begin with an empty sequence
    var seq = []
    var maxTrials = 500 // this should be higher in the real task
    const possDelays = [0.264713485566566, 0.661783713916415,
                        1.257389056441189, 2.150797070228350,
                        3.490909090909091, 5.501077121930202,
                        8.516329168461869, 13.039207238259371,
                        19.823524342955622, 30.000000000000000]

    // always 10 options, so we specify manually,
    // given that jsPsych starts counting at 0, we specify values ranging from 0 to 9
    const avail = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    // only balance 1st-order transitions (length 2)
    // this introduces a weak temporal autocorrelation structure (autocorrelation from balancing 0th-order transitions is much larger)
    // length of subsequence to balance (hardcoded)
    const subLength = 2;

    const candidates = avail;
    const nCand = candidates.length;

    // initialize costs to zero
    var cost = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    // put all of this into a loop
    for (let t = 0; t <= maxTrials; t++){

      // loop over candidates
      // if sequence is longer or equal to sublength, we adjust the costs
      // if not, the cost remain equal to 0 and we choose randomly
      if (seq.length >= subLength) {
        for (let i = 0; i < nCand; i++){
          var provisSeq = seq.concat(i)
          var newSubseq = provisSeq.slice(provisSeq.length-2, provisSeq.length)
          var doubles = []
          for (let s = 0; s < seq.length-1; s++){
              const firstValue = seq[s]
              const secondValue = seq[s+1]
              doubles[s] = "" + firstValue + secondValue
          }
          var firstValueSubseq = newSubseq[0]
          var secondValueSubseq = newSubseq[1]
          var newSubseqString = "" + firstValueSubseq + secondValueSubseq

          var indexes = [];
          for (let index = 0; index < doubles.length; index++) {
            if (doubles[index] === newSubseqString) {
              indexes.push(index);
            }
          }
          indexes.length
          cost[i] = indexes.length
        }
      } // close loop over candidates

      // find indexes of minimum values in cost array
      // (function from: https://www.tutorialspoint.com/find-indexes-of-multiple-minimum-value-in-an-array-in-javascript)
      const minArray = cost => {
         var min = cost.reduce((acc, val) => Math.min(acc, val), Infinity);
         var res = [];
         for(let f = 0; f < cost.length; f++){
            if(cost[f] !== min){
               continue;
            };
            res.push(f);
         };
         return res;
      };
      //console.log(minArray(cost));


      // next step: take the length of all indexes that are the minimum
      // and pick one randomly

      var randomElement = Math.floor(Math.random() * cost.length);
      //console.log(randomElement)

      // use that random value to subset a candidate
      var nextDelayIndex = candidates[randomElement]
      var nextDelay = possDelays[nextDelayIndex]
      var nextDelayInMs = nextDelay * 1000

      seq = seq.concat(nextDelayInMs)

    }; //close for loop over trials

    //console.log(seq)
    var LPDelays = seq


    /**********************************************************************/
    /* main */
    /**********************************************************************/
    var timeoutHandlers = [] // handlers can be defined locally, yet will be pushed to the global level so that they can be killed by the function
    var keyboardListener = new Object // keyboardListener is defined directly on the global level and could be killed by the function, kill_listeners
    var keyboardListenerMatured = new Object
    var globalQuitKeyListener = jsPsych.pluginAPI.getKeyboardResponse({
          callback_function: function(){
            terminate_block()
          },
          valid_responses: [27],
          rt_method: 'performance',
          persist: true
    })

    // trial-wise variables
    var currentDelay;
    var current_rewarded_time;
    var current_trial_start_time;
    //  time marker
    var block_start_time = new Date()
    // trial counter
    var trialCount = 0
    // scheduled delays
    if(trial.condition == "HP"){
      scheduledDelays = HPDelays
    }else{
      scheduledDelays = LPDelays
    }
    var earningsCount = trial.initialEarnings

    // initialize the output
    var scheduledDelay = []
    var condition = []
    var trialIdx = []
    var RT = []
    var trialEarnings = []
    var totalEarnings = []
    var timeWaited = []
    var trialStartTime = []
    var sellTime = []
    var rewardedTime = []
    var screenEnterTime = []
    var screenExitTime = []
    var keepGoing = []



    // display stimuli: wtw-token, wtw-cent-text, wtw-sold-text, wtw-total, wtw-bar, ....
    // properties of these stimuli can be updated later
    if (cb == "standard"){
      display_element.innerHTML =
      `<div class="container" id="jspsych-wtw-content">
          <div id="jspsych-wtw-token"></div>
          <div id = 'jspsych-wtw-cent-text'></div>
          <div id = jspsych-wtw-sold-text></div>
          <div id = jspsych-wtw-ready-text></div>
          <div id = 'jspsych-wtw-total'></div>
          <div id = 'jspsych-wtw-left-time'></div>
          <div id="jspsych-wtw-progress"></div>
          <div id="jspsych-wtw-bar"></div>
          <div id="jspsych-wtw-empty-progress"></div>
          <div id="jspsych-wtw-expired-text"></div>
      </div>`
    }



    // check whether we are in a full screen mode already
    // if so, save a timestamp
    if (document.fullscreenElement){
      screenEnterTime.push(new Date().getTime() - block_start_time.getTime())
    }

    var log_fullscreenchang = function(){
      if (document.fullscreenElement) {
        // if the user enters full screen, record when it is
        screenEnterTime.push(new Date().getTime() - block_start_time.getTime())
        console.log(`Element: ${document.fullscreenElement.id} entered fullscreen mode.`);
      } else {
        // if the user exits full screen, record when it is
        screenExitTime.push(new Date().getTime() - block_start_time.getTime())
        console.log('Leaving full-screen mode.');
      }
    }


    // add an fullscreenchange event listner
    document.documentElement.addEventListener('fullscreenchange', log_fullscreenchang);

    // update the progress bar (to be killed when the trial ends)
    var barHandler = setInterval(function(){updateBar()}, 100);
    var timeHandler = setInterval(function(){updateTime()}, 100);

    //var total_time = document.getElementById("jspsych-wtw-left-time")
    //total_time.innerHTML  = "Time left: " + 10:00

    // call the recursive function, unit_trial
    unit_trial()

    // set up a timer to terminate the block
    jsPsych.pluginAPI.setTimeout(function(){
      terminate_block()
    }, trial.block_time);


  };

  return plugin;
})();
