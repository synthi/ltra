-- code/ltra/lib/controls_enc.lua | v0.9.5
local Enc = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Enc.init(g_ref) Globals = g_ref end

function Enc.delta(n, d)
    Globals.dirty = true
    
    -- MODO MENÚ (Grid Hold)
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==1 then params:delta("osc"..t.."_shape", d)
            elseif n==2 then params:delta("osc"..t.."_pan", d)
            elseif n==3 then params:delta("osc"..t.."_tune", d) end
            
        elseif Globals.menu_mode == Consts.MENU.FILTER then
            if n==1 then 
                -- Fine Tune del filtro seleccionado
                local p = (t==1) and "filt1_tone" or "filt2_tone"
                params:delta(p, d*0.1) -- Movimiento lento
            elseif n==2 then 
                local p = (t==1) and "filt1_res" or "filt2_res"
                params:delta(p, d)
            elseif n==3 then params:delta("filt_drive", d) end
            
        elseif Globals.menu_mode == Consts.MENU.DELAY then
            if n==1 then params:delta("delay_time", d*0.1) -- Fine time
            elseif n==2 then params:delta("delay_fb", d)
            elseif n==3 then params:delta("delay_spread", d) end
            -- K2 Shift layer handled in controls_key if needed
            
        elseif Globals.menu_mode == Consts.MENU.REVERB then
            if n==1 then params:delta("reverb_mix", d)
            elseif n==2 then params:delta("reverb_decay", d)
            elseif n==3 then params:delta("system_dirt", d) end
            
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            if n==1 then params:delta("loop"..t.."_send", d)
            elseif n==2 then params:delta("loop"..t.."_feedback", d)
            elseif n==3 then params:delta("loop"..t.."_vol", d) end
            
        elseif Globals.menu_mode == Consts.MENU.MATRIX then
            -- Edición fina de la celda seleccionada (t.x, t.y)
            if n==3 then
                local src_idx = Consts.SOURCES[ t.src_name ] -- Need mapping back
                -- Simplificación: Matrix edit usa E3 para valor
                -- Requiere acceso directo a params ocultos
                -- Implementación compleja, fallback a visual por ahora
            end
        end
        return
    end
    
    -- NAVEGACIÓN STANDARD
    if n==1 then params:delta("output_level", d)
    elseif n==2 then params:delta("scale_idx", d)
    elseif n==3 then params:delta("scale_root", d) end
end
return Enc
