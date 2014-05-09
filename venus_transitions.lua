-- HUMP.Timer needed for tweens.
-- Don't forget to call Timer.update(dt) in love.update!
if not Timer then Timer = require "timer" end


local transitions = {}

-- SLIDE ----------------------
transitions.slide = {}
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

    Timer.tween(1, ts.pre, {x = -love.window.getWidth()}, "out-quad")
    Timer.tween(1, ts.to, {x = 0}, "out-quad", function() venus._switch(to) end)
end

transitions.slide.draw = function()
    ts.state:draw()
end


-- FADE ----------------------
transitions.fade = {}
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
    
    Timer.tween(0.3, tf.rect, {alpha = 255}, "out-quad", 
        function() 
            tf.switched = true 
            Timer.tween(0.3, tf.rect, {alpha = 0}, "out-quad", function() venus._switch(to) end)
        end
    )
end

transitions.fade.draw = function()
    tf.state:draw()
end

return transitions
