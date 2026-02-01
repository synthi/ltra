-- code/ltra/lib/storage.lua | v1.0
-- LTRA: Storage Manager (Hybrid Persistence)

local Storage = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Storage.init(g_ref)
    Globals = g_ref
    
    -- Hook en el sistema de parámetros de Norns
    -- Se ejecutan automáticamente al guardar/cargar un PSET desde el menú K1
    params.action_write = function(filename, name, number)
        Storage.save_sidecar(number)
    end
    
    params.action_read = function(filename, silent, number)
        Storage.load_sidecar(number)
    end
end

-- Guardar datos extra que params no ve (Snapshots RAM, Escalas Custom, Audio)
function Storage.save_sidecar(pset_number)
    print("LTRA: Saving Sidecar Data for PSET " .. pset_number)
    
    -- 1. Guardar Tablas Lua
    -- La Matriz actual se guarda sola en el PSET (params ocultos).
    -- Pero los Snapshots (Fila 7) y Escalas Custom son tablas Lua.
    local data = {
        custom_scales = Globals.scale.custom_slots,
        snapshots = Globals.snapshots
    }
    
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    tab.save(data, data_path)
    
    -- 2. Guardar Audio (Buffers Softcut)
    -- Guardamos el buffer completo (L y R)
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    -- Buffer 1 (L) y 2 (R), start 0, length -1 (todo el buffer)
    softcut.buffer_write_mono(audio_path_L, 0, -1, 1)
    softcut.buffer_write_mono(audio_path_R, 0, -1, 2)
    
    print("LTRA: Save Complete.")
end

-- Cargar datos extra
function Storage.load_sidecar(pset_number)
    print("LTRA: Loading Sidecar Data for PSET " .. pset_number)
    
    -- 1. Cargar Tablas Lua
    local data_path = _path.data .. "ltra/pset_" .. pset_number .. ".data"
    if util.file_exists(data_path) then
        local data = tab.load(data_path)
        if data then
            if data.custom_scales then Globals.scale.custom_slots = data.custom_scales end
            if data.snapshots then Globals.snapshots = data.snapshots end
        end
    else
        print("LTRA: No sidecar data found (New PSET?)")
    end
    
    -- 2. Cargar Audio
    local audio_path_L = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_L.wav"
    local audio_path_R = _path.audio .. "ltra/snapshots/pset_" .. pset_number .. "_R.wav"
    
    if util.file_exists(audio_path_L) then
        -- Cargar en Buffer 1 y 2
        softcut.buffer_read_mono(audio_path_L, 0, 0, -1, 1, 1)
        softcut.buffer_read_mono(audio_path_R, 0, 0, -1, 1, 2)
    else
        print("LTRA: No audio found for this PSET.")
        -- Opcional: Limpiar buffers si no hay audio, para evitar fantasmas
        softcut.buffer_clear()
    end
    
    -- 3. Sincronización Final
    -- Al cargar params, las acciones ya se dispararon, pero forzamos un sync de matriz por seguridad
    Bridge.sync_matrix()
    Globals.dirty = true
end

-- GESTIÓN DE SNAPSHOTS (RAM - Fila 7)
function Storage.save_snapshot(slot)
    local snap = { params={} }
    -- Iterar todos los parámetros del sistema
    for _, id in ipairs(params.lookup) do
        local p = params:lookup_param(id)
        -- Filtrar solo los relevantes (Sonido) usando patrones definidos en Consts
        for _, pat in ipairs(Consts.SNAPSHOT_PATTERNS) do
            if string.find(p.id, pat) then
                snap.params[p.id] = p:get()
                break
            end
        end
    end
    Globals.snapshots[slot] = snap
    print("LTRA: Snapshot "..slot.." saved to RAM.")
end

function Storage.load_snapshot(slot)
    local snap = Globals.snapshots[slot]
    if not snap then return end
    
    -- Aplicar valores (esto dispara las acciones y actualiza el Engine)
    for id, val in pairs(snap.params) do
        params:set(id, val) 
    end
    print("LTRA: Snapshot "..slot.." loaded.")
end

return Storage
