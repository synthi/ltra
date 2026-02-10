-- code/ltra/lib/controls_enc.lua | v1.4.2
-- LTRA: Encoder Logic
-- FIX: Strict alignment with UI Labels (Delay/Reverb/Chaos)

local Enc = {}
local Globals
local Consts = require 'ltra/lib/consts'

function Enc.init(g_ref) Globals = g_ref end

function Enc.delta(n, d)
    Globals.dirty = true
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        local m = Globals.menu_mode
        
        if m == Consts.MENU.OSC then
            -- UI: Shape, Pan, Tune
            if n==1 then params:delta("osc"..t.."_shape", d)
            elseif n==2 then params:delta("osc"..t.."_pan", d)
            elseif n==3 then params:delta("osc"..t.."_tune", d) end
            
        elseif m == Consts.MENU.LFO then
            -- UI: Shape, Depth, Rate
            if n==1 then params:delta("lfo"..t.."_shape", d)
            elseif n==2 then params:delta("lfo"..t.."_depth", d)
            elseif n==3 then params:delta("lfo"..t.."_rate", d) end
            
        elseif m == Consts.MENU.CHAOS then
            -- UI: Rate, Slew
            if n==1 then params:delta("chaos_rate", d)
            elseif n==2 then params:delta("chaos_slew", d)
            end
            
        elseif m == Consts.MENU.OUTLINE then
            -- UI: Source
            if n==1 then params:delta("outline_src", d) end
            
        elseif m == Consts.MENU.FILTER then
            -- UI: Tone, Res, Drive
            if n==1 then 
                local p = (t==1) and "filt1_tone" or "filt2_tone"
                params:delta(p, d*0.1)
            elseif n==2 then 
                local p = (t==1) and "filt1_res" or "filt2_res"
                params:delta(p, d)
            elseif n==3 then params:delta("filt_drive", d) end
            
        elseif m == Consts.MENU.DELAY then
            -- UI LABELS: E1 Spread, E2 Erosion, E3 Wow/Flut
            -- CORRECCIÓN: Mapear exactamente a eso.
            if n==1 then params:delta("delay_spread", d)
            elseif n==2 then params:delta("tape_erosion", d)
            elseif n==3 then params:delta("tape_wow", d) end
            
        elseif m == Consts.MENU.REVERB then
            -- UI LABELS: E1 Dirt, E2 Decay, E3 Damp
            -- CORRECCIÓN: Mapear exactamente a eso.
            if n==1 then params:delta("system_dirt", d)
            elseif n==2 then params:delta("reverb_decay", d)
            elseif n==3 then params:delta("reverb_damp", d) end
            
        elseif m == Consts.MENU.LOOPER then
            -- UI: Send, Fdbk, Vol
            if n==1 then params:delta("loop"..t.."_send", d)
            elseif n==2 then params:delta("loop"..t.."_feedback", d)
            elseif n==3 then params:delta("loop"..t.."_vol", d) end
            
        elseif m == Consts.MENU.MATRIX then
            if n==3 then
                local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
                local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
                if src_idx and dst_idx then
                    local current = Globals.matrix[src_idx][dst_idx]
                    local new_val = util.clamp(current + d*0.01, 0, 1)
                    local id = "mat_"..Globals.menu_target.src_name.."_"..Globals.menu_target.dest_name
                    params:set(id, new_val)
                end
            end
        end
        return
    end
    
    -- MAIN PAGE
    if n==1 then params:delta("output_level", d)
    elseif n==2 then params:delta("scale_idx", d)
    elseif n==3 then params:delta("scale_root", d) end
end

return Enc
