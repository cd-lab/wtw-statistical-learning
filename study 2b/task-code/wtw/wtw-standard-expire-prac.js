/*
 *
 PExample plugin template
 */

jsPsych.plugins["wtw-standard-expire-prac"] = (function(){

  var plugin = {};

  plugin.info = {
    name: "wtw-standard-expire-prac",
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
      trial_id: {
        type: jsPsych.plugins.parameterType.STRING,
        default: "prac",
        description: 'Trial ID'
      },
      scheduled_delay: {
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
        description: 'earnings earned from previous blocks'
      },
      instruction:{
        type: jsPsych.plugins.parameterType.STRING,
        description: 'Whether to sell the token before or after the token matures'
      }
    }
  }

  plugin.trial = function(display_element, trial){
    /********************************************************************/
    /* helper functions */
    /********************************************************************/
    // functions to kill the handlers and the listener
    // function to display stimuli

    var kill_listeners = function(){
      if(keyboardListener !== 'undefined'){
        jsPsych.pluginAPI.cancelAllKeyboardResponses()
      }
    }
    var kill_timers = function(){
      for (var i = 0; i < timeoutHandlers.length; i++) {
        clearTimeout(timeoutHandlers[i])
      }
    }

    var restart = function(){
      if(trial.instruction == "mature"){
        display_element.innerHTML = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
                '<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature and then sell it.</p>' +
                '<button id = "button">Try Again</button>' 
      }else{
        display_element.innerHTML = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
                '<p style="color: white; font-size: 30px; line-height: 2">Sell the token before it matures</p>' +
                '<button id = "button">Try Again</button>'
      }
      document.getElementById("button").onclick = function() {unit_trial()};
    }


    var display_stim = function(stim_name, current_time){
      var tokenColor = "grey"
      var tokenBorderColor = "grey"
      var soldText = ""
      var centText = ""
      var centTextRight = 55 + "px"
      var expiredText = ""


      if(stim_name == "immature_token"){
        tokenColor = "green"
        tokenBorderColor = "white"
        centText = "0&cent"
        centTextRight = 80 + "px"
      }

      if(stim_name == "mature_token"){
        tokenColor = "blue"
        tokenBorderColor = "white"
        centText = trial.maturation_value + "&cent"
        centTextRight = 55 + "px"
      }

      if(stim_name == "immature_sold"){
        tokenColor = "green"
        tokenBorderColor = "white"
          soldText = "SOLD"
        centText = "0&cent"
        centTextRight = 80 + "px"
      }

      if(stim_name == "mature_sold"){
        tokenColor = "blue"
        tokenBorderColor = "white"
        centText = trial.maturation_value+"&cent"
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

      var cent_text = document.getElementById("jspsych-wtw-cent-text")
      cent_text.innerHTML = centText

      var expired_text = document.getElementById("jspsych-wtw-expired-text")
      expired_text.innerHTML = expiredText

      // update the total earnings
      var total_text = document.getElementById("jspsych-wtw-total")
      var earningsCountToDisplay = (Math.round(earningsCount) / 100).toFixed(2);
      total_text.innerHTML  = "Earned: $" + earningsCountToDisplay


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
      //console.log(4*width)
    }

    var updateTime = function(){
      // read the current time
      var current_time = new Date()
      // update time
      var elapsedTime_block =  current_time.getTime() - block_start_time.getTime()
      var timeinSeconds = parseInt((901000 - elapsedTime_block) / 1000)
      //console.log(timeinSeconds)
      var timeInNewFormat = new Date(timeinSeconds * 1000).toISOString().substr(11, 8);
      var minSec = timeInNewFormat.slice(3,8)
      var total_time = document.getElementById("jspsych-wtw-left-time")
      total_time.innerHTML  = "Time left: " + minSec

    }

    var end_of_trial = function(sell_timing){
      kill_listeners(keyboardListener)
      kill_listeners(keyboardListenerMatured)
      kill_timers(timeoutHandlers)
      if(trial.instruction != sell_timing){
        restart()
      }else{
        trial_data = {
          "scheduledDelay": scheduledDelay,
          "trialStartTime": trialStartTime,
          "RT": RT,
          "trialEarnings": trialEarnings,
          "totalEarnings": totalEarnings,
          "timeWaited": timeWaited,
          "sellTime": sellTime,
          "rewardedTime": rewardedTime
        }
        jsPsych.finishTrial(trial_data)
        clearInterval(barHandler)
        clearInterval(timeHandler)
      }
    }

    // callback functions
    var callback = function(sell_timing){ // data refer to the data recorded by the listener
      kill_timers()
      kill_listeners(keyboardListener)
      kill_listeners(keyboardListenerMatured)


      console.log(trial.feedback_time)
      console.log(trial.iti )
      // update the global variables, trialCount and earningCount
      if(sell_timing == "immature"){
        earningsCount += 0.00
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
        display_stim("immature_sold")
      }
      else{
        display_stim("mature_sold")
      }

      var empty_bar = document.getElementById("jspsych-wtw-empty-progress")
      empty_bar.style.background = "grey"


      // clear the screen for the iti period
      var handle_iti = jsPsych.pluginAPI.setTimeout(function(){
        display_stim("iti")
        var empty_bar = document.getElementById("jspsych-wtw-empty-progress")
        empty_bar.style.borderColor = "transparent"

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

      // if the token is sold before it matures
      keyboardListener = jsPsych.pluginAPI.getKeyboardResponse({
        callback_function: function() {
          callback("immature")
        },
        valid_responses: [32],
        rt_method: 'performance',
        persist: false
      })

      // if the token matures
      var handle_token_mature = jsPsych.pluginAPI.setTimeout(function(){
        kill_listeners()
        kill_timers()
        var current_time = new Date()
        display_stim("mature_token")

        // save rewarded time
        current_rewarded_time = current_time

        // start to check keypress again
        var keyboardListenerMatured = jsPsych.pluginAPI.getKeyboardResponse({
          callback_function: function(){
            callback("mature")
          },
          valid_responses: [32],
          rt_method: 'performance',
          persist: true
        })

        var handleExpired = jsPsych.pluginAPI.setTimeout(function(){

          if (keepGoing == "yes"){
            kill_listeners(keyboardListener)
            kill_listeners(keyboardListenerMatured)


            display_stim("expired")
            var current_time = new Date()

            var elapsedTime_trial =  current_time.getTime() - current_trial_start_time.getTime()
            // clear the screen for the iti period

            earningsCount += 0.00
            trialEarnings.push(0)
            RT.push(Number.NaN)
            sellTime.push(current_time.getTime() - block_start_time.getTime())
            timeWaited.push(current_time.getTime() - current_trial_start_time.getTime())
            rewardedTime.push(Number.NaN)


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
      // display stimuli: wtw-token, wtw-cent-text, wtw-sold-text, wtw-total,...
      // properties of these stimuli can be updated later
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

      //<div id="jspsych-wtw-empty-progress"></div>

      //var empty_bar = document.getElementById("jspsych-wtw-empty-progress")
      //empty_bar.style.background = "transparent"
      keepGoing = "yes"
      block_start_time = new Date()
      earningsCount = 0

      // update the global variable, current_trial_start_time
      current_trial_start_time = new Date()
      trialStartTime.push(current_trial_start_time.getTime() - block_start_time.getTime())

      // update the global variable, current delay
      currentDelay = trial.scheduled_delay

      // save input data
      scheduledDelay.push(currentDelay)

      // update the global variable, trialCount
      trialCount += 1

      // show the immature token
      display_stim("immature_token")


      // check keypress
      keypressCheck()

    }

    /**********************************************************************/
    /* main */
    /**********************************************************************/
    var timeoutHandlers = [] // handlers can be defined locally, yet will be pushed to the global level so that they can be killed by the function
    var keyboardListener = new Object // keyboardListener is defined directly on the global level and could be killed by the function, kill_listeners
    var keyboardListenerMatured = new Object

    // update the progress bar (to be killed when the trial ends)
    var barHandler = setInterval(function(){updateBar()}, 50);
    var timeHandler = setInterval(function(){updateTime()}, 50);

    // trial-wise variables
    var currentDelay;
    var current_rewarded_time;
    var current_trial_start_time;
    //  time marker
    var block_start_time = new Date()
    // trial counter
    var trialCount = 0
    var earningsCount = 0

    // initialize the output
    var scheduledDelay = []
    var RT = []
    var trialEarnings = []
    var totalEarnings = []
    var timeWaited = []
    var trialStartTime = []
    var sellTime = []
    var rewardedTime = []
    var imKeypressLog = []
    var maKeypressLog = []
    var keepGoing = []


    // call the recursive function, unit_trial
    unit_trial()

  };

  return plugin;
})();
