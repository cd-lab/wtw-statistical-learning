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

instructions_3_text = '<p style="color: white; font-size: 30px; line-height: 2">We are almost ready to start!</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Remember, you cannot sell the token before it matures. If you respond too early, you will be penalized by ' + matruation_value + " cents.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to move on.</p>'

instructions_4_text = '<p style="color: white; font-size: 30px; line-height: 2">You should sell the token as soon as it matures.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">If you wait too long, it will expire and you will not be able to sell it.</p>' +
'<img src="wtw/img/expired_cropped.png", style="width: 60%"></img>'

instructions_7_text = '<p style="color: white; font-size: 30px; line-height: 2">You will have 15 minutes to play.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Your goal is to sell each token as quickly as possible after it matures.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Remember that you cannot sell the token before it matures.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">If you respond too slowly after it matures, it will expire and you will not be able to sell it.</p>'


instructions_8_text = '<p style="color: white; font-size: 30px; line-height: 2">At the end of the experiment, you will be paid what you earned as a bonus in addition to your $6 baseline payment.</p>'

instructions_9_text = '<p style="color: white; font-size: 30px; line-height: 2">You just completed the first block. Please take a break but make sure to not exit the fullscreen mode.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Whenever you are ready, please click "Next" to move on to the next block.</p>'

instructions_10_text_a = '<p style="color: white; font-size: 30px; line-height: 2">Your task in the second block will be similiar to your task in the first block.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Tokens will behave in a similar way to the first block: They will be worth 0 cents at first. After some time, they will "mature" and be worth ' + matruation_value + " cents. </p>"

instructions_10_text_b = '<p style="color: white; font-size: 30px; line-height: 2">In the second block, you can sell tokens before they mature. If you do, you will receive 0 cents and move on to the next token.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">You might want to do this if a token is taking too long, since you have a limited amount of time to play.</p>'


instructions_11_text = '<p style="color: white; font-size: 30px; line-height: 2">In the following practice trial, try selling the token before it matures.</p>'

instructions_12_text = '<p style="color: white; font-size: 30px; line-height: 2"> Ok, let'+ "&#39s do it again.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2">Practice selling the token before it matures.</p>'

instructions_13_text = '<p style="color: white; font-size: 30px; line-height: 2">You will have 15 minutes to play, and you can get as many tokens as time permits.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Ok, let'+ "&#39s do it again.</p>"

instructions_pre_text = '<p style="color: white; font-size: 30px; line-height: 2">This task will consist of two 15 minute blocks.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Please click "Next" to start practicing for the first block.</p>'


//instructions
instructions_1a_text =
        '<p style="color: white; font-size: 30px; line-height: 2" id="instruction">You will see a token on the screen. Tokens can be sold for money.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Each token is worth ' + initial_value + " cents at first.</p>" +
        '<p style="color: white; font-size: 30px; line-height: 2">After some time, it "matures" and is worth ' + matruation_value + " cents. </p>"

instructions_1b_text  = '<p style="color: white; font-size: 30px; line-height: 2">Try a practice round.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature, then press the spacebar to sell it as quickly as possible.</p>' +
'<p style="color: white; font-size: 30px; line-height: 2">Be careful! If you wait too long, it will expire!</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to start.</p>'

standard_instructions_2_text = '<p style="color: white; font-size: 30px; line-height: 2"> Ok, let'+ "&#39s do it again.</p>" +
'<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature, then sell it.</p>'
'<p style="color: white; font-size: 30px; line-height: 2">Click "Next" to start.</p>'

do_not_sell_before_mat = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">You cannot sell the token before it matures.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature and then sell it.</p>' +
        '<button id = "button">Try Again</button>'

respond_faster = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">You should sell the token as soon as it matures.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">If you wait too long, it will expire and you will not be able to sell it.</p>' +
        '<button id = "button">Try Again</button>'

do_not_sell_before_but_respond_faster = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">You cannot sell the token before it matures.</p>' +
        '<p style="color: white; font-size: 30px; line-height: 2">After it matures, you should sell it as quickly as possible.</p>' +
        '<button id = "button">Try Again</button>'

        passive_warnings_please_wait_longer_text = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
                '<p style="color: white; font-size: 30px; line-height: 2">Wait for the token to mature and then sell it.</p>' +
                '<button id = "button">Try Again</button>'

        passive_warnings_please_sell_ealier_text = '<p style="color: white; font-size: 30px; line-height: 2">Please follow the instructions.</p>' +
                '<p style="color: white; font-size: 30px; line-height: 2">Sell the token before it matures</p>' +
                '<button id = "button">Try Again</button>'


standard_instructions_bar = '<p style="color: white; font-size: 30px; line-height: 2">The progress bar shows you how long the current token has been on the screen.</p>' +
      '<img src="wtw/img/standard_cropped.png", style="width: 60%"></img>'

discrete_instructions_bar = '<p style="color: white; font-size: 30px; line-height: 2">The progress bar shows you how long the current token has been on the screen.</p>' +
          '<img src="wtw/img/discrete_cropped.png", style="width: 60%"></img>' +
          '<p style="color: white; font-size: 30px; line-height: 2">The bar will be crosshatched to mark the possible reward times. For each token, one of the marked times is selected at random, with equal probability, as the time when the token will mature.</p>'
