-- TODO
-- #2 be able to change bird color

-- Assets obtained from https://github.com/samuelcust/flappy-bird-assets
push = require "push"
Class = require "class"

require 'Bird'
require 'Pipe'
require 'PipePair'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 534
VIRTUAL_HEIGHT =  300

--background and ground images
local background = love.graphics.newImage('/assets/background.png')
local ground = love.graphics.newImage('/assets/ground.png')

-- Scroll offset
local backgroundScroll = 0
local groundScroll = 0

-- Scroll speeds
local BACKGROUND_SCROLL_SPEED = 30
local GROUND_SCROLL_SPEED = 70

-- Looping Points
local BACKGROUND_LOOPING_POINT = 300
local GROUND_LOOPING_POINT = 43

-- Classes instantiation
local bird = Bird()
-- Table of spawning pipes
local pipePairs = {}

-- spawnTimer variable, in seconds
local spawnTimer = 0

-- Variable to keep continuity on the pipes path for the bird
local lastY = -PIPE_HEIGHT + math.random(80) + 20

local score = 0
local bestScore = 0

local point = love.audio.newSource('/assets/audio/point.wav', 'stream')

-- Variable that changes when the bird collides with a pipe
--local aliveBird = true

gameState = 'start'

function love.load(arg)
    love.graphics.setDefaultFilter('nearest', 'nearest')
    love.window.setTitle("Flappy Bird!")

    math.randomseed(os.time())

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true  
    })

    -- Table of keys pressed  is defined to be used outside main.lua
    love.keyboard.keysPressed = {}


end


function love.resize(w, h)
    push:resize(w, h)
end

function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end



function love.keypressed(key)
    love.keyboard.keysPressed[key] =  true
    -- escape
    if key == 'escape' then

        love.event.quit()

    -- Change states when the return key is pressed
    elseif key == 'enter' or key == 'return' then

    	if gameState == 'start' then
    		gameState = 'play'    	

    	elseif gameState == 'gameOver' then
    		gameState = 'leaderboard'
    	
    	elseif gameState == 'leaderboard' then
    		-- Bird's properties reset.
    		bird:init()

    		-- Pipes reset
    		for k in pairs (pipePairs) do
			    pipePairs[k] = nil
			end

    		gameState = 'start'
    	end
    	
    end
end


function love.update(dt)
    --if aliveBird then
    if gameState == 'start' or gameState == 'play' then

        -- Scroll background
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt)
            % BACKGROUND_LOOPING_POINT
        -- Scroll ground
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt)
            % GROUND_LOOPING_POINT
    end

    -- Avoided using elseif, given that it wouldn't trigger until after the play stage.
    if gameState == 'play' then

        -- Update of spawnTimer
        spawnTimer = spawnTimer + dt
        -- How often a pipe is generated, is updated each two and half second
        if spawnTimer > 2 then
            --Can be changed for dificulties
            -- Sets the new pipes, no higher than 10 pixels below the top of the screen and no loweer than 90 pixels from the bottom
            -- Within the math random are the values of the shift of the next pipes, how high or low will be respect the previous one,
            local y = math.max(-PIPE_HEIGHT + 10, math.min(lastY + math.random(-40, 40), VIRTUAL_HEIGHT - 90 - PIPE_HEIGHT))
            lastY = y

            table.insert(pipePairs, PipePair(y))
            -- Reset spawnTimer
            spawnTimer = 0
        end

        bird:update(dt)
        
        -- Ground collision
        if bird.y >= VIRTUAL_HEIGHT - 45 then
            --aliveBird = false
            gameState = 'gameOver'
        end
        
        --  for each pipe pair
        for k, pair in pairs(pipePairs) do
            pair:update(dt)

            -- update score
            if pair.checked == false then

	            if bird.x > pair.x then
	            	score = score + 1
	            	love.audio.play(point)
	            	pair.checked = true
	            end
        	end

            --checks collision
            for i, pipe in pairs(pair.pipes) do
                if bird:collides(pipe) then
                    
                    -- check if new best score
                    if score > bestScore then
                    	bestScore = score
                    end

                    gameState = 'gameOver'
                end
            end
            
            -- Removes the pipe one it is not visible
            if pair.x < -PIPE_WIDTH then
                pair.remove = true
            end
        end

        for k, pair in pairs(pipePairs) do    
            -- Makes the pipe disapear once traversed all the screen
            if pair.remove then
                table.remove(pipePairs, k)
            end
        end

    end
    love.keyboard.keysPressed = {}
end


function love.draw()
    push:start()
    --Simulate a draw layer by setting an order in which objects will be drawn
    
    if gameState == 'start' or gameState == 'play' or gameState == 'gameOver' then
	    -- Draw background
	    love.graphics.draw(background, -backgroundScroll, -200)
	    
	    -- Draw ground
	    love.graphics.draw(ground, -groundScroll-1, VIRTUAL_HEIGHT - 20)

	    -- Draw Bird
	    bird:render(dt)
	end

	if gameState == 'play' or gameState == 'gameOver' then
	    love.graphics.print(score, VIRTUAL_WIDTH/2, VIRTUAL_HEIGHT/4)

	    -- Draw pipes
	    for k, pair in pairs(pipePairs) do
	        pair:render()
	    end

        -- Draw ground
	    love.graphics.draw(ground, -groundScroll-1, VIRTUAL_HEIGHT - 20)
	end        

    push:finish()
end