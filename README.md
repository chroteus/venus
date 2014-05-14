Venus
=====

Venus is easy-to-use gamestate library with smooth transitions between states to make games feel better, as direct switch doesn't look and feel good.

Setup
-----

* HUMP.Timer is needed for tweens which are used in transitions. It's already loaded in venus_transitions. You'll need to call Timer.update(dt) in the love.update(dt), though.

* Default transition animation is "fade". You can change the transition animation by changing venus.currentFx to the animation you want. (ex: "slide") 


Callbacks
---------

Venus has all the callbacks that LÖVE has (draw, update, etc) with all their arguments (like dt in update).
In addition to these, there are additional callbacks:

* init: Called once. Load and initialize stuff here.
* enter: Called each time you enter state.
* leave: Called each time you leave state.


Example:
```lua
  tutorial = {} -- create state

  function tutorial:init() -- ran only once
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
  end
```
