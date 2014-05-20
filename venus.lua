venus = {}
venus.current = "No state"
venus.noState = true

venus.currentFx = "slide"

--[[ 
List of transitions:

1) fade: Default one. Fades in to a black rectangle which covers whole screen, then fades out to the next state.
2) slide: Slides between states from right to left.
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

local transitions = require "lib.venus_transitions"

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
        if venus.currentFx ~= effect then venus.currentFx = effect end
        transitions[effect].switch(to)
    end
end

return venus
