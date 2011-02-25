--
-- "Go Fish" for PSP
--
-- by DSI
--




-- Global variables

version = "1.1"

card_back	      = "deck/back_blue.png"
background      = "misc/background.png" 
triangle        = "misc/triangle.png"
select_snd      = "sounds/select.wav"
doh_snd         = "sounds/doh.wav"
excellent_snd   = "sounds/excellent.wav"
booo_snd        = "sounds/booo.wav"
hurray_snd      = "sounds/applause.wav"
groan_snd       = "sounds/groans.wav"
score_file      = "score.dat"


myfont = Font.createProportional()
myfont:setPixelSizes(0,11)
y_fix = 12

text_rect_w = 230
text_rect_h = 15
hearts = {}
diamonds = {}
spades = {}
clubs = {}
deck = {}
deck_index = 1
NONE = 0
PC = 1
HUMAN = 2
num_pairs = {}
num_pairs[PC] = 0
num_pairs[HUMAN] = 0
won = {}
won[HUMAN] = 0
won[PC] = 0
hand = {}
hand[PC] = {}
hand[HUMAN] = {}
max_size = 14 -- You can have 13 cards without a pair, plus 1 from deck/opponent
current_turn = NONE
next_turn = NONE
selected_card = 1
card_to_ask = 0
GO_FISH = 1
MATCH = 2
response_result = NONE
add_number = 0
add_suit = 0
reset_flag = false
end_flag = false

card_str = {}
card_str[1] = "ACE"
card_str[2] = "TWO"
card_str[3] = "THREE"
card_str[4] = "FOUR"
card_str[5] = "FIVE"
card_str[6] = "SIX"
card_str[7] = "SEVEN"
card_str[8] = "EIGHT"
card_str[9] = "NINE"
card_str[10] = "TEN"
card_str[11] = "JACK"
card_str[12] = "QUEEN"
card_str[13] = "KING"

black = Color.new(0,0,0)
white = Color.new(255,255,255)
red = Color.new(255,0,0)
green = Color.new(0,255,0)
blue = Color.new(0,0,255)
yellow = Color.new(245,245,125)


function loadScore()

	-- open file for reading
	file = io.open(score_file, "r")

	-- file not found
	if file == nil then	
		saveScore()

	-- if file found then grab the high score
	else
		won[HUMAN] = file:read("*n")
    won[PC] = file:read("*n")
	  file:close()
	end

end -- loadScore


function saveScore()

	file = io.open(score_file, "w")

	if file then
		file:write(won[HUMAN])
    file:write("\n")
    file:write(won[PC])
		file:close()
	end

end -- saveScore



function loadImages() 

  card_back	= Image.load(card_back)
  background = Image.load(background)  
  triangle = Image.load(triangle)

	for i = 1,13 do

		if i == 11 then
			num = "j"
		elseif i == 12 then
			num = "q"
		elseif i == 13 then
			num = "k"
		else
			num = i
		end	

		hearts[i] 		= Image.load("deck/h" .. num .. ".png")
		diamonds[i]		= Image.load("deck/d" .. num .. ".png")
		spades[i] 		= Image.load("deck/s" .. num .. ".png")
		clubs[i] 			= Image.load("deck/c" .. num .. ".png")

	end

end -- loadImages



function loadSounds()

  select_snd = Sound.load(select_snd)
  doh_snd = Sound.load(doh_snd)
  excellent_snd = Sound.load(excellent_snd)
  booo_snd = Sound.load(booo_snd)
  hurray_snd = Sound.load(hurray_snd)
  groan_snd = Sound.load(groan_snd)

end -- loadSounds


function loadFiles()

  showLoading()
  loadScore()
  loadImages()
  loadSounds()

end -- loadFiles



function showLoading() 

  loadfont = Font.createProportional()
  loadfont:setPixelSizes(0,18)
  load_str = "Loading ..."
  x = (480 - 10*string.len(load_str)) / 2 + 1 
  y = (272 - 18) / 2 + 1
  screen:fontPrint(loadfont,x,y,load_str,yellow)
  screen.waitVblankStart()
  screen:flip()

end -- showLoading




function shuffleDeck()

  -- Generate a random number seed based on the time
  -- Note: sometimes the first number is not random, so call it twice
  math.randomseed(os.time())
  math.randomseed(os.time())

	-- Create a deck of cards
	for i = 1,52 do

    -- Ace = 1, Jack = 11, Queen = 12, King = 13
		deck[i] = { number = 0, suit = 0 } 

		if i < 14 then
			deck[i].suit = "HEARTS"				-- cards 1 to 13	
			deck[i].number = i
		elseif i < 27 then
			deck[i].suit = "SPADES"       -- cards 14 to 26
			deck[i].number = i-13
		elseif i < 40 then
			deck[i].suit = "DIAMONDS"     -- cards 27 to 39
			deck[i].number = i-26
		else 
			deck[i].suit = "CLUBS"				-- cards 40 to 52
			deck[i].number = i-39
		end

	end -- FOR


  -- Now shuffle

	temp = { number = 0, suit = 0 }

	for i = 1,52 do
	
		-- Swap current card with a random card in the deck
		rand = math.random(1,52)

		if i ~= rand then

			temp.suit = deck[i].suit
			temp.number = deck[i].number		

			deck[i].suit = deck[rand].suit
			deck[i].number = deck[rand].number
			deck[rand].suit = temp.suit
			deck[rand].number = temp.number

		end
	end

	
end -- shuffleDeck





function dealCards()

  num_pairs[PC] = 0
  num_pairs[HUMAN] = 0
  response_result = NONE
  current_turn = NONE

	-- Initialize the hand of cards that will be held by the players
	for h = 1,max_size do
		hand[PC][h]       = { number = 0, suit = 0 }
		hand[HUMAN][h]    = { number = 0, suit = 0 }
	end

	-- Now deal 7 cards to the players	
	deck_index = 1

	for d = 1,7 do
		hand[PC][d].suit    = deck[deck_index].suit
		hand[PC][d].number 	= deck[deck_index].number
		deck_index = deck_index + 1

		hand[HUMAN][d].suit   = deck[deck_index].suit
		hand[HUMAN][d].number	= deck[deck_index].number
    deck_index = deck_index + 1
	end

end -- dealCards






function getCardImage(card)

	number = card.number
	image = nil

	if card.suit == "HEARTS" then
		image = hearts[number]
	elseif card.suit == "DIAMONDS" then
		image = diamonds[number]
	elseif card.suit == "SPADES" then
		image = spades[number]
	else
		image = clubs[number]
	end

	return image

end -- getCardImage




function drawEverything()

  x_gap = 5
  y_gap = 10
  y_status = 3*y_gap + card_back:height() + 5*y_gap + card_back:height() + 2*y_gap - 5
  y_status2 = y_status + 2*y_gap

  -- Draw background
  screen:blit(0, 0, background, 0, 0, background:width(), background:height(), false)

  -- Show computer's's cards
  x = 3*x_gap
  y = 3*y_gap
  for p = 1,max_size do
    if hand[PC][p].number ~= 0 then
      image = card_back
      screen:blit(x,y,image)
      x = x + 6*x_gap
    end
  end  

  -- Show human's cards
  x = 3*x_gap
  y = 3*y_gap + card_back:height() + 5*y_gap
  for p = 1,max_size do
    if hand[HUMAN][p].number ~= 0 then
      image = getCardImage(hand[HUMAN][p])
      screen:blit(x,y,image)
      x = x + 6*x_gap
    end
  end

  -- Show a message if cards have been dealt for the first time
  if current_turn == NONE then
    x = x_gap
    y = y_status
    screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
    screen:fontPrint(myfont,x,y+y_fix,"Cards have been dealt to each player",black)

  end 


  -- Show whose turn is next
  x = x_gap
  y = y_status 

  if current_turn ~= NONE then

    -- Start of turn
    if response_result == NONE then
      player_str = "COMPUTER"
     
      if current_turn == HUMAN then
        player_str = "HUMAN"
      end

      screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
      screen:fontPrint(myfont,x,y+y_fix,player_str .. "'s turn",black)
    end  

 
    -- Current turn is Human 
    if current_turn == HUMAN then

      -- Show what he wants or what the response was
      y = y_status
      x = x_gap
      
      if response_result == NONE then

        -- Draw triangle under selected card
        y = 8*y_gap + 2*image:height() 
        x = 4*x_gap + 6*(selected_card-1)*x_gap
        screen:blit(x,y,triangle)

        -- Draw help info for triangle
        y = y_status2
        x = x_gap

        str = card_str[hand[HUMAN][selected_card].number]
        screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
        screen:fontPrint(myfont,x,y+y_fix,"Press triangle to play the " ..str,black)

      else
        if isHandFinished()==false and isDeckEmpty()==false then
          screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)

          if response_result == GO_FISH then
            screen:fontPrint(myfont,x,y+y_fix,"COMPUTER said 'GO FISH'",black)
          elseif response_result == MATCH then
            screen:fontPrint(myfont,x,y+y_fix,"COMPUTER gave up a card",black)    
          elseif response_result == ADD_CARD then
            
            str = "COMPUTER"

            if next_turn == opponent then
              str = "the deck"
            end

            screen:fontPrint(myfont,x,y+y_fix,"HUMAN adds a card from " .. str,black)
          end
        end
      end

    -- Current turn is Computer
    else

      -- Show what he wants or what the response was
      y = y_status2
      x = x_gap
      
      if card_to_ask ~= 0 then
        str = card_str[card_to_ask]
        screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
        screen:fontPrint(myfont,x,y+y_fix,"COMPUTER is asking for: " ..str,black)
      
      else
        if isHandFinished()==false and isDeckEmpty()==false then
          y = y_status 
          screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
         
          if response_result == GO_FISH then
            screen:fontPrint(myfont,x,y+y_fix,"HUMAN said 'GO FISH'",black)
          elseif response_result == MATCH then
            screen:fontPrint(myfont,x,y+y_fix,"HUMAN gave up a card",black)    
          elseif response_result == ADD_CARD then

            str = "HUMAN"

            if next_turn == opponent then
              str = "the deck"
            end

            screen:fontPrint(myfont,x,y+y_fix,"COMPUTER adds a card from " .. str,black)
          end

        end
      end

    end -- ELSE current_turn 
  end -- IF current_turn ~= NONE
  

  -- If game over show why it finished
  if isHandFinished() then
    y = y_status
    screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
    screen:fontPrint(myfont,x,y+y_fix,"Hand is empty - game over",black)
  elseif isDeckEmpty() then
    y = y_status
    screen:fillRect(2,y,text_rect_w,text_rect_h,yellow)
    screen:fontPrint(myfont,x,y+y_fix,"Deck is finished - game over",black)
  end


  -- Show scoreboard for PC
  x = x_gap
  y = y_gap

  screen:fillRect(2,5,text_rect_w,text_rect_h,white)
  str = " pairs"
  if num_pairs[PC] == 1 then
    str = " pair"
  end

  str = str .. "   Games won: " .. won[PC]
  screen:fontPrint(myfont,x,y+7, "COMPUTER: " .. num_pairs[PC] .. str,black)
 
  -- Show scoreboard for human 
  y = 3*y_gap + card_back:height() + 2*y_gap
  screen:fillRect(2,y+5,text_rect_w,text_rect_h,white)

  str = " pairs"
  if num_pairs[HUMAN] == 1 then
    str = " pair"
  end

  str = str .. "   Games won: " .. won[HUMAN]
  screen:fontPrint(myfont,x,y+10+7,"HUMAN: " .. num_pairs[HUMAN] .. str,black)


  -- Show deck's remaining cards 
  remaining = 53 - deck_index 
  x = 390
  y = 2*y_gap 
  for i=1,remaining do
    screen:blit(x,y,card_back)
    y = y + 4
  end 
  
  screen:fillRect(360,255,120,20,green)
  screen:fontPrint(myfont,368,267,"Go Fish v" .. version .. " by DSI",black)

  -- Refresh screen with the updates 
  screen.waitVblankStart()
  screen:flip()

end -- drawEverything





function readInput()

	pad = Controls.read()

	if pad:cross() then 
		waitForPadUp()
		return "OK"
	end
	
	if pad:circle() then
		waitForPadUp()
		return "OK"
	end

	if pad:left() then
    setSelectedLeft()
		waitForPadUp()
	end

	if pad:right() then
    setSelectedRight()
		waitForPadUp()
	end

	if pad:triangle() then
		waitForPadUp()
    reset_flag = true
    end_flag = true
    return "ASK"
	end

	-- Screenshot
	if pad:select() then
		screen:save("screenshot.png")
		waitForPadUp()
	end	

  if pad:start() then
    waitForPadUp()
    end_flag = true
    return "START"
  end


end -- readInput


-- If you move left, select the next card on the left
function setSelectedLeft()

  if selected_card ~= 1 then
    selected_card = selected_card - 1

    if current_turn == HUMAN and response_result == NONE then
      select_snd:play()
      System.sleep(100)
    end 
  end

end


-- If you move right, select the next card on the right
function setSelectedRight()

  if selected_card ~= max_size then
    if hand[HUMAN][selected_card+1].number ~= 0 then
      selected_card = selected_card + 1

      if current_turn == HUMAN and response_result == NONE then
        select_snd:play()
        System.sleep(100)
      end 
    end
  end

end




--
-- waitForPadUp:  Pauses execution till all buttons are released;
--								prevents scrolling too fast when pressing d-pad
--
-- This function is credited to Dark Killer at www.ps2dev.org
--
function waitForPadUp()

	pad = Controls.read()

	while pad:cross() or pad:circle() or pad:left() or pad:right() or pad:triangle() or pad:start() do
		pad = Controls.read()
	end

end -- waitForPadUp



-- Look for pairs and remove them from the board
function checkPairs()

  while readInput() ~= "OK" do
    drawEverything()
  end

  -- Go through the hand and discard the pairs 
  -- Mark the pair cards as 0
  for player = PC,HUMAN do 

    for i = 1,(max_size-1) do
      for j = (i+1),max_size do
        if hand[player][i].number ~= 0 and 
         hand[player][i].number == hand[player][j].number then
          num_pairs[player] = num_pairs[player] + 1
          hand[player][i] = { number = 0, suit = 0 }
          hand[player][j] = { number = 0, suit = 0 }
          break
        end
      end 
    end
  end


  -- Create a temporary array that moves the cards over so that the 
  -- "0" cards are moved to the end

  temp = {}

  for player = PC,HUMAN do 
  
    hand_i = 1
    temp[player] = {}
    done_hand = false
 
    for temp_i = 1,max_size do
    
      -- Initialize temp card to 0
      temp[player][temp_i] = { number = 0, suit = 0 }

      -- If we have not looked through the entire hand
      if done_hand == false then
    
        -- Find the next card in the real hand that is non-zero
        while hand[player][hand_i].number == 0 do
          if hand_i < max_size then
            hand_i =  hand_i + 1
          else
            done_hand = true
            break
          end  
        end
   
        -- Set the temp card to the value of the hand card 
        if hand[player][hand_i].number ~=0 then  
          temp[player][temp_i].number = hand[player][hand_i].number
          temp[player][temp_i].suit   = hand[player][hand_i].suit 
        end

        if hand_i < max_size then
          hand_i = hand_i + 1
        end

      end -- IF done_hand

    end -- FOR temp_i

    -- Copy the temporary array into the existing hands
    for hand_i = 1,max_size do
      hand[player][hand_i].number = temp[player][hand_i].number
      hand[player][hand_i].suit   = temp[player][hand_i].suit
    end

  end 


end -- checkPairs



-- Check both hands to see if they are finished
function isHandFinished() 
  
  finished = true

  for c = 1,max_size do
    if hand[PC][c].number ~= 0 and hand[HUMAN][c].number ~= 0 then
      finished = false
      break
    end
  end

  return finished

end -- isHandfinished


function isDeckEmpty()

  empty = false

  if deck_index > 52 then
    empty = true
  end

  return empty

end -- isDeckEmpty



-- Determine whose turn it is
-- Player goes again if he received opponent's card
-- If start of game, then determine randomly the first to go
function determineWhoseTurn()

  -- Game has started, determine first to go with a coin toss
  if current_turn == NONE then
    current_turn = math.random(PC,HUMAN)
  else
    current_turn = next_turn
  end

  selected_card = 1

end -- determineWhoseTurn



function getNumCardsInHand(who)

  num = 0
  while hand[who][num+1].number ~= 0 do
    num = num + 1
  end 

  return num

end -- getNumCardsInHand


-- Ask the other player for a matching card.
--
-- (If it's the PC's turn, then this is determined by randomly picking a card, 
-- OR, it is determined based on what the human player asked before)
--
function askCard() 

  response_result = NONE

  if current_turn == PC then

    -- Determine number of cards in hand
    num = getNumCardsInHand(PC)

    -- Ask for a match for a random card from its hand 
    rand = math.random(1,num)
    card_to_ask = hand[PC][rand].number 

    while readInput() ~= "OK" do
      drawEverything()
    end

  else

    while readInput() ~= "ASK" do
      drawEverything()
    end

    card_to_ask = hand[HUMAN][selected_card].number
  end

end -- askCard


-- a) If opponent has match, then player takes it
-- b) If no match, player gets one card from deck  
function getResponse() 

  opponent = PC

  if current_turn == PC then
    opponent = HUMAN
  end

  -- Look for this card in human's hand
  for index = 1,max_size do

    -- Card not found, go fish
    if hand[opponent][index].number == 0 then
      response_result = GO_FISH
      card_to_ask = 0       
 
      while readInput() ~= "OK" do
        drawEverything()
      end

      -- Add card from deck
      response_result = ADD_CARD
      insert_index = getNumCardsInHand(current_turn) + 1
      hand[current_turn][insert_index].number = deck[deck_index].number
      hand[current_turn][insert_index].suit = deck[deck_index].suit
      deck_index = deck_index + 1
      
      next_turn = opponent
      break

    -- Card is found
    elseif hand[opponent][index].number == card_to_ask then
      response_result = MATCH
      card_to_ask = 0

      if opponent == PC then
        doh_snd:play()
        System.sleep(500)
      else
        excellent_snd:play()
        System.sleep(1000)
      end


      -- Remove from opponent
      removed_num = hand[opponent][index].number
      removed_suit = hand[opponent][index].suit
      hand[opponent][index].number = 0
      hand[opponent][index].suit = 0

      while readInput() ~= "OK" do
        drawEverything()
      end
 
      -- Add card from opponent
      response_result = ADD_CARD
      insert_index = getNumCardsInHand(current_turn) + 1
      hand[current_turn][insert_index].number = removed_num
      hand[current_turn][insert_index].suit = removed_suit

      next_turn = current_turn
      break
    end
  end



end -- getResponse


function gameOverScreen() 

    winner = "COMPUTER"
    if num_pairs[PC] > num_pairs[HUMAN] then
      won[PC] = won[PC] + 1
    elseif num_pairs[HUMAN] > num_pairs[PC] then
      won[HUMAN] = won[HUMAN] + 1
      winner = "HUMAN"
    else
      winner = "NOBODY - TIE GAME" 
    end

    x = x_gap
    y = 50

    while readInput() ~= "OK" do
      drawEverything()
    end


    sound_played = false
    endfont = Font.createProportional()
    endfont:setPixelSizes(0,18)
    donatefont = Font.createProportional()
    donatefont:setPixelSizes(0,9)

    end_flag = false
    reset_flag = false

    -- Close the Game Over screen if Start or Triangle pressed
    while true do

      screen:blit(0, 0, background, 0, 0, background:width(), background:height(), false)
      screen:fillRect(71,40,340,132,yellow)
      screen:fillRect(71,192,340,50,white)

      winner_str = "Winner: " .. winner
      x_winner = (480 - 10*string.len(winner_str)) / 2 + 1      
 
      screen:fontPrint(endfont,x_winner,55+y_fix,winner_str,black) 
      screen:fontPrint(myfont,80,80+y_fix,"COMPUTER's pairs = " .. num_pairs[PC],black)
      screen:fontPrint(myfont,80,100+y_fix,"HUMAN's pairs = " .. num_pairs[HUMAN],black)
      screen:fontPrint(myfont,80,120+y_fix,"OVERALL: COMPUTER won " .. won[PC] .. ",  HUMAN won " .. won[HUMAN],black)
      screen:fontPrint(myfont,80,150+y_fix,"Press triangle to reset the score file (and keep this result)",black)

      str1 = "Press START to continue, HOME to quit"
      str2 = "Paypal donations: dislam@rocketmail.com"
      x1 = (480 - 6*string.len(str1)) / 2 + 1
      x2 = (480 - 5*string.len(str2)) / 2 + 1
      screen:fontPrint(myfont,x1,200+y_fix,str1,black) 
      screen:fontPrint(donatefont,x2,220+y_fix,str2,black)
   
      screen.waitVblankStart()
      screen:flip()

      if sound_played == false then
        if winner == "COMPUTER" then
          booo_snd:play()
          System.sleep(2000)
        elseif winner == "HUMAN" then
          hurray_snd:play()
          System.sleep(2000) 
        elseif winner == "NOBODY - TIE GAME" then
          groan_snd:play()
          System.sleep(2000)
        end
        sound_played = true
      end

      readInput()

      if end_flag == true then
        break
      end

    end -- WHILE


    if reset_flag == true then
      won[HUMAN] = 0
      won[PC] = 0

      if winner == "COMPUTER" then
        won[PC] = 1
      elseif winner == "HUMAN" then
        won[HUMAN] = 1
      end
    end

    saveScore()

    reset_flag = false
    end_flag = false

end -- gameOverScreen




----------------------
-- Main program
----------------------

loadFiles()

while true do 

  shuffleDeck() 
  dealCards() 

  while true do
    
    drawEverything()
    checkPairs()

    if isHandFinished() or isDeckEmpty() then 
      break
    end
    
    determineWhoseTurn()
    askCard() 
    getResponse()
  
  end
 
  gameOverScreen() 

end 

