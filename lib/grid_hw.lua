-- code/ltra/lib/grid_hw.lua | v0.8
-- LTRA: Hardware Abstraction Layer
-- FEATURES: Smart Redraw & Input Debounce

local GridHW = {}
local Globals; local Pages; local g
local next_frame = {}
local last_press_time = {} -- Tabla para Debounce

function GridHW.init(g_ref, dev, p_ref)
    Globals = g_ref
    Pages = p_ref
    g = grid.connect(dev)
    
    -- Inicializar buffers
    for x=1,16 do 
        next_frame[x]={} 
        last_press_time[x]={}
        for y=1,8 do 
            next_frame[x][y]=0 
            last_press_time[x][y]=0
        end 
    end
    
    g.key = function(x,y,z) 
        GridHW.handle_key(x,y,z) 
    end
end

function GridHW.led(x,y,v) 
    if x>=1 and x<=16 and y>=1 and y<=8 then
        next_frame[x][y]=math.floor(v) 
    end
end

function GridHW.redraw()
    if not g then return end
    
    -- 1. Solicitar renderizado lógico
    if Pages then Pages.redraw() end
    
    -- 2. Enviar diferencias al hardware
    for x=1,16 do for y=1,8 do
        if next_frame[x][y] ~= Globals.led_cache[x][y] then
            g:led(x,y,next_frame[x][y])
            Globals.led_cache[x][y]=next_frame[x][y]
        end
        next_frame[x][y]=0 -- Limpiar para siguiente ciclo
    end end
    g:refresh()
end

function GridHW.handle_key(x, y, z)
    local now = util.time()
    
    -- LÓGICA DEBOUNCE (Solo en pulsación z=1)
    if z == 1 then
        local last = last_press_time[x][y]
        if (now - last) < 0.05 then 
            -- Ignorar rebote (<50ms)
            return 
        end
        last_press_time[x][y] = now
    end
    
    -- Actualizar estado global
    Globals.button_state[x][y] = (z==1)
    
    -- Pasar evento a la lógica
    if Pages then Pages.key(x,y,z) end
end

return GridHW
