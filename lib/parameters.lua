-- code/ltra/lib/parameters.lua | v1.4.8
-- LTRA: Parameters
-- FIX: Forced Scales.update_all_voices() on scale/root change

local Params = {}
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'
local Scales = require 'ltra/lib/scales'

function Params.init(g_ref)
    local Globals = g_ref
    params:add_separator("LTRA v1.4.8")
    
    params:add_group("GLOBAL", 5)
    params:add_control("output_level", "Master Vol", controlspec.new(0,1,"lin",0.01,1))
    params:set_action("output_level", function(x) _norns.audio.level_dac(x) end)
    
    params:add_number("scale_idx", "Scale", 1, 30, 1)
    params:set_action("scale_idx", function(x) 
        if Globals then 
            Globals.scale.current_idx = x; 
            Globals.dirty=true 
            -- FIX 3.1: Actualizar voces inmediatamente
            Scales.update_all_voices()
        end 
    end)
    
    params:add_number("scale_root", "Root Note", 1, 12, 1)
    params:set_action("scale_root", function(x) 
        if Globals then 
            Globals.scale.root_note = x; 
            Globals.dirty=true 
            -- FIX 3.1: Actualizar voces inmediatamente
            Scales.update_all_voices()
        end 
    end)
    
    params:add_control("monitor_level", "Monitor In", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("monitor_level", function(x) _norns.audio.level_adc(x) end)
    params:add_control("loop_return", "Global Loop Return", controlspec.new(0,1,"lin",0.01,1))
    params:set_action("loop_return", function(x) Bridge.set_param("loop_return_level", x) end)

    for i=1,4 do
        params:add_group("VOICE "..i, 7)
        params:add_control("osc"..i.."_pitch", "Pitch", controlspec.new(0,1,"lin",0,0.5))
        params:set_action("osc"..i.."_pitch", function(x)
            local deg = math.floor(x * 60)
            local hz = Scales.get_freq(deg, 0)
            local tune = params:get("osc"..i.."_tune") or 0
            hz = hz * (2 ^ (tune / 12))
            Bridge.set_freq(i, hz)
        end)
        params:add_control("osc"..i.."_vol", "Vol", controlspec.new(0,1,"lin",0.01,0.8))
        params:set_action("osc"..i.."_vol", function(x) if Globals then Globals.voices[i].vol=x end; Bridge.set_param("vol"..i, x) end)
        params:add_control("osc"..i.."_pan", "Pan", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("osc"..i.."_pan", function(x) if Globals then Globals.voices[i].pan=x end; Bridge.set_param("pan"..i, x) end)
        params:add_control("osc"..i.."_shape", "Shape", controlspec.new(0,4,"lin",0.01,0))
        params:set_action("osc"..i.."_shape", function(x) if Globals then Globals.voices[i].shape=x end; Bridge.set_param("shape"..i, x) end)
        params:add_control("osc"..i.."_tune", "Fine Tune", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("osc"..i.."_tune", function(x) if Globals then Globals.voices[i].tune=x end; Scales.update_all_voices() end)
        params:add_binary("osc"..i.."_arp", "Arp Mode", "toggle", 0)
        params:set_action("osc"..i.."_arp", function(x) if Globals then Globals.voices[i].arp_enabled=(x==1) end end)
        params:add_binary("osc"..i.."_route", "To Looper", "toggle", 1)
        params:set_action("osc"..i.."_route", function(x) if Globals then Globals.voices[i].to_looper=(x==1) end end)
    end
    
    params:add_group("ARP", 8)
    params:add_option("arp_div", "Clock Div", {"1/4", "1/8", "1/16", "1/32"}, 2)
    params:add_control("arp_chaos", "Chaos Prob", controlspec.new(0,1,"lin",0.01,0.2))
    params:add_binary("latch_mode", "Latch", "toggle", 0)
    params:set_action("latch_mode", function(x) if Globals then Globals.latch_mode=(x==1); Globals.dirty=true end end)
    for i=1,4 do
        params:add_control("arp_cv"..i, "Arp CV "..i, controlspec.new(0,1,"lin",0,0))
        params:hide("arp_cv"..i)
        params:set_action("arp_cv"..i, function(x) Bridge.set_param("arp_cv"..i, x) end)
    end

    params:add_group("FILTERS", 6)
    params:add_control("filt1_tone", "Filt 1 Tone", controlspec.new(-1,1,"lin",0.01,0))
    params:set_action("filt1_tone", function(x) Bridge.set_filter_tone(1, x) end)
    params:add_control("filt2_tone", "Filt 2 Tone", controlspec.new(-1,1,"lin",0.01,0))
    params:set_action("filt2_tone", function(x) Bridge.set_filter_tone(2, x) end)
    params:add_control("filt1_res", "Filt 1 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt1_res", function(x) Bridge.set_param("filt1_res", x) end)
    params:add_control("filt2_res", "Filt 2 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt2_res", function(x) Bridge.set_param("filt2_res", x) end)
    params:add_control("filt_drive", "Drive", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt_drive", function(x) Bridge.set_param("filt1_drive", x); Bridge.set_param("filt2_drive", x) end)
    params:add_binary("filt_type", "Type", "toggle", 0)
    params:set_action("filt_type", function(x) Bridge.set_param("filt_type", x) end)

    params:add_group("MODULATION", 10)
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

    params:add_group("LOOPERS", 18)
    for i=1,3 do
        params:add_separator("Looper "..i)
        params:add_control("loop"..i.."_vol", "Vol", controlspec.new(0,1,"lin",0.01,0.8))
        params:set_action("loop"..i.."_vol", function(x) if Globals then Globals.tracks[i].vol = x end end)
        params:add_control("loop"..i.."_speed", "Speed", controlspec.new(-2,2,"lin",0.01,1))
        params:set_action("loop"..i.."_speed", function(x) if Globals then Globals.tracks[i].speed = x end end)
        params:add_control("loop"..i.."_pan", "Pan", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("loop"..i.."_pan", function(x) if Globals then Globals.tracks[i].pan = x end end)
        params:add_control("loop"..i.."_feedback", "Feedback", controlspec.new(0,1,"lin",0.01,1))
        params:set_action("loop"..i.."_feedback", function(x) if Globals then Globals.tracks[i].feedback = x end end)
        params:add_control("loop"..i.."_send", "Send Space", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("loop"..i.."_send", function(x) if Globals then Globals.tracks[i].send_space = x end end)
        params:add_binary("loop"..i.."_pre", "Pre/Post", "toggle", 0)
        params:set_action("loop"..i.."_pre", function(x) if Globals then Globals.tracks[i].pre_fx = (x==1) end end)
    end

    for s_name, s_idx in pairs(Consts.SOURCES) do
        for d_name, d_idx in pairs(Consts.DESTINATIONS) do
            local id = "mat_"..s_name.."_"..d_name
            params:add_control(id, id, controlspec.new(0,1,"lin",0,0))
            params:hide(id)
            params:set_action(id, function(x) 
                if Globals then Globals.matrix[s_idx][d_idx] = x end
                local idx = string.match(d_name, "(%d+)$") or ""
                local bridge_dest = d_name:lower():gsub("%d", "")
                if bridge_dest == "delay_t" then bridge_dest = "delay_time" end
                if bridge_dest == "delay_f" then bridge_dest = "delay_fb" end
                if bridge_dest == "filt" then bridge_dest = "filt" end 
                Bridge.set_matrix(s_name:lower(), bridge_dest, idx, x)
            end)
        end
    end
end

return Params
