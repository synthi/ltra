-- =============================================================================
-- PROJECT: LTRA
-- FILE: lib/grid_hw.lua
-- VERSION: v1.4.7 (Ncoco Doctrine)
-- DESCRIPTION: Hardware Abstraction Layer with Differential Cache.
-- =============================================================================

local GridHW = {}
local Globals; local Pages; local g
local cache = {} -- Differential Cache

function GridHW.init(g_ref, dev, p_ref)
    Globals = g_ref; Pages = p_ref; g = grid.connect(dev)
    
    -- Init Cache
    for x=1,16 do 
        cache[x]={} 
        for y=1,8 do 
            cache[x][y] = -1 -- Force update on first frame
        end 
    end
    
    g.key = function(x,y,z) GridHW.handle_key(x,y,z) end
end

function GridHW.led(x,y,v) 
    -- We don't send LED commands here anymore.
    -- We just update the 'next_frame' buffer in Globals if needed,
    -- but actually, Pages.redraw calls this.
    -- To support the 'ncoco' style, we need to intercept the call.
    
    -- In LTRA architecture, Pages.redraw calls led_safe which calls HW.led.
    -- We will store the value in a temporary buffer for this frame.
    if x>=1 and x<=16 and y>=1 and y<=8 then
        Globals.led_cache[x][y] = math.floor(v) -- Using existing led_cache as 'next_frame'
    end
end

function GridHW.redraw()
    if not g then return end
    
    -- 1. Calculate Next Frame (Logic)
    if Pages then Pages.redraw() end
    
    -- 2. Differential Update (Hardware)
    for x=1,16 do for y=1,8 do
        local new_val = Globals.led_cache[x][y]
        if cache[x][y] ~= new_val then
            g:led(x, y, new_val)
            cache[x][y] = new_val
        end
        -- Reset for next frame (optional, depending on logic style, 
        -- but LTRA clears frame usually)
        Globals.led_cache[x][y] = 0 
    end end
    g:refresh()
end

function GridHW.handle_key(x, y, z)
    -- Direct pass-through, debounce handled in Pages if needed
    Globals.button_state[x][y] = (z==1)
    if Pages then Pages.key(x,y,z) end
end

return GridHW
