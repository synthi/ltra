-- code/ltra/lib/controls_enc.lua | v1.4.7
-- LTRA: Encoder Logic
-- FIX: Matrix E2 Quantize Toggle & Correct Mappings

local Enc = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Enc.init(g_ref) Globals = g_ref end

function Enc.delta(n, d)
    Globals.dirty = true
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        local m = Globals.menu_mode
        
        if m == Consts.MENU.OSC then
            if n==1 then params:delta("osc"..t.."_shape", d)
            elseif n==2 then params:delta("osc"..t.."_pan", d)
            elseif n==3 then params:delta("osc"..t.."_tune", d) end
            
        elseif m == Consts.MENU.LFO then
            if n==1 then params:delta("lfo"..t.."_shape", d)
            elseif n==2 then params:delta("lfo"..t.."_depth", d)
            elseif n==3 then params:delta("lfo"..t.."_rate", d) end
            
        elseif m == Consts.MENU.CHAOS then
            if n==1 then params:delta("chaos_rate", d)
            elseif n==2 then params:delta("chaos_slew", d)
            end
            
        elseif m == Consts.MENU.OUTLINE then
            if n==1 then params:delta("outline_src", d)
            elseif n==2 then params:delta("outline_gain", d) end
            
        elseif m == Consts.MENU.FILTER then
            if n==1 then 
                local p = (t==1) and "filt1_tone" or "filt2_tone"
                params:delta(p, d*0.1)
            elseif n==2 then 
                local p = (t==1) and "filt1_res" or "filt2_res"
                params:delta(p, d)
            elseif n==3 then params:delta("filt_drive", d) end
            
        elseif m == Consts.MENU.DELAY then
            if n==1 then params:delta("delay_spread", d)
            elseif n==2 then params:delta("tape_erosion", d)
            elseif n==3 then params:delta("tape_wow", d) end
            
        elseif m == Consts.MENU.REVERB then
            if n==1 then params:delta("reverb_mix", d)
            elseif n==2 then params:delta("reverb_decay", d)
            elseif n==3 then params:delta("reverb_damp", d) end
            
        elseif m == Consts.MENU.LOOPER then
            if n==1 then params:delta("loop"..t.."_send", d)
            elseif n==2 then params:delta("loop"..t.."_feedback", d)
            elseif n==3 then params:delta("loop"..t.."_vol", d) end
            
        elseif m == Consts.MENU.MATRIX then
            local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
            local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
            
            if src_idx and dst_idx then
                -- FIX: E2 Toggle Quantize (Solo si es destino Pitch 1-4)
                if n==2 and dst_idx <= 4 then
                    if d > 0 or d < 0 then 
                        local current_q = Globals.matrix_quant[src_idx][dst_idx]
                        local new_q = 1 - current_q
                        Globals.matrix_quant[src_idx][dst_idx] = new_q
                        
                        local idx = string.match(Globals.menu_target.dest_name, "(%d+)$") or ""
                        Bridge.set_matrix_quant(Globals.menu_target.src_name:lower(), "pitch", idx, new_q)
                    end
                end
                
                -- E3: Amount
                if n==3 then
                    local current = Globals.matrix[src_idx][dst_idx]
                    local new_val = util.clamp(current + d*0.01, 0, 1)
                    local id = "mat_"..Globals.menu_target.src_name.."_"..Globals.menu_target.dest_name
                    params:set(id, new_val)
                    
                    if Globals.ui_popup.active then
                        local q_str = (Globals.matrix_quant[src_idx][dst_idx] == 1) and "[Q]" or "[F]"
                        if dst_idx > 4 then q_str = "" end 
                        Globals.ui_popup.val = string.format("%.2f %s", new_val, q_str)
                        Globals.ui_popup.deadline = util.time() + 1.5
                    end
                end
            end
        end
        return
    end
    
    if n==1 then params:delta("output_level", d)
    elseif n==2 then params:delta("scale_idx", d)
    elseif n==3 then params:delta("scale_root", d) end
end

return Enc
