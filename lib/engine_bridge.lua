-- code/ltra/lib/engine_bridge.lua | v0.7
local Bridge = {}
local Globals
local Loopers = require 'ltra/lib/loopers'

function Bridge.init(g_ref) Globals = g_ref end

function Bridge.handle_osc(path, args)
    if not Globals then return end
    if path == "/ltra/visuals" then
        if Globals.visuals then
            Globals.visuals.amp_l = args[1]; Globals.visuals.amp_r = args[2]
            Globals.visuals.lfo_vals[1] = args[3]; Globals.visuals.lfo_vals[2] = args[4]
            Globals.dirty = true 
        end
    elseif path == "/ltra/config" then
        Globals.engine_bus_id = args[1]
        Loopers.configure_audio_routing(Globals)
        Globals.dirty = true
    end
end

function Bridge.query_config() engine.query_config() end
function Bridge.set_param(name, value) engine.param(name, value) end
function Bridge.set_freq(idx, hz) engine.param("freq"..idx, hz) end
function Bridge.set_gate(idx, val) engine.param("gate"..idx, val) end

-- NUEVO: Trigger para Arp
function Bridge.trigger_arp(idx) engine.param("t_arp"..idx, 1) end

-- NUEVO: Reset LFOs
function Bridge.reset_lfo() engine.param("t_reset", 1) end

function Bridge.set_filter_tone(idx, val)
    local tone = util.linlin(0, 1, -1.0, 1.0, val)
    engine.param("filt"..idx.."_tone", tone)
end
function Bridge.set_matrix(src, dest, idx, val)
    engine.param("mod_"..src.."_"..dest..idx, val)
end
return Bridge
