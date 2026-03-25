-- lib/midi_in.lua | v2.0.1
-- FIX: Voice Stealing Purge, Velocity Tracking for Grid Visuals

local MidiIn = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'

function MidiIn.init(g_ref)
    Globals = g_ref
    Globals.midi_active_notes = {}
    Globals.midi_rr_index = 1
    Globals.midi_voice_vel = {0, 0, 0, 0} -- FIX: Track velocity per voice for UI
    
    MidiIn.device = midi.connect(1)
    MidiIn.device.event = MidiIn.handle_event
    
    clock.run(function()
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

function MidiIn.handle_event(data)
    local msg = midi.to_msg(data)
    if not msg then return end
    
    if msg.type == "note_on" then
        MidiIn.note_on(msg.note, msg.vel, msg.ch)
    elseif msg.type == "note_off" then
        MidiIn.note_off(msg.note, msg.ch)
    elseif msg.type == "pitchbend" then
        Bridge.set_pitch_bend(msg.val)
    elseif msg.type == "cc" and msg.cc == 1 then
        Bridge.set_mod_wheel(msg.val)
    end
end

function MidiIn.note_on(note, vel, ch)
    local poly_mode = params:get("midi_poly_mode") or 1
    local target_voices = {}
    
    for i=1, 4 do
        local v_ch = params:get("osc"..i.."_midi_ch")
        local v_on = params:get("osc"..i.."_midi_note")
        if v_on == 1 and (v_ch == 17 or v_ch == ch) then
            table.insert(target_voices, i)
        end
    end
    
    if #target_voices == 0 then return end
    
    Globals.midi_active_notes[note] = Globals.midi_active_notes[note] or {}
    
    -- FIX: Purge stolen voices from old notes to prevent ghost Note OFFs
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

    if poly_mode == 3 then -- Unison
        for _, v in ipairs(target_voices) do
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel)
            table.insert(Globals.midi_active_notes[note], v)
        end
    elseif poly_mode == 2 then -- Reset
        local allocated = false
        for _, v in ipairs(target_voices) do
            if not MidiIn.is_voice_busy(v) then
                MidiIn.trigger_voice(v, note, vel)
                table.insert(Globals.midi_active_notes[note], v)
                allocated = true
                break
            end
        end
        if not allocated then 
            local v = target_voices[1]
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel)
            table.insert(Globals.midi_active_notes[note], v)
        end
    else -- Round Robin
        local allocated = false
        for i=1, #target_voices do
            local v_idx = ((Globals.midi_rr_index + i - 2) % #target_voices) + 1
            local v = target_voices[v_idx]
            if not MidiIn.is_voice_busy(v) then
                MidiIn.trigger_voice(v, note, vel)
                table.insert(Globals.midi_active_notes[note], v)
                Globals.midi_rr_index = (v_idx % #target_voices) + 1
                allocated = true
                break
            end
        end
        if not allocated then 
            local v = target_voices[Globals.midi_rr_index]
            steal_voice(v)
            MidiIn.trigger_voice(v, note, vel)
            table.insert(Globals.midi_active_notes[note], v)
            Globals.midi_rr_index = (Globals.midi_rr_index % #target_voices) + 1
        end
    end
end

function MidiIn.note_off(note, ch)
    if Globals.midi_active_notes[note] then
        for _, v in ipairs(Globals.midi_active_notes[note]) do
            if not Globals.voices[v].latched and not Globals.voices[v].sustained then
                Bridge.set_gate(v, 0)
            end
            Globals.midi_voice_vel[v] = 0 -- FIX: Clear velocity for UI
            Globals.dirty = true
        end
        Globals.midi_active_notes[note] = nil
    end
end

function MidiIn.trigger_voice(v, note, vel)
    Bridge.set_midi_note(v, note)
    Bridge.set_midi_vel(v, vel)
    Globals.midi_voice_vel[v] = vel -- FIX: Store velocity for UI
    Globals.dirty = true
    if not Globals.voices[v].latched and not Globals.voices[v].sustained then
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
