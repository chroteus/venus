Venus
=====

Venus is easy-to-use gamestate library with smooth transitions between states to make games feel better, as direct switch doesn't look and feel good. It harnesses the power of HUMP.timer which you'll need to get from https://github.com/vrld/hump

Setup
-----
* Load HUMP.timer. If you've loaded it as something other than like the example in the HUMP docs you can register your timer with `venus.timer = Timer` where `Timer` is an instance of HUMP.timer

* Load venus. Anything can be used as a variable for venus. (ex: `State = require("venus")`)

* Call `venus.registerEvents()` in `love.load()` to override love's callbacks.

* Call `Timer.update(dt)` in `love.update(dt)`. HUMP.Timer (by vrld) is used for tweens in transitions. So make sure you're calling update on whatever time you've registered with Venus.

* Default transition animation is "fade". You can change the transition animation by passing it as an argument to venus.switch (List of animations and venus.effects can be found on top of the venus.lua).

* Switch to a state using `venus.switch` or else nothing would appear.

Effects
-------

#####fade
Fades into a black state and then fades out to the next state.

#####slide
Slides the state depending on the direction you give to it. Not specifying a direction will use "slide_left"

* slide_right: Slides the state from left to right.
* slide_left: Default if you used "slide" only. Slides to left.
* slide_down: Slides the state down.
* slide_up: Slides the state up.


#####none
Direct switch without transition effects. The rule of initializing everything in `init` does not apply to this transition.

Functions
---------

#####venus.registerEvents()
Turns love.callback into love.callback + venus.callback.
This eliminates the need to call venus.callback in every love.callback.

callback = (update, draw, keyreleased, etc)

#####venus.switch(to, effect, duration)
Switches to a state. Effect is an optional argument and if it's absent venus.effect will be used. Duration is also optional and if it's absent venus.duration will be used. Current defaults are 'fade' and '1' respectively.

Setting Defaults
----------------

Set the default transition effect with `venus.effect = 'fade'` and the default transition duration with `venus.duration = 0.5`.

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
Timer = require "lib.timer" -- This is HUMP.timer
State = require "lib.venus"
require "states.tutorial"

function love.load()
    State.registerEvents()
    State.switch(tutorial)
end

function love.update(dt)
    Timer.update(dt)
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
