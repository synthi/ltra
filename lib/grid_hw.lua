-- =============================================================================
-- PROJECT: LTRA
-- FILE: lib/grid_hw.lua
-- VERSION: v1.4.8
-- DESCRIPTION: Hardware Abstraction Layer with Differential Cache & Boot Protection.
-- =============================================================================

local GridHW = {}
local Globals; local Pages; local g
local cache = {}

function GridHW.init(g_ref, dev, p_ref)
    Globals = g_ref; Pages = p_ref; g = grid.connect(dev)
    
    for x=1,16 do 
        cache[x]={} 
        for y=1,8 do 
            cache[x][y] = -1 
        end 
    end
    
    g.key = function(x,y,z) GridHW.handle_key(x,y,z) end
end

function GridHW.led(x,y,v) 
    if x>=1 and x<=16 and y>=1 and y<=8 then
        Globals.led_cache[x][y] = math.floor(v) 
    end
end

function GridHW.redraw()
    if not g then return end
    
    if Pages then Pages.redraw() end
    
    for x=1,16 do for y=1,8 do
        local new_val = Globals.led_cache[x][y]
        if cache[x][y] ~= new_val then
            g:led(x, y, new_val)
            cache[x][y] = new_val
        end
        Globals.led_cache[x][y] = 0 
    end end
    g:refresh()
end

function GridHW.handle_key(x, y, z)
    -- FIX 3.1: Boot Protection. Ignorar hardware si Lua no está 100% listo.
    if not Globals or not Globals.loaded then return end
    
    Globals.button_state[x][y] = (z==1)
    if Pages then 
        local status, err = pcall(Pages.key, x, y, z)
        if not status then print("Grid Error: " .. tostring(err)) end
    end
end

return GridHW
