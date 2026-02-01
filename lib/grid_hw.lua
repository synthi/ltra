-- =============================================================================
-- PROJECT: LTRA
-- FILE: lib/grid_hw.lua
-- VERSION: v1.0 (Golden Master)
-- DESCRIPTION: Hardware Abstraction Layer (Debounce & Cache).
-- =============================================================================

local GridHW = {}
local Globals; local Pages; local g
local next_frame = {}
local last_press = {}

function GridHW.init(g_ref, dev, p_ref)
    Globals = g_ref; Pages = p_ref; g = grid.connect(dev)
    
    for x=1,16 do 
        next_frame[x]={} 
        last_press[x]={}
        for y=1,8 do 
            next_frame[x][y]=0 
            last_press[x][y]=0
        end 
    end
    
    g.key = function(x,y,z) GridHW.handle_key(x,y,z) end
end

function GridHW.led(x,y,v) 
    if x>=1 and x<=16 and y>=1 and y<=8 then
        next_frame[x][y]=math.floor(v) 
    end
end

function GridHW.redraw()
    if not g then return end
    if Pages then Pages.redraw() end
    
    for x=1,16 do for y=1,8 do
        if next_frame[x][y] ~= Globals.led_cache[x][y] then
            g:led(x,y,next_frame[x][y])
            Globals.led_cache[x][y]=next_frame[x][y]
        end
        next_frame[x][y]=0
    end end
    g:refresh()
end

function GridHW.handle_key(x, y, z)
    local now = util.time()
    -- Debounce (50ms) para evitar rebotes de hardware
    if z == 1 then
        if (now - last_press[x][y]) < 0.05 then return end
        last_press[x][y] = now
    end
    
    Globals.button_state[x][y] = (z==1)
    if Pages then Pages.key(x,y,z) end
end

return GridHW
