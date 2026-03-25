-- lib/storage.lua | v2.0.0
-- FIX: Stereo Looper Saving (L/R files)

local Storage = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Storage.init(g_ref)
    Globals = g_ref
    
    params.action_write = function(filename, name, number)
        Storage.save_sidecar(number)
    end
    
    params.action_read = function(filename, silent, number)
        Storage.load_sidecar(number)
    end
end

function Storage.save_sidecar(pset_number)
    print("LTRA: Saving Sidecar Data for PSET " .. pset_number)
    
    local data = {
        custom_scales = Globals.scale.custom_slots,
        snapshots = Globals.snapshots,
        matrix_quant = Globals.matrix_quant
    }
    
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    tab.save(data, data_path)
    
    local timestamp = os.date("%Y%m%d_%H%M%S")
    for i=1, 3 do
        local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_trk_" .. i .. "_L_" .. timestamp .. ".wav"
        local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_trk_" .. i .. "_R_" .. timestamp .. ".wav"
        local start_pos = (i-1) * 115
        
        -- Save Buffer 1 (L) and Buffer 2 (R)
        softcut.buffer_write_mono(audio_path_L, start_pos, 110, 1)
        softcut.buffer_write_mono(audio_path_R, start_pos, 110, 2)
    end
    
    print("LTRA: Save Complete.")
end

function Storage.load_sidecar(pset_number)
    print("LTRA: Loading Sidecar Data for PSET " .. pset_number)
    
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    if util.file_exists(data_path) then
        local data = tab.load(data_path)
        if data then
            if data.custom_scales then Globals.scale.custom_slots = data.custom_scales end
            if data.snapshots then Globals.snapshots = data.snapshots end
            if data.matrix_quant then Globals.matrix_quant = data.matrix_quant end
        end
    else
        print("LTRA: No sidecar data found (New PSET?)")
    end
    
    Bridge.clear_delay()
    Bridge.sync_matrix()
    
    local Midi16n = require 'ltra/lib/midi_16n'
    Midi16n.sync_faders()
    
    Globals.dirty = true
end

function Storage.save_snapshot(slot)
    local snap = { params={}, volatile={} }
    
    for id, idx in pairs(params.lookup) do
        local p = params.params[idx]
        if p.t ~= 4 then 
            snap.params[id] = p:get()
        end
    end
    
    snap.volatile.latch_mode = Globals.latch_mode
    snap.volatile.voices_latched = {}
    snap.volatile.voices_sustained = {} 
    for i=1, 4 do 
        snap.volatile.voices_latched[i] = Globals.voices[i].latched 
        snap.volatile.voices_sustained[i] = Globals.voices[i].sustained
    end
    
    Globals.snapshots[slot] = snap
    print("LTRA: Snapshot "..slot.." saved to RAM.")
end

function Storage.load_snapshot(slot)
    local snap = Globals.snapshots[slot]
    if not snap then return end
    
    for id, val in pairs(snap.params) do
        params:set(id, val) 
    end
    
    if snap.volatile then
        Globals.latch_mode = snap.volatile.latch_mode
        for i=1, 4 do 
            Globals.voices[i].latched = snap.volatile.voices_latched[i]
            Globals.voices[i].sustained = snap.volatile.voices_sustained and snap.volatile.voices_sustained[i] or false
            
            local gate_val = (Globals.voices[i].latched or Globals.voices[i].sustained) and 1 or 0
            Bridge.set_gate(i, gate_val)
        end
    end
    
    local Midi16n = require 'ltra/lib/midi_16n'
    Midi16n.sync_faders()
    
    print("LTRA: Snapshot "..slot.." loaded.")
end

function Storage.delete_snapshot(slot)
    Globals.snapshots[slot] = nil
    print("LTRA: Snapshot "..slot.." deleted.")
end

return Storage
