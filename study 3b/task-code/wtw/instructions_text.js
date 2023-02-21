// task constants
var block_time = 15 * 1000 * 60
var task_time = 15 * 1000 * 60
var initial_value = 0
var matruation_value = 3

//
mid_quit_warning_text = "<p style= 'color: white; font-size: 30px; line-height: 2' id='instruction'>Please avoid closing the tab midway through the task. You may lose your data in that case.</p>" +
"<p style= 'color: white; font-size: 30px; line-height: 2' id='instruction'>You will be given explicit instructions to close the tab after you complete this task.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2" id="instruction">Make sure you have ' + task_time / 1000 / 60 + ' minutes of undistracted time before you start.</p>'+
"<p style= 'color: white; font-size: 30px; line-height: 2' id='instruction'>If you are ready, click 'Next' to start the task.</p>"

instructions_3_text = '<p style="color: white; font-size: 30px; line-height: 2">You will have a limited amount of time to play.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">If a token is taking too long, you might want to sell it before it matures in order to move on to a new one.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Next, practice selling the token before it matures.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to start.</p>'

instructions_4_text = '<p style="color: white; font-size: 30px; line-height: 2"> Ok, let'+ "&#39s do it again.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2">Practice selling the token before it matures.</p>'

instructions_5_text = '<p style="color: white; font-size: 30px; line-height: 2">You will have ' + block_time / 1000 / 60 + ' minutes to play.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Your goal is to earn as much money as you can in the available time.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">At the end of the experiment, you will be paid what you earned as a bonus in addition to your $3 baseline payment.</p>'

instructions_6_text = '<p style="color: white; font-size: 30px; line-height: 2">You just completed the first block. Please take a break.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Whenever you are ready, please click "Next" to start the second block</p>'

// passive-waiting instructions
standard_instructions_1a_text =
        '<p style="color: white; font-size: 30px; line-height: 2" id="instruction">You will see a token on the screen. Tokens can be sold for money.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Each token is worth ' + initial_value + " cents at first.</p>" +
        '<p style="color: white; font-size: 30px; line-height: 2">After some time, it "matures" and is worth ' + matruation_value + " cents. </p>"

standard_instructions_1b_text  = '<p style="color: white; font-size: 30px; line-height: 2">Now try a practice round.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature, then press the spacebar to sell it.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to start.</p>'

standard_instructions_2_text = '<p style="color: white; font-size: 30px; line-height: 2"> Ok, let'+ "&#39s do it again.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature, then sell it.</p>'
'<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to start.</p>'

passive_warnings_please_wait_longer_text = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature and then sell it.</p>' +
        '<button id = "button">Try Again</button>'

passive_warnings_please_sell_ealier_text = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Sell the token before it matures</p>' +
        '<button id = "button">Try Again</button>'


standard_instructions_bar = '<p style="color: white; font-size: 30px; line-height: 2">The progress bar will show you how long the current token has been on the screen.</p>' +
      '<img src="wtw/img/standard_cropped.png", style="width: 60%"></img>'

discrete_instructions_bar = '<p style="color: white; font-size: 30px; line-height: 2">The progress bar will show you how long the current token has been on the screen.</p>' +
          '<img src="wtw/img/discrete_cropped.png", style="width: 60%"></img>' +
          '<p style="color: white; font-size: 30px; line-height: 2">The bar will be crosshatched to mark the possible reward times. For each token, one of the marked times is selected at random, with equal probability, as the time when the token will mature.</p>'
