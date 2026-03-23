-- lib/arp.lua | v1.5.14
-- FIX: Active Voices Logic (Only Held/Latched/Sustained)

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
        local is_active = false
        if Globals.button_state[i] and Globals.button_state[i][8] then is_active = true end
        if Globals.voices[i].latched or Globals.voices[i].sustained then is_active = true end
        
        if Globals.voices[i].arp_enabled and is_active then 
            table.insert(active_voices, i) 
        end
    end
    
    if #active_voices == 0 then return end
    
    Globals.arp.current_step = (Globals.arp.current_step % #active_voices) + 1
    local target_voice = active_voices[Globals.arp.current_step]

    local chaos_prob = params:get("arp_chaos") or 0.1
    local len = params:get("arp_length") or 8
    local oct_range = params:get("arp_octaves") or 1

    local reg = Globals.arp.register[target_voice]
    
    local last_bit = reg[len]
    local prev_bit = reg[len-1]
    if prev_bit == nil then prev_bit = 0 end
    
    local new_bit = (last_bit ~= prev_bit) and 1 or 0 
    
    if math.random() < chaos_prob then new_bit = 1 - new_bit end
    
    table.remove(reg)
    table.insert(reg, 1, new_bit)
    
    local val = (reg[1] * 4) + (reg[2] * 2) + (reg[3] * 1)
    local norm_val = val / 7
    Globals.arp.step_val[target_voice] = norm_val
    
    Bridge.set_param("arp_cv"..target_voice, norm_val)
    
    local r = math.random()
    local oct_offset = 0
    local skip = false
    local ratchet = false
    
    if r < (chaos_prob * 0.4) then
        oct_offset = math.random(1, oct_range) 
    elseif r < (chaos_prob * 0.7) then
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
        
        clock.run(function()
            Bridge.set_gate(target_voice, 1)
            if ratchet then
                clock.sleep(0.05)
                Bridge.set_gate(target_voice, 0)
                clock.sleep(0.05)
                Bridge.set_gate(target_voice, 1)
            end
            clock.sleep(params:get("arp_gate_len") or 0.5)
            if not Globals.voices[target_voice].latched and not Globals.voices[target_voice].sustained then
                Bridge.set_gate(target_voice, 0)
            end
        end)
    end
end

return Arp
