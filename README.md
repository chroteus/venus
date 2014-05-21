Venus
=====

Venus is easy-to-use gamestate library with smooth transitions between states to make games feel better, as direct switch doesn't look and feel good.

Setup
-----
* Load venus. Anything can be used as a variable for venus. (ex: state = require("venus"))

* Call venus.registerEvents() in love.load() to override love's callbacks.

* Call venus.timer.update(dt) in love.update(dt). HUMP.Timer (by vrld) is used for tweens in transitions.

* Default transition animation is "fade". You can change the transition animation by changing value of venus.currentFx (List of animations and venus.currentFx can be found on top of the venus.lua).

* Switch to a state using venus.switch(to, effect) or else nothing would appear.

Functions
---------

#####venus.registerEvents()
Turns love.callback into love.callback + venus.callback.
This eliminates the need to call venus.callback in every love.callback.

callback = (update, draw, keyreleased, etc)

#####venus.switch(to, effect)
Switches to a state. Effect is an optional argument and if it's absent venus.currentFx will be used.

Callbacks
---------

Venus has all the callbacks that LÖVE has (draw, update, etc) with all their arguments (like dt in update).
In addition to these, there are additional callbacks:

* init: Called once. Load and initialize stuff here.
* enter: Called each time you enter state.
* leave: Called each time you leave state.

Important note
--------------

Do NOT initialize anything in enter. Initialize/load everything in "init".

#####The reason 
Before switching to a state and starting animation, state is initialized.
This is done in order to load or initialize everything (images, text...) needed for drawing when playing animation.
"enter" is called when the animation stops and you finally enter the state.

Instead, "enter" should be used to reset data.


***

Example:

main.lua:

```lua
venus = require "lib.venus"
require "states.tutorial"

function love.load()
    venus.registerEvents()
    venus.switch(tutorial)
end

function love.update(dt)
    venus.timer.update(dt)
end
```

    

State (tutorial.lua) file:
```lua
tutorial = {} -- create state

function tutorial:init() -- ran only once
    -- notice that NOTHING is initialized in "enter" callback

    tutorial.text = [[
    Map:
    WASD/Mouse - Move camera
    Mouse wheel - Zoom in/out
      
    ESC - Menu
    Tab - Character Screen
      
    Battle:
    Space - Attack 
    Hotkey (or click) - Skill
    ]]
    
    tutorial.btn = GenericButton(4, "Start >>", function() Gamestate.switch(game) end)
end

function tutorial:enter() -- ran every time you enter state
    print("Entered tutorial state")
end
  
function tutorial:update(dt)
    tutorial.btn:update()
end
  
function tutorial:draw()
    tutorial.btn:draw()
    love.graphics.printf(tutorial.text, 0, 100, the.screen.width, "center")
end
  
function tutorial:mousereleased(x,y,button)
    tutorial.btn:mousereleased(x,y,button)
end

function tutorial:leave() -- ran each time you leave the state
    print("Left tutorial state!")
end
```
