Venus
=====

Venus is easy-to-use gamestate library with smooth transitions between states to make games feel better, as direct switch doesn't look and feel good.

Setup
-----

* HUMP.Timer is needed for tweens which are used in transitions. It's already loaded in venus_transitions. You'll need to call Timer.update(dt) in the love.update(dt), though.

* Default transition animation is "fade". You can change the transition animation by changing venus.currentFx to the animation you want. (ex: "slide") 
