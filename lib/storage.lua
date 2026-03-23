-- lib/storage.lua | v1.5.5
-- FIX: Save ALL params, Delete Snapshot

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
    local snap = { params={} }
    -- FIX: Save absolutely everything
    for _, id in ipairs(params.lookup) do
        local p = params:lookup_param(id)
        if p.t ~= 4 then -- Don't save groups/separators
            snap.params[p.id] = p:get()
        end
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
    print("LTRA: Snapshot "..slot.." loaded.")
end

function Storage.delete_snapshot(slot)
    Globals.snapshots[slot] = nil
    print("LTRA: Snapshot "..slot.." deleted.")
end

return Storage
