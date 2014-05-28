--[[
License:
This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

    1- The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
    2- Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
    3- This notice may not be removed or altered from any source distribution. 
]]--

venus = {}
venus.current = "No state"
venus.noState = true

venus.currentFx = "fade"

local transitions = {
    fade = {},
    slide = {},
    fall = {}
}
--[[ 
List of transitions:

1) fade: Default one. Fades in to a black rectangle which covers whole screen, then fades out to the next state.
2) slide: Slides between states from right to left.
3) fall: Similar to slide, but "falls" downwards and has a slightly different animation.
]]--

local all_callbacks = {
	"update", "draw", "focus", "keypressed", "keyreleased",
	"mousepressed", "mousereleased", "joystickpressed",
	"joystickreleased", "textinput", "quit"
}

function venus.registerEvents()
    for _,callback in pairs(all_callbacks) do
        local backupFunc = love[callback]
        love[callback] = function(...)
            if backupFunc then backupFunc(...) end
            if venus.current[callback] then venus.current[callback](self, ...) end
        end
    end
end

-- globalCalls: Add your functions which you want to be called with every state's callback
-- NOTE: Must be one of the callbacks from the all_callbacks list
--[[ Example: 
    venus.globalCalls = {
        update = function() print("test...") end, -- this will call print("test...") every frame.
    }
]]--

venus.globalCalls = {
}

function venus._switch(to, ...)
    -- internal switch function which directly switches without any transitions
    if venus.current.leave then venus.current.leave() end
    
    if to.init then to.init() end
    to.init = nil
    
    if to.enter then to.enter(venus.current, ...) end
    venus.current = to
    
    for _,callback in pairs(all_callbacks) do
        venus[callback] = function(...)
            if venus.current[callback] then
                
                for k,v in pairs(venus.globalCalls) do
                    if callback == k then
                        local backupFunc = venus.current[callback] 
                        
                        venus.current[callback] = function(self, ...)
                            v()
                            backupFunc()
                        end
                    end
                end
                
                if venus.noState then
                    venus.current[callback](self, ...)
                else                    
                    if callback == "draw" then
                        venus.current[callback](self, ...)
                        transitions[venus.currentFx].draw()
                    else
                        venus.current[callback](self, ...)
                    end
                end
            end
        end
    end
    
    venus.noState = false
end

function venus.switch(to, effect)
    if venus.noState then
        venus._switch(to)
    else
        local effect = effect or venus.currentFx
        assert(transitions[effect], '"'..effect..'"'.." animation does not exist.")
        
        if venus.currentFx ~= effect then venus.currentFx = effect end
        transitions[effect].switch(to)
    end
end

--#################--
--###--EFFECTS--###--

-- uncomment if you already use HUMP.Timer
-- venus.timer = Timer

-- SLIDE ----------------------
local ts = transitions.slide

transitions.slide.state = {}

function transitions.slide.state:draw()
    if ts.pre then
        love.graphics.push()
        love.graphics.translate(ts.pre.x, ts.pre.y)
        if ts.pre.state.draw then ts.pre.state:draw() end
        love.graphics.pop()
    end
    
    if ts.to then 
        love.graphics.push()
        love.graphics.translate(ts.to.x, ts.to.y)
        if ts.to.state.draw then ts.to.state:draw() end
        love.graphics.pop()
    end
end

transitions.slide.switch = function(to, ...)
    ts.pre = {x = 0, y = 0, state = venus.current}
    ts.to = {x = love.window.getWidth(), y = 0, state = to}  
    
    if to.init then to.init(); to.init = nil end
    venus._switch(ts.state)

    venus.timer.tween(1, ts.pre, {x = -love.window.getWidth()}, "out-quad")
    venus.timer.tween(1, ts.to, {x = 0}, "out-quad", function() venus._switch(to) end)
end

transitions.slide.draw = function()
    ts.state:draw()
end


-- FADE ----------------------
local tf = transitions.fade

tf.rect = {
    color = {10,10,10},
    alpha = 0
}

tf.state = {}

function tf.state:draw()
    if tf.switched then
        if tf.to then 
            if tf.to.draw then tf.to:draw() end
        end
    else
        if tf.pre then
            if tf.pre.draw then tf.pre:draw() end
        end
    end
    
    love.graphics.setColor(tf.rect.color[1], tf.rect.color[2], tf.rect.color[3], tf.rect.alpha)
    love.graphics.rectangle("fill", 0, 0, love.window.getDimensions())
    love.graphics.setColor(255,255,255)
end

transitions.fade.switch = function(to, ...)
    tf.switched = false
    tf.pre = venus.current
    tf.to = to
    
    if to.init then to.init(); to.init = nil end
    venus._switch(tf.state)
    
    venus.timer.tween(0.3, tf.rect, {alpha = 255}, "out-quad", 
        function() 
            tf.switched = true 
            venus.timer.tween(0.3, tf.rect, {alpha = 0}, "out-quad", function() venus._switch(to) end)
        end
    )
end

transitions.fade.draw = function()
    tf.state:draw()
end

-- FALL ----------
local tfall = transitions.fall

tfall.state = {}

function tfall.state:draw()
    love.graphics.push()
    love.graphics.translate(0, tfall.y)
    
    if tfall.pre then
        if tfall.pre.draw then tfall.pre:draw() end
    end
    
    if tfall.to then
        love.graphics.push()
        love.graphics.translate(0,-love.window.getHeight())
        if tfall.to.draw then tfall.to:draw() end
        love.graphics.pop()
    end

    love.graphics.pop()
end

tfall.switch = function(to, ...)
    tfall.pre = venus.current
    tfall.to = to
    
    tfall.y = 0
    
    if to.init then to.init(); to.init = nil end
    venus._switch(tfall.state)

    venus.timer.tween(1.8, tfall, {y = love.window.getHeight()}, "out-quint", function() venus._switch(to) end)
end

tfall.draw = function()
    tfall.state:draw()
end


--###############--
--###--TIMER--###--

--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--
local Timer = {}
Timer.__index = Timer

local function _nothing_() end

local function new()
	return setmetatable({functions = {}, tween = Timer.tween}, Timer)
end

function Timer:update(dt)
	local to_remove = {}
	for handle, delay in pairs(self.functions) do
		delay = delay - dt
		if delay <= 0 then
			to_remove[#to_remove+1] = handle
		end
		self.functions[handle] = delay
		handle.func(dt, delay)
	end
	for _,handle in ipairs(to_remove) do
		self.functions[handle] = nil
		handle.after(handle.after)
	end
end

function Timer:do_for(delay, func, after)
	local handle = {func = func, after = after or _nothing_}
	self.functions[handle] = delay
	return handle
end

function Timer:add(delay, func)
	return self:do_for(delay, _nothing_, func)
end

function Timer:addPeriodic(delay, func, count)
	local count, handle = count or math.huge -- exploit below: math.huge - 1 = math.huge

	handle = self:add(delay, function(f)
		if func(func) == false then return end
		count = count - 1
		if count > 0 then
			self.functions[handle] = delay
		end
	end)
	return handle
end

function Timer:cancel(handle)
	self.functions[handle] = nil
end

function Timer:clear()
	self.functions = {}
end

Timer.tween = setmetatable({
	-- helper functions
	out = function(f) -- 'rotates' a function
		return function(s, ...) return 1 - f(1-s, ...) end
	end,
	chain = function(f1, f2) -- concatenates two functions
		return function(s, ...) return (s < .5 and f1(2*s, ...) or 1 + f2(2*s-1, ...)) * .5 end
	end,

	-- useful tweening functions
	linear = function(s) return s end,
	quad   = function(s) return s*s end,
	cubic  = function(s) return s*s*s end,
	quart  = function(s) return s*s*s*s end,
	quint  = function(s) return s*s*s*s*s end,
	sine   = function(s) return 1-math.cos(s*math.pi/2) end,
	expo   = function(s) return 2^(10*(s-1)) end,
	circ   = function(s) return 1 - math.sqrt(1-s*s) end,

	back = function(s,bounciness)
		bounciness = bounciness or 1.70158
		return s*s*((bounciness+1)*s - bounciness)
	end,

	bounce = function(s) -- magic numbers ahead
		local a,b = 7.5625, 1/2.75
		return math.min(a*s^2, a*(s-1.5*b)^2 + .75, a*(s-2.25*b)^2 + .9375, a*(s-2.625*b)^2 + .984375)
	end,

	elastic = function(s, amp, period)
		amp, period = amp and math.max(1, amp) or 1, period or .3
		return (-amp * math.sin(2*math.pi/period * (s-1) - math.asin(1/amp))) * 2^(10*(s-1))
	end,
}, {

-- register new tween
__call = function(tween, self, len, subject, target, method, after, ...)
	-- recursively collects fields that are defined in both subject and target into a flat list
	local function tween_collect_payload(subject, target, out)
		for k,v in pairs(target) do
			local ref = subject[k]
			assert(type(v) == type(ref), 'Type mismatch in field "'..k..'".')
			if type(v) == 'table' then
				tween_collect_payload(ref, v, out)
			else
				local ok, delta = pcall(function() return (v-ref)*1 end)
				assert(ok, 'Field "'..k..'" does not support arithmetic operations')
				out[#out+1] = {subject, k, delta}
			end
		end
		return out
	end

	method = tween[method or 'linear'] -- see __index
	local payload, t, args = tween_collect_payload(subject, target, {}), 0, {...}

	local last_s = 0
	return self:do_for(len, function(dt)
		t = t + dt
		local s = method(math.min(1, t/len), unpack(args))
		local ds = s - last_s
		last_s = s
		for _, info in ipairs(payload) do
			local ref, key, delta = unpack(info)
			ref[key] = ref[key] + delta * ds
		end
	end, after)
end,

-- fetches function and generated compositions for method `key`
__index = function(tweens, key)
	if type(key) == 'function' then return key end

	assert(type(key) == 'string', 'Method must be function or string.')
	if rawget(tweens, key) then return rawget(tweens, key) end

	local function construct(pattern, f)
		local method = rawget(tweens, key:match(pattern))
		if method then return f(method) end
		return nil
	end

	local out, chain = rawget(tweens,'out'), rawget(tweens,'chain')
	return construct('^in%-([^-]+)$', function(...) return ... end)
	       or construct('^out%-([^-]+)$', out)
	       or construct('^in%-out%-([^-]+)$', function(f) return chain(f, out(f)) end)
	       or construct('^out%-in%-([^-]+)$', function(f) return chain(out(f), f) end)
	       or error('Unknown interpolation method: ' .. key)
end})

-- default timer
local default = new()

-- the module
venus.timer = setmetatable({
	new         = new,
	update      = function(...) return default:update(...) end,
	do_for      = function(...) return default:do_for(...) end,
	add         = function(...) return default:add(...) end,
	addPeriodic = function(...) return default:addPeriodic(...) end,
	cancel      = function(...) return default:cancel(...) end,
	clear       = function(...) return default:clear(...) end,
	tween       = setmetatable({}, {
		__index    = Timer.tween,
		__newindex = function(_,k,v) Timer.tween[k] = v end,
		__call     = function(t,...) return default:tween(...) end,
	})
}, {__call = new})


return venus
