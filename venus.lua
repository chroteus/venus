--[[
License:
This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

    1- The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
    2- Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
    3- This notice may not be removed or altered from any source distribution.
]]--

local venus = {}

-- set some sensible defaults.
-- defaults can be set by referencing State.property when you set up your instance of Venus
venus.duration = 1       -- default duration for transitions.
venus.effect   = 'fade'  -- default transition effect
venus.timer    = Timer   -- sesible default for the HUMP.timer object.

-- set up initial states or things will fall in a heap
local states = {}
states.current = {}
states.tween   = {}
states.next    = {}

-- internal function to the next state
function states.switch()
  if states.current.leave then states.current.leave() end

  states.current = states.next
  if states.current.init then states.current.init() end
  states.current.init = nil
  if states.current.enter then states.current.enter() end

  states.tween = {}
end

--[[
List of transitions:
1) fade: Default one. Fades in to a black rectangle which covers whole screen, then fades out to the next state.
2) slide: Slides between states from right to left.
3) fall: Similar to slide, but "falls" downwards and has a slightly different animation.
4) none: Direct switch.
]]--
local transitions = {
  fade = {},
  slide = {},
  fall = {},
  none = {},
}

local all_callbacks = {
  'draw', 'errhand', 'focus', 'keypressed', 'keyreleased', 'mousefocus',
  'mousepressed', 'mousereleased', 'quit', 'resize', 'textinput',
  'threaderror', 'update', 'visible', 'gamepadaxis', 'gamepadpressed',
  'gamepadreleased', 'joystickadded', 'joystickaxis', 'joystickhat',
  'joystickpressed', 'joystickreleased', 'joystickremoved'
}

-- overides love's default events and binds venus' events in their place
function venus.registerEvents(timer)
  local registry = {}
  for _, f in ipairs(all_callbacks) do
    registry[f] = love[f] or function(...) end
    love[f] = function(...)
      registry[f](...)
      if f == 'draw' and states.tween.draw then
        states.tween.draw(...)
      elseif states.current[f] then
        states.current[f](...)
      end
    end
  end
end

-- switch to a state
function venus.switch(state, effect, duration)
  assert(state, "Missing argument: state")

  if next(states.current) == nil or effect == 'none' or duration == 0 then
    states.next = state
    states.switch()
  else
    duration = duration or venus.duration
    assert(duration >= 0, 'Transition duration must be greater or equal to zero.')

    effect = effect or venus.effect
    assert(transitions[effect], effect .. ' animation does not exist.')

    transitions[effect].run(state, duration)
  end
end

-- fade effect
transitions.fade.state = {}

function transitions.fade.state:draw(...)
  if transitions.fade.complete and states.next.draw then
    states.next.draw(...)
  elseif states.current.draw then
    states.current.draw(...)
  end

  love.graphics.setColor(0, 0, 0, transitions.fade.alpha)
  love.graphics.rectangle("fill", 0, 0, love.window.getDimensions())
  love.graphics.setColor(255,255,255)
end

function transitions.fade.run(state, duration)
  transitions.fade.alpha = 0
  transitions.fade.complete = false

  states.tween = transitions.fade.state
  states.next  = state

  if states.next.init then states.next.init() end
  states.next.init = nil

  local f = function()
    transitions.fade.complete = true
    venus.timer.tween(duration / 2, transitions.fade, { alpha = 0 }, "out-quad", function() states.switch() end)
  end

  venus.timer.tween(duration / 2, transitions.fade, { alpha = 255 }, "out-quad", f)
end

-- slide effect
transitions.slide.state = {}

function transitions.slide.state:draw(...)
  love.graphics.push()
  love.graphics.translate(transitions.slide.pos, 0)
  if states.current.draw then states.current.draw(...) end
  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(transitions.slide.pos + love.window.getWidth(), 0)
  if states.next.draw then states.next.draw(...) end
  love.graphics.pop()
end

function transitions.slide.run(state, duration)
  transitions.slide.pos = 0

  states.tween = transitions.slide.state
  states.next  = state

  if states.next.init then states.next.init() end
  states.next.init = nil

  venus.timer.tween(duration, transitions.slide, { pos = -love.window.getWidth() }, "out-quad", function() states.switch() end)
end

-- fall effect
transitions.fall.state = {}

function transitions.fall.state:draw(...)
  love.graphics.push()
  love.graphics.translate(0, transitions.fall.pos)
  if states.current.draw then states.current.draw(...) end
  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(0, transitions.fall.pos - love.window.getHeight())
  if states.next.draw then states.next.draw(...) end
  love.graphics.pop()
end

function transitions.fall.switch(to, duration)
  transitions.fall.pos = 0

  states.tween = transitions.fall.state
  states.next  = state

  if states.next.init then states.next.init() end
  states.next.init = nil

  venus.timer.tween(duration, transitions.fall, { pos = love.window.getHeight() }, "out-quint", function() states.switch() end)
end

return venus
