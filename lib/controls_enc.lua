-- lib/controls_enc.lua | v2.8.2
-- FIX: Bifurcated Routing (Global vs Targeted) to prevent Ghost Multipliers

local Enc = {}
local Globals
local Consts = require 'ltra/lib/consts'

function Enc.init(g_ref) 
    Globals = g_ref 
    Enc.last_time = {}
end

function Enc.delta(n, d)
    Globals.dirty = true
    
    local now = util.time()
    local dt = now - (Enc.last_time[n] or 0)
    Enc.last_time[n] = now
    
    local accel = 1
    if dt < 0.03 then accel = 5
    elseif dt < 0.06 then accel = 2
    elseif dt > 0.15 then accel = 0.1 end 
    
    local function do_delta(id, delta_val)
        local p = params:lookup_param(id)
        if p and p.controlspec and p.controlspec.step == 0 then
            local range = p.controlspec.maxval - p.controlspec.minval
            local change = delta_val * accel * (range / 1000)
            params:set(id, p:get() + change)
        else
            params:delta(id, delta_val)
        end
    end
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local m = Globals.menu_mode
        
        -- FIX: GLOBAL MENUS (No loop, prevents Ghost Multiplier)
        if m == Consts.MENU.ARP then
            if Globals.arp_menu_page == 1 then
                if n==1 then do_delta("arp_gate_len", d)
                elseif n==2 then do_delta("arp_div", d)
                elseif n==3 then do_delta("arp_chaos", d) end
            else
                if n==1 then params:delta("clock_tempo", d)
                elseif n==2 then do_delta("arp_length", d)
                elseif n==3 then do_delta("arp_octaves", d) end
            end
            return
            
        elseif m == Consts.MENU.OUTLINE then
            if Globals.outline_menu_page == 1 then
                if n==2 then do_delta("outline_src", d)
                elseif n==3 then do_delta("outline_gain", d) end
            elseif Globals.outline_menu_page == 2 then
                if n==1 then do_delta("mod4_lfo_shape", d)
                elseif n==2 then 
                    if params:get("mod4_lfo_sync") == 1 then do_delta("mod4_lfo_div", d)
                    else do_delta("mod4_lfo_rate", d) end
                elseif n==3 then do_delta("mod4_depth", d) end
            else
                if n==1 then do_delta("mod4_chaos_slew", d)
                elseif n==2 then 
                    if params:get("mod4_chaos_sync") == 1 then do_delta("mod4_chaos_div", d)
                    else do_delta("mod4_chaos_rate", d) end
                elseif n==3 then do_delta("mod4_mix", d) end
            end
            return
            
        elseif m == Consts.MENU.DELAY then
            if Globals.delay_menu_page == 1 then
                if n==1 then do_delta("delay_send", d)
                elseif n==2 then do_delta("tapecho_time", d)
                elseif n==3 then do_delta("tapecho_feedback", d) end
            else
                if n==1 then do_delta("tapecho_drive", d)
                elseif n==2 then do_delta("tapecho_erosion", d)
                elseif n==3 then do_delta("tapecho_wow_flutter", d) end
            end
            return
            
        elseif m == Consts.MENU.REVERB then
            if Globals.reverb_menu_page == 1 then
                if n==1 then do_delta("reverb_mix", d)
                elseif n==2 then do_delta("blossomverb_bloom", d)
                elseif n==3 then do_delta("blossomverb_decay", d) end
            elseif Globals.reverb_menu_page == 2 then
                if n==2 then do_delta("blossomverb_predelay", d)
                elseif n==3 then do_delta("blossomverb_damp", d) end
            else
                if n==2 then do_delta("blossomverb_mod_rate", d)
                elseif n==3 then do_delta("blossomverb_mod_depth", d) end
            end
            return
            
        elseif m == Consts.MENU.LOOPER then 
            if n==1 then do_delta("system_dirt", d)
            elseif n==2 then do_delta("monitor_vol", d)
            elseif n==3 then do_delta("master_vol", d) end
            return
        end
        
        -- FIX: TARGETED MENUS (Loop over selected voices)
        local targets = {Globals.menu_target}
        if type(Globals.menu_target) == "table" then
            if Globals.menu_target.src_name then
                targets = {Globals.menu_target}
            else
                targets = Globals.menu_target
            end
        end
        
        for _, t in ipairs(targets) do
            if m == Consts.MENU.OSC then
                if Globals.osc_menu_page == 1 then
                    if n==1 then do_delta("osc"..t.."_tune", d)
                    elseif n==2 then do_delta("osc"..t.."_shape", d)
                    elseif n==3 then do_delta("osc"..t.."_octave", d) end
                elseif Globals.osc_menu_page == 2 then
                    if n==1 then do_delta("osc"..t.."_vol", d)
                    elseif n==2 then do_delta("osc"..t.."_drift", d)
                    elseif n==3 then do_delta("osc"..t.."_spread", d) end
                else
                    -- FIX: Added MIDI Quantization to E1
                    if n==1 then 
                        local curr = params:get("osc"..t.."_quant_midi")
                        params:set("osc"..t.."_quant_midi", 1-curr)
                    elseif n==2 then do_delta("osc"..t.."_glide", d) end
                end
                
            elseif m == Consts.MENU.ENV then
                if n==1 then do_delta("osc"..t.."_pan", d)
                elseif n==2 then do_delta("env_atk"..t, d)
                elseif n==3 then do_delta("env_rel"..t, d) end
                
            elseif m == Consts.MENU.MIDI then
                if Globals.midi_menu_page == 1 then
                    if n==1 then do_delta("osc"..t.."_vel_vol", d)
                    elseif n==2 then do_delta("osc"..t.."_vel_shp", d)
                    elseif n==3 then do_delta("osc"..t.."_vel_atk", d) end
                elseif Globals.midi_menu_page == 2 then
                    if n==1 then do_delta("mw_filt2", d)
                    elseif n==2 then do_delta("osc"..t.."_slide_vol", d)
                    elseif n==3 then do_delta("osc"..t.."_slide_shp", d) end
                else
                    if n==1 then do_delta("mw_delay_f", d)
                    elseif n==2 then do_delta("osc"..t.."_press_vol", d)
                    elseif n==3 then do_delta("osc"..t.."_press_shp", d) end
                end
                
            elseif m == Consts.MENU.MOD then
                if Globals.mod_menu_page == 1 then
                    if n==1 then do_delta("mod"..t.."_lfo_shape", d)
                    elseif n==2 then 
                        if params:get("mod"..t.."_lfo_sync") == 1 then do_delta("mod"..t.."_lfo_div", d)
                        else do_delta("mod"..t.."_lfo_rate", d) end
                    elseif n==3 then do_delta("mod"..t.."_depth", d) end
                else
                    if n==1 then do_delta("mod"..t.."_chaos_slew", d)
                    elseif n==2 then 
                        if params:get("mod"..t.."_chaos_sync") == 1 then do_delta("mod"..t.."_chaos_div", d)
                        else do_delta("mod"..t.."_chaos_rate", d) end
                    elseif n==3 then do_delta("mod"..t.."_mix", d) end
                end
                
            elseif m == Consts.MENU.FILTER then
                if n==1 then do_delta("filt"..t.."_drive", d)
                elseif n==2 then do_delta("filt"..t.."_cutoff", d)
                elseif n==3 then do_delta("filt"..t.."_res", d) end
                
            elseif m == Consts.MENU.MATRIX then
                local src_idx = Consts.SOURCES[t.src_name]
                local dst_idx = Consts.DESTINATIONS[t.dest_name]
                if src_idx and dst_idx then
                    if n==3 then
                        local current = Globals.matrix[src_idx][dst_idx]
                        local new_val = util.clamp(current + d*accel*0.005, -1, 1)
                        local id = "mat_"..t.src_name.."_"..t.dest_name
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
        end
        return
    end
    
    if n==1 then do_delta("master_vol", d)
    elseif n==2 then do_delta("scale_idx", d)
    elseif n==3 then do_delta("scale_root", d) end
end

return Enc
