-- lib/parameters.lua | v1.5.13
-- FIX: Added VCO Pan, Added Loopers Group

local Params = {}
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'
local Scales = require 'ltra/lib/scales'
local Loopers = require 'ltra/lib/loopers' -- FIX: Require Loopers for actions

function Params.init(g_ref)
    local Globals = g_ref
    params:add_separator("LTRA v1.5.13")
    
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
        params:add_group("VOICE "..i, 11) -- FIX: Increased to 11 for Pan
        
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
        
        -- FIX: Added VCO Pan
        params:add_control("osc"..i.."_pan", "Pan", controlspec.new(-1,1,"lin",0.01,0.0))
        params:set_action("osc"..i.."_pan", function(x) Bridge.set_param("pan"..i, x) end)
        
        params:add_control("osc"..i.."_shape", "Shape", controlspec.new(0,4,"lin",0.01,2))
        params:set_action("osc"..i.."_shape", function(x) if Globals then Globals.voices[i].shape=x end; Bridge.set_param("shape"..i, x) end)
        
        params:add_control("osc"..i.."_tune", "Fine Tune", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("osc"..i.."_tune", function(x) 
            if Globals then Globals.voices[i].tune=x end
            if Globals and Globals.loaded then Scales.update_all_voices() end
        end)
        
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
        
        params:add_control("env_atk"..i, "Attack", controlspec.new(0.001, 5.0, "exp", 0.01, 0.01))
        params:set_action("env_atk"..i, function(x) Bridge.set_param("env_atk"..i, x) end)
        params:add_control("env_rel"..i, "Release", controlspec.new(0.001, 11.0, "exp", 0.01, 0.2))
        params:set_action("env_rel"..i, function(x) Bridge.set_param("env_rel"..i, x) end)
    end
    
    local sync_opts = {}
    for _, v in ipairs(Consts.SYNC_DIVS) do table.insert(sync_opts, v.name) end

    params:add_group("ARP", 10)
    params:add_option("arp_div", "Clock Div", sync_opts, 10) 
    params:add_control("arp_chaos", "Chaos Prob", controlspec.new(0,1,"lin",0.01,0.2))
    params:add_number("arp_length", "Length", 1, 8, 8)
    params:add_number("arp_octaves", "Octaves", 1, 3, 1)
    params:add_control("arp_gate_len", "Gate Length", controlspec.new(0.1, 1.0, "lin", 0.01, 0.5))
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

    params:add_group("MODULATION", 32) 
    for i=1, 3 do
        params:add_binary("mod"..i.."_lfo_sync", "MOD"..i.." LFO Sync", "toggle", 0)
        params:add_option("mod"..i.."_lfo_div", "MOD"..i.." LFO Div", sync_opts, 10)
        params:add_control("mod"..i.."_lfo_rate", "MOD"..i.." LFO Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
        params:set_action("mod"..i.."_lfo_rate", function(x) if params:get("mod"..i.."_lfo_sync")==0 then Bridge.set_param("mod"..i.."_lfo_rate", x) end end)
        params:add_control("mod"..i.."_lfo_shape", "MOD"..i.." LFO Shape", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("mod"..i.."_lfo_shape", function(x) Bridge.set_param("mod"..i.."_lfo_shape", x) end)
        params:add_control("mod"..i.."_depth", "MOD"..i.." Depth", controlspec.new(0,1,"lin",0.01,1))
        params:set_action("mod"..i.."_depth", function(x) Bridge.set_param("mod"..i.."_depth", x) end)
        
        params:add_binary("mod"..i.."_chaos_sync", "MOD"..i.." Chaos Sync", "toggle", 0)
        params:add_option("mod"..i.."_chaos_div", "MOD"..i.." Chaos Div", sync_opts, 10)
        params:add_control("mod"..i.."_chaos_rate", "MOD"..i.." Chaos Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
        params:set_action("mod"..i.."_chaos_rate", function(x) if params:get("mod"..i.."_chaos_sync")==0 then Bridge.set_param("mod"..i.."_chaos_rate", x) end end)
        params:add_control("mod"..i.."_chaos_slew", "MOD"..i.." Chaos Slew", controlspec.new(0,1,"lin",0.01,0.1))
        params:set_action("mod"..i.."_chaos_slew", function(x) Bridge.set_param("mod"..i.."_chaos_slew", x) end)
        
        params:add_control("mod"..i.."_mix", "MOD"..i.." Mix", controlspec.new(0,1,"lin",0.01,0.0)) 
        params:set_action("mod"..i.."_mix", function(x) Bridge.set_param("mod"..i.."_mix", x) end)
    end
    
    params:add_option("outline_src", "Outline Source", {"Internal Gates", "External Audio"}, 1)
    params:set_action("outline_src", function(x) Bridge.set_param("outline_source", x-1) end)
    params:add_control("outline_gain", "Outline Gain", controlspec.new(1, 20, "lin", 0.1, 1))
    params:set_action("outline_gain", function(x) Bridge.set_param("outline_gain", x) end)

    params:add_group("SPACE", 16) 
    params:add_control("system_dirt", "Dirt", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("system_dirt", function(x) Bridge.set_param("system_dirt", x) end)
    params:add_control("dust_dens", "Dust", controlspec.new(0,50,"lin",0.1,0))
    params:set_action("dust_dens", function(x) Bridge.set_param("dust_dens", x) end)
    
    params:add_control("delay_send", "Delay Send", controlspec.new(0,1,"lin",0.01,0.5))
    params:set_action("delay_send", function(x) Bridge.set_param("delay_send", x) end)
    
    params:add_control("tapecho_time", "Tape Time", controlspec.new(0.01,2.0,"exp",0.01,0.3))
    params:set_action("tapecho_time", function(x) Bridge.set_param("tapecho_time", x) end)
    params:add_control("tapecho_feedback", "Tape Feedback", controlspec.new(0,1.2,"lin",0.01,0.4))
    params:set_action("tapecho_feedback", function(x) Bridge.set_param("tapecho_feedback", x) end)
    params:add_control("tapecho_wow_flutter", "Tape Wow/Flut", controlspec.new(0,1.0,"lin",0.01,0.1))
    params:set_action("tapecho_wow_flutter", function(x) Bridge.set_param("tapecho_wow_flutter", x) end)
    params:add_control("tapecho_erosion", "Tape Erosion", controlspec.new(0,1.0,"lin",0.01,0.0))
    params:set_action("tapecho_erosion", function(x) Bridge.set_param("tapecho_erosion", x) end)
    params:add_control("tapecho_drive", "Tape Drive", controlspec.new(0.1,5.0,"lin",0.01,1.0))
    params:set_action("tapecho_drive", function(x) Bridge.set_param("tapecho_drive", x) end)
    params:add_control("tapecho_filter", "Tape Filter", controlspec.new(20,18000,"exp",1,8000))
    params:set_action("tapecho_filter", function(x) Bridge.set_param("tapecho_filter", x) end)
    
    params:add_control("reverb_mix", "Reverb Mix", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("reverb_mix", function(x) Bridge.set_param("reverb_mix", x) end)
    
    params:add_control("blossomverb_decay", "Rev Decay", controlspec.new(0.1,100.0,"exp",0.1,4.75))
    params:set_action("blossomverb_decay", function(x) Bridge.set_param("blossomverb_decay", x) end)
    params:add_control("blossomverb_bloom", "Rev Bloom", controlspec.new(0.01,2.0,"lin",0.01,1.80))
    params:set_action("blossomverb_bloom", function(x) Bridge.set_param("blossomverb_bloom", x) end)
    params:add_control("blossomverb_damp", "Rev Damp", controlspec.new(200,18000,"exp",1,3500))
    params:set_action("blossomverb_damp", function(x) Bridge.set_param("blossomverb_damp", x) end)
    params:add_control("blossomverb_predelay", "Rev Predelay", controlspec.new(0.0,1.0,"lin",0.01,0.110))
    params:set_action("blossomverb_predelay", function(x) Bridge.set_param("blossomverb_predelay", x) end)
    params:add_control("blossomverb_mod_rate", "Rev Mod Rate", controlspec.new(0.0,10.0,"lin",0.01,0.300))
    params:set_action("blossomverb_mod_rate", function(x) Bridge.set_param("blossomverb_mod_rate", x) end)
    params:add_control("blossomverb_mod_depth", "Rev Mod Depth", controlspec.new(0.0,0.002,"lin",0.0001,0.002))
    params:set_action("blossomverb_mod_depth", function(x) Bridge.set_param("blossomverb_mod_depth", x) end)

    -- FIX: Added LOOPERS Group
    params:add_group("LOOPERS", 20)
    for i=1, 4 do
        params:add_control("looper"..i.."_vol", "L"..i.." Vol", controlspec.new(0,1,"lin",0.01,1.0))
        params:set_action("looper"..i.."_vol", function(x) Loopers.set_vol(i, x) end)
        params:add_control("looper"..i.."_cut", "L"..i.." Cutoff", controlspec.new(20,18000,"exp",1,18000))
        params:set_action("looper"..i.."_cut", function(x) Loopers.set_cut(i, x) end)
        params:add_control("looper"..i.."_res", "L"..i.." Res", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("looper"..i.."_res", function(x) Loopers.set_res(i, x) end)
        params:add_control("looper"..i.."_pan", "L"..i.." Pan", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("looper"..i.."_pan", function(x) Loopers.set_pan(i, x) end)
        params:add_control("looper"..i.."_fade", "L"..i.." Fade", controlspec.new(0,16,"lin",0.1,0))
    end

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
                if bridge_dest == "delay_t" then bridge_dest = "tapecho_time" end
                if bridge_dest == "delay_f" then bridge_dest = "tapecho_feedback" end
                Bridge.set_matrix(s_name:lower(), bridge_dest, idx, x)
            end)
        end
    end
end

return Params
