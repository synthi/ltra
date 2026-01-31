-- =============================================================================
-- PROJECT: LTRA
-- FILE: lib/controls_enc.lua
-- VERSION: v1.0 (Golden Master)
-- DESCRIPTION: Gestión de Encoders para Menús Contextuales y Navegación.
-- =============================================================================

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
                local p = (t==1) and "filt1_tone" or "filt2_tone"
                params:delta(p, d*0.1) -- Fine tune
            elseif n==2 then 
                local p = (t==1) and "filt1_res" or "filt2_res"
                params:delta(p, d)
            elseif n==3 then params:delta("filt_drive", d) end
            
        elseif Globals.menu_mode == Consts.MENU.DELAY then
            if n==1 then params:delta("delay_time", d*0.1)
            elseif n==2 then params:delta("delay_fb", d)
            elseif n==3 then params:delta("delay_spread", d) end
            
        elseif Globals.menu_mode == Consts.MENU.REVERB then
            if n==1 then params:delta("reverb_mix", d)
            elseif n==2 then params:delta("reverb_decay", d)
            elseif n==3 then params:delta("system_dirt", d) end
            
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            if n==1 then params:delta("loop"..t.."_send", d)
            elseif n==2 then params:delta("loop"..t.."_feedback", d)
            elseif n==3 then params:delta("loop"..t.."_vol", d) end
            
        elseif Globals.menu_mode == Consts.MENU.MATRIX then
            -- Edición fina de matriz (E3)
            if n==3 then
                local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
                local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
                if src_idx and dst_idx then
                    local current = Globals.matrix[src_idx][dst_idx]
                    local new_val = util.clamp(current + d*0.01, 0, 1)
                    -- Actualizar vía params ocultos
                    local id = "mat_"..Globals.menu_target.src_name.."_"..Globals.menu_target.dest_name
                    params:set(id, new_val)
                end
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
