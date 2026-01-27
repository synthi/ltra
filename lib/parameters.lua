-- code/ltra/lib/parameters.lua | v0.6
-- LTRA: Definición de Parámetros del Sistema

local Params = {}
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Params.init()
    params:add_separator("LTRA v0.6")
    
    -- GRUPO: VOICES
    params:add_group("VOICES", 16)
    for i=1,4 do
        params:add_control("osc"..i.."_shape", "Osc "..i.." Shape", controlspec.new(0,4,"lin",0.01,0))
        params:set_action("osc"..i.."_shape", function(x) Bridge.set_param("shape"..i, x) end)
        
        params:add_control("osc"..i.."_pan", "Osc "..i.." Pan", controlspec.new(-1,1,"lin",0.01,0))
        params:set_action("osc"..i.."_pan", function(x) Bridge.set_param("pan"..i, x) end)
        
        params:add_control("osc"..i.."_vol", "Osc "..i.." Vol", controlspec.new(0,1,"lin",0.01,0))
        params:set_action("osc"..i.."_vol", function(x) Bridge.set_param("vol"..i, x) end)
        
        params:add_control("osc"..i.."_tune", "Osc "..i.." Fine", controlspec.new(-1,1,"lin",0.01,0))
        -- Tune se aplica en midi_16n al calcular freq, no directo al engine
    end
    
    -- GRUPO: FILTERS
    params:add_group("FILTERS", 6)
    params:add_control("filt1_tone", "Filt 1 Tone", controlspec.new(-1,1,"lin",0.01,0))
    params:set_action("filt1_tone", function(x) Bridge.set_filter_tone(1, x) end)
    
    params:add_control("filt2_tone", "Filt 2 Tone", controlspec.new(-1,1,"lin",0.01,0))
    params:set_action("filt2_tone", function(x) Bridge.set_filter_tone(2, x) end)
    
    params:add_control("filt1_res", "Filt 1 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt1_res", function(x) Bridge.set_param("filt1_res", x) end)
    
    params:add_control("filt2_res", "Filt 2 Res", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt2_res", function(x) Bridge.set_param("filt2_res", x) end)
    
    params:add_control("filt_type", "Filt Type", controlspec.new(0,1,"lin",1,0)) -- 0=SVF, 1=Moog
    params:set_action("filt_type", function(x) Bridge.set_param("filt_type", x) end)
    
    params:add_control("filt_drive", "Filt Drive", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("filt_drive", function(x) Bridge.set_param("filt1_drive", x); Bridge.set_param("filt2_drive", x) end)

    -- GRUPO: SPACE
    params:add_group("SPACE", 10)
    params:add_control("system_dirt", "Dirt", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("system_dirt", function(x) Bridge.set_param("system_dirt", x) end)
    
    params:add_control("delay_time", "Delay Time", controlspec.new(0.01,2.0,"lin",0.01,0.5))
    params:set_action("delay_time", function(x) Bridge.set_param("delay_time", x) end)
    
    params:add_control("delay_fb", "Delay Feedback", controlspec.new(0,1.1,"lin",0.01,0))
    params:set_action("delay_fb", function(x) Bridge.set_param("delay_fb", x) end)
    
    params:add_control("delay_spread", "Delay Spread", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("delay_spread", function(x) Bridge.set_param("delay_spread", x) end)
    
    params:add_control("tape_erosion", "Erosion", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_erosion", function(x) Bridge.set_param("tape_erosion", x) end)
    
    params:add_control("tape_wow", "Wow", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_wow", function(x) Bridge.set_param("tape_wow", x) end)
    
    params:add_control("tape_flutter", "Flutter", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("tape_flutter", function(x) Bridge.set_param("tape_flutter", x) end)
    
    params:add_control("reverb_mix", "Reverb Mix", controlspec.new(0,1,"lin",0.01,0))
    params:set_action("reverb_mix", function(x) Bridge.set_param("reverb_mix", x) end)
    
    params:add_control("reverb_decay", "Reverb Decay", controlspec.new(0.1,60,"exp",0.1,5))
    params:set_action("reverb_decay", function(x) Bridge.set_param("reverb_time", x) end)
    
    params:add_control("reverb_damp", "Reverb Damp", controlspec.new(0,1,"lin",0.01,0.5))
    params:set_action("reverb_damp", function(x) Bridge.set_param("reverb_damp", x) end)

    -- GRUPO: MODULATION
    params:add_group("MODULATION", 8)
    params:add_control("lfo1_rate", "LFO1 Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
    params:set_action("lfo1_rate", function(x) Bridge.set_param("lfo1_rate", x) end)
    
    params:add_control("lfo2_rate", "LFO2 Rate", controlspec.new(0.01,20,"exp",0.01,0.2))
    params:set_action("lfo2_rate", function(x) Bridge.set_param("lfo2_rate", x) end)
    
    params:add_control("chaos_rate", "Chaos Rate", controlspec.new(0.01,20,"exp",0.01,0.5))
    params:set_action("chaos_rate", function(x) Bridge.set_param("chaos_rate", x) end)
    
    params:add_control("chaos_slew", "Chaos Slew", controlspec.new(0,1,"lin",0.01,0.1))
    params:set_action("chaos_slew", function(x) Bridge.set_param("chaos_slew", x) end)

    -- GRUPO: MATRIX (HIDDEN)
    -- 4 Sources * 16 Destinos = 64 Parámetros ocultos para guardar PSETs
    for s_name, s_idx in pairs(Consts.SOURCES) do
        for d_name, d_idx in pairs(Consts.DESTINATIONS) do
            local id = "mat_"..s_name.."_"..d_name
            params:add_control(id, id, controlspec.new(0,1,"lin",0,0))
            params:hide(id)
            -- Al cargar PSET, esto actualizará el Engine
            params:set_action(id, function(x) 
                -- Actualizar Engine
                local type = string.match(d_name, "^([A-Z]+)")
                local idx = string.match(d_name, "(%d+)$") or ""
                -- Mapeo de nombres para Bridge (pitch, amp, shape...)
                local bridge_dest = d_name:lower():gsub("%d", "")
                if bridge_dest == "delay_t" then bridge_dest = "delay_time" end
                if bridge_dest == "delay_f" then bridge_dest = "delay_fb" end
                if bridge_dest == "filt" then bridge_dest = "filt" end -- filt1/2 handled by idx
                
                Bridge.set_matrix(s_name:lower(), bridge_dest, idx, x)
            end)
        end
    end
end

return Params
