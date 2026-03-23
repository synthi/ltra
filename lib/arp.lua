-- lib/arp.lua | v1.5.11
-- FIX: Musical Arpeggiator (Cross-Voice, Octaves, Skips, Ratchets)

local Arp = {}
local Globals
local Scales = require 'ltra/lib/scales'
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Arp.init(g_ref)
    Globals = g_ref
    Globals.arp.current_step = 0
    
    Arp.clock_id = clock.run(function()
        while true do
            local div_idx = params:get("arp_div") or 10
            local div_val = Consts.SYNC_DIVS[div_idx].v
            local bpm = params:get("clock_tempo") or 120
            local sync_val = (60 / bpm) * div_val
            
            clock.sleep(sync_val)
            Arp.tick()
        end
    end)
end

function Arp.stop()
    if Arp.clock_id then clock.cancel(Arp.clock_id) end
end

function Arp.tick()
    local active_voices = {}
    for i=1, 4 do
        if Globals.voices[i].arp_enabled then table.insert(active_voices, i) end
    end
    
    if #active_voices == 0 then return end
    
    -- FIX: Cross-Voice Cycling
    Globals.arp.current_step = (Globals.arp.current_step % #active_voices) + 1
    local target_voice = active_voices[Globals.arp.current_step]

    local chaos_prob = params:get("arp_chaos") or 0.1
    local oct_range = params:get("arp_octaves") or 1
    
    -- FIX: Musical Chaos Logic
    local r = math.random()
    local oct_offset = 0
    local skip = false
    local ratchet = false
    
    if r < (chaos_prob * 0.3) then
        oct_offset = math.random(1, oct_range)
    elseif r < (chaos_prob * 0.6) then
        oct_offset = -math.random(1, oct_range)
    elseif r < (chaos_prob * 0.8) then
        skip = true
    elseif r < (chaos_prob * 1.0) then
        ratchet = true
    end

    if not skip then
        local pitch_val = params:get("osc"..target_voice.."_pitch") or 0.5
        local deg = math.floor(pitch_val * 24)
        local hz = Scales.get_freq(deg, (params:get("osc"..target_voice.."_octave") or 0) + oct_offset)
        local tune = params:get("osc"..target_voice.."_tune") or 0
        hz = hz * (2 ^ (tune / 12))
        
        Bridge.set_freq(target_voice, hz)
        
        -- FIX: Real Gate Pulse for Envelopes
        clock.run(function()
            Bridge.set_gate(target_voice, 1)
            if ratchet then
                clock.sleep(0.05)
                Bridge.set_gate(target_voice, 0)
                clock.sleep(0.05)
                Bridge.set_gate(target_voice, 1)
            end
            clock.sleep(params:get("arp_gate_len") or 0.5)
            -- Only close if not latched
            if not Globals.voices[target_voice].latched then
                Bridge.set_gate(target_voice, 0)
            end
        end)
    end
end

return Arp
