--[[
License:
This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

    1- The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
    2- Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
    3- This notice may not be removed or altered from any source distribution.
]]--

local venus = {}

local function __NULL__() end

-- set some sensible defaults.
-- defaults can be set by referencing State.property when you set up your instance of Venus
venus.duration = 1       -- default duration for transitions.
venus.effect   = 'fade'  -- default transition effect
venus.timer    = Timer   -- sesible default for the HUMP.timer object.

-- set up an initial state or things will fall in a heap. produces error on every callback
venus.current  = {}
venus.no_state = true

--[[
List of transitions:

1) none: transition instantly. Same as duration = 0
2) fade: Default one. Fades in to a black rectangle which covers whole screen, then fades out to the next state.
3) slide: Slides between states from right to left.
4) fall: Similar to slide, but "falls" downwards and has a slightly different animation.
]]--
local transitions = {
  none = {},
  fade = {},
  slide = {},
  fall = {},
}

local all_callbacks = {
  'draw', 'errhand', 'focus', 'keypressed', 'keyreleased', 'mousefocus',
  'mousepressed', 'mousereleased', 'quit', 'resize', 'textinput',
  'threaderror', 'update', 'visible', 'gamepadaxis', 'gamepadpressed',
  'gamepadreleased', 'joystickadded', 'joystickaxis', 'joystickhat',
  'joystickpressed', 'joystickreleased', 'joystickremoved'
}

function venus.registerEvents(timer)
  local registry = {}
  for _, f in ipairs(all_callbacks) do
    registry[f] = love[f] or __NULL__
    love[f] = function(...)
      registry[f](...)
      return (venus.current[f] or __NULL__)(...)
    end
  end
end

function venus._switch(to, ...)
  assert(to, "Missing argument: Gamestate to switch to")

  local pre = venus.current
  ;(pre.leave or __NULL__)()

  ;(to.init or __NULL__)()
  to.init = nil

  ;(to.enter or __NULL__)()
  venus.current = to
end

function venus.switch(to, effect, duration)
  assert(to, "Missing argument: state to switch to")

  if next(venus.current) == nil or effect == 'none' or duration == 0 then
    venus._switch(to)
  else
    duration = duration or venus.duration
    assert(duration >= 0, 'Transition duration must be greater or equal to zero.')

    effect = effect or venus.effect
    assert(transitions[effect], effect .. ' animation does not exist.')

    transitions[effect].switch(to, duration)
  end
end

-- fade effect
transitions.fade.state = {}

function transitions.fade.state:draw()
  if transitions.fade.switched then
    _ = (transitions.fade.to.draw or __NULL__)()
  else
    _ = (transitions.fade.pre.draw or __NULL__)()
  end

  love.graphics.setColor(0, 0, 0, transitions.fade.alpha)
  love.graphics.rectangle("fill", 0, 0, love.window.getDimensions())
  love.graphics.setColor(255,255,255)
end

function transitions.fade.switch(to, duration, ...)
  transitions.fade.alpha = 0
  transitions.fade.switched = false
  transitions.fade.pre = venus.current
  transitions.fade.to = to

  ;(to.init or __NULL__)()
  to.init = nil

  venus._switch(transitions.fade.state)

  local f = function()
    transitions.fade.switched = true
    venus.timer.tween(duration / 2, transitions.fade, { alpha = 0 }, "out-quad", function() venus._switch(to) end)
  end

  venus.timer.tween(duration / 2, transitions.fade, { alpha = 255 }, "out-quad", f)
end

-- slide effect
transitions.slide.state = {}

function transitions.slide.state:draw()
  love.graphics.push()
  love.graphics.translate(transitions.slide.pos, 0)
  ;(transitions.slide.pre.draw or __NULL__)()
  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(transitions.slide.pos + love.window.getWidth(), 0)
  ;(transitions.slide.to.draw or __NULL__)()
  love.graphics.pop()
end

function transitions.slide.switch(to, duration, ...)
  transitions.slide.pos = 0
  transitions.slide.pre = venus.current
  transitions.slide.to = to

  ;(to.init or __NULL__)()
  to.init = nil

  venus._switch(transitions.slide.state)

  venus.timer.tween(duration, transitions.slide, { pos = -love.window.getWidth() }, "out-quad", function() venus._switch(to) end)
end

-- fall effect
transitions.fall.state = {}

function transitions.fall.state:draw()
  love.graphics.push()
  love.graphics.translate(0, transitions.fall.pos)
  ;(transitions.fall.pre.draw or __NULL__)()
  love.graphics.pop()

  love.graphics.push()
  love.graphics.translate(0, transitions.fall.pos - love.window.getHeight())
  ;(transitions.fall.to.draw or __NULL__)()
  love.graphics.pop()
end

function transitions.fall.switch(to, duration, ...)
  transitions.fall.pos = 0
  transitions.fall.pre = venus.current
  transitions.fall.to = to

  ;(to.init or __NULL__)()
  to.init = nil

  venus._switch(transitions.fall.state)

  venus.timer.tween(duration, transitions.fall, { pos = love.window.getHeight() }, "out-quint", function() venus._switch(to) end)
end

return venus
