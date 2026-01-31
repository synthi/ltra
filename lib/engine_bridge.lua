-- code/ltra/lib/engine_bridge.lua | v1.0
local Bridge = {}
local Globals
local Loopers = require 'ltra/lib/loopers'
local Consts = require 'ltra/lib/consts'

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

function Bridge.sync_matrix()
    for s_name, s_idx in pairs(Consts.SOURCES) do
        for d_name, d_idx in pairs(Consts.DESTINATIONS) do
            local val = Globals.matrix[s_idx][d_idx]
            if val > 0 then
                local idx = string.match(d_name, "(%d+)$") or ""
                local dest = d_name:lower():gsub("%d", "")
                if dest == "delay_t" then dest = "delay_time" end
                if dest == "delay_f" then dest = "delay_fb" end
                if dest == "filt" then dest = "filt" end 
                local param_id = "mod_" .. s_name:lower() .. "_" .. dest .. idx
                engine.param(param_id, val)
            end
        end
    end
end

function Bridge.query_config() engine.query_config() end
function Bridge.set_param(name, value) engine.param(name, value) end
function Bridge.set_freq(idx, hz) engine.param("freq"..idx, hz) end
function Bridge.set_gate(idx, val) engine.param("gate"..idx, val) end
function Bridge.trigger_arp(idx) engine.param("t_arp"..idx, 1) end
function Bridge.reset_lfo() engine.param("t_reset", 1) end

function Bridge.set_filter_tone(idx, val)
    local tone = util.linlin(0, 1, -1.0, 1.0, val)
    engine.param("filt"..idx.."_tone", tone)
end
function Bridge.set_matrix(src, dest, idx, val)
    engine.param("mod_"..src.."_"..dest..idx, val)
end
return Bridge
