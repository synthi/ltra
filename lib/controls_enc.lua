-- lib/controls_enc.lua | v1.5.14
-- FIX: ARP Menu Page 2, ENV Menu Pan

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
            if Globals.osc_menu_page == 1 then
                if n==1 then params:delta("osc"..t.."_octave", d)
                elseif n==2 then params:delta("osc"..t.."_shape", d)
                elseif n==3 then params:delta("osc"..t.."_tune", d) end
            else
                if n==1 then params:delta("osc"..t.."_drift", d)
                elseif n==2 then params:delta("osc"..t.."_spread", d)
                elseif n==3 then params:delta("osc"..t.."_vol", d) end
            end
            
        elseif m == Consts.MENU.ENV then
            if n==1 then params:delta("osc"..t.."_pan", d)
            elseif n==2 then params:delta("env_atk"..t, d)
            elseif n==3 then params:delta("env_rel"..t, d) end
            
        elseif m == Consts.MENU.MOD then
            if Globals.mod_menu_page == 1 then
                if n==1 then params:delta("mod"..t.."_lfo_shape", d)
                elseif n==2 then 
                    if params:get("mod"..t.."_lfo_sync") == 1 then
                        params:delta("mod"..t.."_lfo_div", d)
                    else
                        params:delta("mod"..t.."_lfo_rate", d) 
                    end
                elseif n==3 then params:delta("mod"..t.."_depth", d) end
            else
                if n==1 then params:delta("mod"..t.."_mix", d)
                elseif n==2 then 
                    if params:get("mod"..t.."_chaos_sync") == 1 then
                        params:delta("mod"..t.."_chaos_div", d)
                    else
                        params:delta("mod"..t.."_chaos_rate", d) 
                    end
                elseif n==3 then params:delta("mod"..t.."_chaos_slew", d) end
            end
            
        elseif m == Consts.MENU.ARP then
            if Globals.arp_menu_page == 1 then
                if n==1 then params:delta("arp_div", d)
                elseif n==2 then params:delta("arp_chaos", d)
                elseif n==3 then params:delta("arp_gate_len", d) end
            else
                if n==2 then params:delta("arp_length", d)
                elseif n==3 then params:delta("arp_octaves", d) end
            end
            
        elseif m == Consts.MENU.OUTLINE then
            if n==1 then params:delta("outline_src", d)
            elseif n==2 then params:delta("outline_gain", d) end
            
        elseif m == Consts.MENU.FILTER then
            if n==1 then params:delta("filt"..t.."_drive", d)
            elseif n==2 then params:delta("filt"..t.."_cutoff", d)
            elseif n==3 then params:delta("filt"..t.."_res", d) end
            
        elseif m == Consts.MENU.DELAY then
            if Globals.delay_menu_page == 1 then
                if n==1 then params:delta("delay_send", d)
                elseif n==2 then params:delta("tapecho_time", d)
                elseif n==3 then params:delta("tapecho_feedback", d) end
            else
                if n==1 then params:delta("tapecho_drive", d)
                elseif n==2 then params:delta("tapecho_erosion", d)
                elseif n==3 then params:delta("tapecho_wow_flutter", d) end
            end
            
        elseif m == Consts.MENU.REVERB then
            if Globals.reverb_menu_page == 1 then
                if n==1 then params:delta("reverb_mix", d)
                elseif n==2 then params:delta("blossomverb_decay", d)
                elseif n==3 then params:delta("blossomverb_bloom", d) end
            elseif Globals.reverb_menu_page == 2 then
                if n==1 then params:delta("blossomverb_damp", d)
                elseif n==2 then params:delta("blossomverb_predelay", d)
                elseif n==3 then params:delta("blossomverb_mod_rate", d) end
            else
                if n==1 then params:delta("blossomverb_mod_depth", d) end
            end
            
        elseif m == Consts.MENU.LOOPER then 
            if n==1 then params:delta("monitor_vol", d)
            elseif n==2 then params:delta("master_vol", d)
            elseif n==3 then params:delta("system_dirt", d) end
            
        elseif m == Consts.MENU.MATRIX then
            local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
            local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
            
            if src_idx and dst_idx then
                if n==3 then
                    local current = Globals.matrix[src_idx][dst_idx]
                    local new_val = util.clamp(current + d*0.01, -1, 1)
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
    
    if n==1 then params:delta("master_vol", d)
    elseif n==2 then params:delta("scale_idx", d)
    elseif n==3 then params:delta("scale_root", d) end
end

return Enc
