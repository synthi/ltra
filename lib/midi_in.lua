-- lib/midi_in.lua | v2.9.0
-- FIX: Absolute Frequency Distance Quantization (Fixes Wrap-Around and JI Bugs)

local MidiIn = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Scales = require 'ltra/lib/scales'
local Consts = require 'ltra/lib/consts'
local musicutil = require 'musicutil'

function MidiIn.init(g_ref)
    Globals = g_ref
    Globals.midi_active_notes = {}
    Globals.midi_rr_index = 1
    Globals.midi_voice_vel = {0, 0, 0, 0, 0, 0, 0, 0} 
    
    MidiIn.device = midi.connect(1)
    MidiIn.device.event = MidiIn.handle_event
    
    Globals.midi_watch_thread = clock.run(function()
        while true do
            clock.sleep(1)
            local target_dev = params:get("midi_device")
            if target_dev and midi.vports[target_dev] then
                if MidiIn.device.name ~= midi.vports[target_dev].name then
                    MidiIn.device.event = nil
                    MidiIn.device = midi.connect(target_dev)
                    MidiIn.device.event = MidiIn.handle_event
                end
            end
        end
    end)
end

function MidiIn.stop()
    if Globals and Globals.midi_watch_thread then
        clock.cancel(Globals.midi_watch_thread)
        Globals.midi_watch_thread = nil
    end
end

function MidiIn.handle_event(data)
    local msg = midi.to_msg(data)
    if not msg then return end
    
    if msg.type == "note_on" then
        MidiIn.note_on(msg.note, msg.vel, msg.ch)
    elseif msg.type == "note_off" then
        MidiIn.note_off(msg.note, msg.ch)
    elseif msg.type == "pitchbend" then
        if msg.ch == 1 then 
            Bridge.set_pitch_bend(msg.val)
        else
            for i=1, 8 do
                local p_idx = ((i-1) % 4) + 1
                if Globals.voices[i].mpe_channel == msg.ch and params:get("osc"..p_idx.."_midi_ch") == 18 then
                    Bridge.set_mpe_bend(i, msg.val)
                end
            end
        end
    elseif msg.type == "cc" then
        if msg.cc == 1 and msg.ch == 1 then
            Bridge.set_mod_wheel(msg.val)
        elseif msg.cc == 74 then
            for i=1, 8 do
                local p_idx = ((i-1) % 4) + 1
                if Globals.voices[i].mpe_channel == msg.ch and params:get("osc"..p_idx.."_midi_ch") == 18 then
                    Bridge.set_mpe_slide(i, msg.val)
                end
            end
        end
    elseif msg.type == "channel_pressure" then
        for i=1, 8 do
            local p_idx = ((i-1) % 4) + 1
            if Globals.voices[i].mpe_channel == msg.ch and params:get("osc"..p_idx.."_midi_ch") == 18 then
                Bridge.set_mpe_press(i, msg.val)
            end
        end
    end
end

function MidiIn.note_on(note, vel, ch)
    local poly_mode = params:get("midi_poly_mode") or 1
    local target_voices = {}
    local main_pool = {}
    local twin_pool = {}
    
    for i=1, 4 do
        local v_ch = params:get("osc"..i.."_midi_ch")
        local v_on = params:get("osc"..i.."_midi_note")
        local twin_on = params:get("osc"..i.."_twin_enable")
        
        if v_on == 1 and (v_ch == 17 or v_ch == 18 or v_ch == ch) then
            table.insert(main_pool, i)
            if twin_on == 1 then
                table.insert(twin_pool, i+4)
            end
        end
    end
    
    for _, v in ipairs(main_pool) do table.insert(target_voices, v) end
    for _, v in ipairs(twin_pool) do table.insert(target_voices, v) end
    
    if #target_voices == 0 then return end
    
    Globals.midi_active_notes[note] = Globals.midi_active_notes[note] or {}
    
    local function steal_voice(v)
        for n, voices in pairs(Globals.midi_active_notes) do
            for i, active_v in ipairs(voices) do
                if active_v == v then
                    table.remove(voices, i)
                    break
                end
            end
        end
    end

    if poly_mode == 3 then 
        for _, v in ipairs(target_voices) do
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel, ch)
            table.insert(Globals.midi_active_notes[note], v)
        end
    elseif poly_mode == 2 then 
        local allocated = false
        for _, v in ipairs(target_voices) do
            if not MidiIn.is_voice_busy(v) then
                MidiIn.trigger_voice(v, note, vel, ch)
                table.insert(Globals.midi_active_notes[note], v)
                allocated = true
                break
            end
        end
        if not allocated then 
            local v = target_voices[1]
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel, ch)
            table.insert(Globals.midi_active_notes[note], v)
        end
    else 
        local allocated = false
        for i=1, #target_voices do
            local v_idx = ((Globals.midi_rr_index + i - 2) % #target_voices) + 1
            local v = target_voices[v_idx]
            if not MidiIn.is_voice_busy(v) then
                MidiIn.trigger_voice(v, note, vel, ch)
                table.insert(Globals.midi_active_notes[note], v)
                Globals.midi_rr_index = (v_idx % #target_voices) + 1
                allocated = true
                break
            end
        end
        if not allocated then 
            local v = target_voices[Globals.midi_rr_index]
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel, ch)
            table.insert(Globals.midi_active_notes[note], v)
            Globals.midi_rr_index = (Globals.midi_rr_index % #target_voices) + 1
        end
    end
end

function MidiIn.note_off(note, ch)
    if Globals.midi_active_notes[note] then
        for _, v in ipairs(Globals.midi_active_notes[note]) do
            local p_idx = ((v-1) % 4) + 1
            if not Globals.voices[p_idx].latched and not Globals.voices[p_idx].sustained then
                Bridge.set_gate(v, 0)
            end
            Bridge.set_midi_gate(v, 0)
            Globals.midi_voice_vel[v] = 0 
            Globals.voices[v].mpe_channel = nil
            Globals.dirty = true
        end
        Globals.midi_active_notes[note] = nil
    end
end

function MidiIn.trigger_voice(v, note, vel, ch)
    local p_idx = ((v-1) % 4) + 1
    
    local is_quantized = params:get("osc"..p_idx.."_quant_midi") == 1
    local base_note = 60
    local degree = note - base_note
    local ratio = 1.0
    
    if is_quantized then
        -- FIX: Absolute Frequency Distance Quantization
        local target_hz = musicutil.note_num_to_freq(note)
        local base_hz = Scales.get_freq(0, 0)
        
        local idx = Globals.scale.current_idx
        local intervals = {}
        local num_predefined = #Consts.SCALES_A + #Consts.SCALES_B
        if idx <= #Consts.SCALES_A then intervals = Consts.SCALES_A[idx].intervals
        elseif idx <= num_predefined then intervals = Consts.SCALES_B[idx - #Consts.SCALES_A].intervals
        else intervals = Globals.scale.custom_slots[idx - num_predefined].intervals end
        
        if not intervals or #intervals == 0 then intervals = {0} end
        local len = #intervals
        
        -- Generate a map of exact frequencies for 3 octaves below and above the played note
        local oct_guess = math.floor(degree / 12)
        local min_d = math.huge
        local best_hz = base_hz
        
        for o = oct_guess - 3, oct_guess + 3 do
            for i = 0, len - 1 do
                local test_degree = (o * len) + i
                local test_hz = Scales.get_freq(test_degree, 0)
                local dist = math.abs(test_hz - target_hz)
                if dist < min_d then
                    min_d = dist
                    best_hz = test_hz
                end
            end
        end
        
        ratio = best_hz / base_hz
    else
        ratio = 2 ^ (degree / 12.0)
    end
    
    Bridge.set_midi_ratio(v, ratio)
    Bridge.set_midi_vel(v, vel)
    Globals.midi_voice_vel[v] = vel 
    Globals.voices[v].mpe_channel = ch
    Globals.dirty = true
    
    Bridge.set_midi_gate(v, 1)
    if not Globals.voices[p_idx].latched and not Globals.voices[p_idx].sustained then
        Bridge.set_gate(v, 1)
    end
end

function MidiIn.is_voice_busy(v)
    for note, voices in pairs(Globals.midi_active_notes) do
        for _, active_v in ipairs(voices) do
            if active_v == v then return true end
        end
    end
    return false
end

return MidiIn
