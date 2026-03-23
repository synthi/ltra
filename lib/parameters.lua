-- lib/parameters.lua | v1.5.5
-- FIX: Added Drift, Spread, Chaos Amp

local Params = {}
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'
local Scales = require 'ltra/lib/scales'

function Params.init(g_ref)
    local Globals = g_ref
    params:add_separator("LTRA v1.5.5")
    
    params:add_group("GLOBAL", 4)
    params:add_control("master_vol", "Master Vol", controlspec.new(0,1,"lin",0.01,1))
    params:set_action("master_vol", function(x) audio.level_dac(x) end)
    
    params:add_number("scale_idx", "Scale", 1, 32, 1)
    params:set_action("scale_idx", function(x) 
        if Globals then 
            Globals.scale.current_idx = x; 
            Globals.dirty=true 
            if Globals.loaded then Scales.update_all_voices() end
        end 
    end)
    
    params:add_number("scale_root", "Root Note", 1, 12, 1)
    params:set_action("scale_root", function(x) 
        if Globals then 
            Globals.scale.root_note = x; 
            Globals.dirty=true 
            if Globals.loaded then Scales.update_all_voices() end
        end 
    end)
    
    params:add_control("monitor_vol", "Monitor In", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("monitor_vol", function(x) audio.level_adc(x) end)

    for i=1,4 do
        params:add_group("VOICE "..i, 8) -- FIX: Increased to 8
        
        params:add_number("osc"..i.."_octave", "Octave", -2, 2, 0)
        params:set_action("osc"..i.."_octave", function(x)
            local p = params:get("osc"..i.."_pitch")
            local action = params:lookup_param("osc"..i.."_pitch").action
            if action then action(p) end
        end)
        
        params:add_control("osc"..i.."_pitch", "Pitch", controlspec.new(0,1,"lin",0,0.5))
        params:set_action("osc"..i.."_pitch", function(x)
            local deg = math.floor(x * 24)
            local hz = Scales.get_freq(deg, params:get("osc"..i.."_octave") or 0)
            local tune = params:get("osc"..i.."_tune") or 0
            hz = hz * (2 ^ (tune / 12))
            Bridge.set_freq(i, hz)
        end)
        
        params:add_control("osc"..i.."_vol", "Vol", controlspec.new(0,1,"lin",0.01,0.0))
        params:set_action("osc"..i.."_vol", function(x) if Globals then Globals.voices[i].vol=x end; Bridge.set_param("vol"..i, x) end)
        
        params:add_control("osc"..i.."_shape", "Shape", controlspec.new(0,4,"lin",0.01,2))
        params:set_action("osc"..i.."_shape", function(x) if Globals then Globals.voices[i].shape=x end; Bridge.set_param("shape"..i, x) end)
        
        params:add_control("osc"..i.."_tune", "Fine Tune", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("osc"..i.."_tune", function(x) 
            if Globals then Globals.voices[i].tune=x end
            if Globals and Globals.loaded then Scales.update_all_voices() end
        end)
        
        -- FIX: Drift and Spread
        params:add_control("osc"..i.."_drift", "Drift", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("osc"..i.."_drift", function(x) Bridge.set_param("drift"..i, x) end)
        
        params:add_control("osc"..i.."_spread", "Spread", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("osc"..i.."_spread", function(x) Bridge.set_param("spread"..i, x) end)
        
        params:add_binary("osc"..i.."_arp", "Arp Mode", "toggle", 0)
        params:set_action("osc"..i.."_arp", function(x) 
            if Globals then Globals.voices[i].arp_enabled=(x==1) end 
            if x == 0 then
                local p = params:get("osc"..i.."_pitch")
                local action = params:lookup_param("osc"..i.."_pitch").action
                if action then action(p) end
            end
        end)
    end
    
    params:add_group("ARP", 7)
    params:add_option("arp_div", "Clock Div", {"1/4", "1/8", "1/16", "1/32"}, 2)
    params:add_control("arp_chaos", "Chaos Prob", controlspec.new(0,1,"lin",0.01,0.2))
    params:add_binary("latch_mode", "Latch", "toggle", 0)
    params:set_action("latch_mode", function(x) if Globals then Globals.latch_mode=(x==1); Globals.dirty=true end end)
    for i=1,4 do
        params:add_control("arp_cv"..i, "Arp CV "..i, controlspec.new(0,1,"lin",0,0))
        params:hide("arp_cv"..i)
        params:set_action("arp_cv"..i, function(x) Bridge.set_param("arp_cv"..i, x) end)
    end

    params:add_group("FILTERS", 8)
    params:add_control("filt1_cutoff", "Filt 1 Cutoff", controlspec.new(20,18000,"exp",1,32))
    params:set_action("filt1_cutoff", function(x) Bridge.set_param("filt1_cutoff", x) end)
    params:add_control("filt2_cutoff", "Filt 2 Cutoff", controlspec.new(20,18000,"exp",1,14200))
    params:set_action("filt2_cutoff", function(x) Bridge.set_param("filt2_cutoff", x) end)
    params:add_control("filt1_res", "Filt 1 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt1_res", function(x) Bridge.set_param("filt1_res", x) end)
    params:add_control("filt2_res", "Filt 2 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt2_res", function(x) Bridge.set_param("filt2_res", x) end)
    params:add_binary("filt1_type", "Filt 1 Type (LP/HP)", "toggle", 1)
    params:set_action("filt1_type", function(x) Bridge.set_param("filt1_type", x) end)
    params:add_binary("filt2_type", "Filt 2 Type (LP/HP)", "toggle", 0)
    params:set_action("filt2_type", function(x) Bridge.set_param("filt2_type", x) end)
    params:add_control("filt1_drive", "Filt 1 Drive", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt1_drive", function(x) Bridge.set_param("filt1_drive", x) end)
    params:add_control("filt2_drive", "Filt 2 Drive", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt2_drive", function(x) Bridge.set_param("filt2_drive", x) end)

    params:add_group("MODULATION", 11) -- FIX: Increased to 11
    params:add_control("lfo1_rate", "LFO1 Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
    params:set_action("lfo1_rate", function(x) Bridge.set_param("lfo1_rate", x) end)
    params:add_control("lfo1_depth", "LFO1 Depth", controlspec.new(0,1,"lin",0.01,1))
    params:set_action("lfo1_depth", function(x) Bridge.set_param("lfo1_depth", x) end)
    params:add_control("lfo1_shape", "LFO1 Shape", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("lfo1_shape", function(x) Bridge.set_param("lfo1_shape", x) end)
    
    params:add_control("lfo2_rate", "LFO2 Rate", controlspec.new(0.01,20,"exp",0.01,0.2))
    params:set_action("lfo2_rate", function(x) Bridge.set_param("lfo2_rate", x) end)
    params:add_control("lfo2_depth", "LFO2 Depth", controlspec.new(0,1,"lin",0.01,1))
    params:set_action("lfo2_depth", function(x) Bridge.set_param("lfo2_depth", x) end)
    params:add_control("lfo2_shape", "LFO2 Shape", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("lfo2_shape", function(x) Bridge.set_param("lfo2_shape", x) end)
    
    params:add_control("chaos_rate", "Chaos Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
    params:set_action("chaos_rate", function(x) Bridge.set_param("chaos_rate", x) end)
    params:add_control("chaos_slew", "Chaos Slew", controlspec.new(0,1,"lin",0.01,0.1))
    params:set_action("chaos_slew", function(x) Bridge.set_param("chaos_slew", x) end)
    params:add_control("chaos_amp", "Chaos Amp", controlspec.new(0,1,"lin",0.01,1.0)) -- FIX: Chaos Amp
    params:set_action("chaos_amp", function(x) Bridge.set_param("chaos_amp", x) end)
    
    params:add_option("outline_src", "Outline Source", {"Internal Gates", "External Audio"}, 1)
    params:set_action("outline_src", function(x) Bridge.set_param("outline_source", x-1) end)
    params:add_control("outline_gain", "Outline Gain", controlspec.new(1, 20, "lin", 0.1, 1))
    params:set_action("outline_gain", function(x) Bridge.set_param("outline_gain", x) end)

    params:add_group("SPACE", 12)
    params:add_control("system_dirt", "Dirt", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("system_dirt", function(x) Bridge.set_param("system_dirt", x) end)
    params:add_control("dust_dens", "Dust", controlspec.new(0,50,"lin",0.1,0))
    params:set_action("dust_dens", function(x) Bridge.set_param("dust_dens", x) end)
    params:add_control("delay_time", "Delay Time", controlspec.new(0.01,2.0,"lin",0.01,0.5))
    params:set_action("delay_time", function(x) Bridge.set_param("delay_time", x) end)
    params:add_control("delay_fb", "Delay Feedback", controlspec.new(0,1.1,"lin",0.01,0))
    params:set_action("delay_fb", function(x) Bridge.set_param("delay_fb", x) end)
    params:add_control("delay_spread", "Spread", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("delay_spread", function(x) Bridge.set_param("delay_spread", x) end)
    params:add_control("delay_send", "Delay Send", controlspec.new(0,1,"lin",0.01,0.5))
    params:set_action("delay_send", function(x) Bridge.set_param("delay_send", x) end)
    params:add_control("tape_wow", "Wow", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_wow", function(x) Bridge.set_param("tape_wow", x) end)
    params:add_control("tape_flutter", "Flutter", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_flutter", function(x) Bridge.set_param("tape_flutter", x) end)
    params:add_control("tape_erosion", "Erosion", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_erosion", function(x) Bridge.set_param("tape_erosion", x) end)
    params:add_control("reverb_mix", "Reverb Mix", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("reverb_mix", function(x) Bridge.set_param("reverb_mix", x) end)
    params:add_control("reverb_decay", "Reverb Decay", controlspec.new(0.1,60,"exp",0.1,5))
    params:set_action("reverb_decay", function(x) Bridge.set_param("reverb_time", x) end)
    params:add_control("reverb_damp", "Reverb Damp", controlspec.new(0,1,"lin",0.01,0.5))
    params:set_action("reverb_damp", function(x) Bridge.set_param("reverb_damp", x) end)

    for s_name, s_idx in pairs(Consts.SOURCES) do
        for d_name, d_idx in pairs(Consts.DESTINATIONS) do
            local id = "mat_"..s_name.."_"..d_name
            params:add_control(id, id, controlspec.new(-1,1,"lin",0,0))
            params:hide(id)
            params:set_action(id, function(x) 
                if Globals then Globals.matrix[s_idx][d_idx] = x end
                local idx = string.match(d_name, "(%d+)$") or ""
                local bridge_dest = d_name:lower():gsub("%d", "")
                if bridge_dest == "filt" then bridge_dest = "filt" end 
                if bridge_dest == "morph" then bridge_dest = "shape" end 
                -- FIX: Delay strings match SC exactly
                if bridge_dest == "delay_t" then bridge_dest = "delay_time" end
                if bridge_dest == "delay_f" then bridge_dest = "delay_fb" end
                Bridge.set_matrix(s_name:lower(), bridge_dest, idx, x)
            end)
        end
    end
end

return Params
