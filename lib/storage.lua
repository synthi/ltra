-- lib/storage.lua | v1.5.6
-- FIX: params.lookup iteration, Volatile State Saving

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
    Globals.dirty = true
end

function Storage.save_snapshot(slot)
    local snap = { params={}, volatile={} }
    
    -- FIX: Correct iteration over params.lookup dictionary
    for id, idx in pairs(params.lookup) do
        local p = params.params[idx]
        if p.t ~= 4 then -- Skip groups/separators
            snap.params[id] = p:get()
        end
    end
    
    -- FIX: Save volatile state (Latch and Gates)
    snap.volatile.latch_mode = Globals.latch_mode
    snap.volatile.voices_latched = {}
    for i=1, 4 do snap.volatile.voices_latched[i] = Globals.voices[i].latched end
    
    Globals.snapshots[slot] = snap
    print("LTRA: Snapshot "..slot.." saved to RAM.")
end

function Storage.load_snapshot(slot)
    local snap = Globals.snapshots[slot]
    if not snap then return end
    
    for id, val in pairs(snap.params) do
        params:set(id, val) 
    end
    
    -- FIX: Restore volatile state
    if snap.volatile then
        Globals.latch_mode = snap.volatile.latch_mode
        for i=1, 4 do 
            Globals.voices[i].latched = snap.volatile.voices_latched[i]
            Bridge.set_gate(i, snap.volatile.voices_latched[i] and 1 or 0)
        end
    end
    
    print("LTRA: Snapshot "..slot.." loaded.")
end

function Storage.delete_snapshot(slot)
    Globals.snapshots[slot] = nil
    print("LTRA: Snapshot "..slot.." deleted.")
end

return Storage
