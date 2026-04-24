-- lib/midi_in.lua | v2.8.4
-- FIX: Lua-side MIDI Quantization for JI Scale Compatibility

local MidiIn = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Scales = require 'ltra/lib/scales'

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
    
    -- FIX: Lua-side MIDI Quantization (Supports JI Scales)
    local is_quantized = params:get("osc"..p_idx.."_quant_midi") == 1
    if is_quantized then
        local oct = math.floor(note / 12)
        local pc = note % 12
        
        local active_notes = {}
        for i=0, 11 do
            if Scales.is_note_active(i) then table.insert(active_notes, i) end
        end
        if #active_notes == 0 then active_notes = {0} end
        
        local nearest_val = active_notes[1]
        local min_d = 100
        for _, n in ipairs(active_notes) do
            if math.abs(pc - n) < min_d then min_d = math.abs(pc - n); nearest_val = n end
            if math.abs(pc - (n+12)) < min_d then min_d = math.abs(pc - (n+12)); nearest_val = n+12 end
            if math.abs(pc - (n-12)) < min_d then min_d = math.abs(pc - (n-12)); nearest_val = n-12 end
        end
        
        local q_note = (oct * 12) + nearest_val
        
        -- Calculate exact Hz using Scales library (JI or TET)
        local hz = Scales.get_freq(q_note, 0)
        Bridge.set_freq(v, hz)
    else
        -- Unquantized: Send raw MIDI note offset to SC
        Bridge.set_midi_note(v, note)
    end
    
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
