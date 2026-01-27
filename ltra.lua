-- ltra.lua | v0.6.1
-- LTRA: Main Script (Final Assembly)
-- FIX: Params initialization with Globals injection

engine.name = 'Ltra'

local Globals = include('lib/globals')
local Consts = include('lib/consts')
local Bridge = include('lib/engine_bridge')
local Scales = include('lib/scales')
local GridHW = include('lib/grid_hw')
local GridPages = include('lib/grid_pages')
local Matrix = include('lib/mod_matrix')
local Midi16n = include('lib/midi_16n')
local Loopers = include('lib/loopers')
local Gestures = include('lib/seq_gestures')
local UI = include('lib/ui')
local Params = include('lib/parameters')
local Arp = include('lib/arp')
local Enc = include('lib/controls_enc')
local Keys = include('lib/controls_key')
local Storage = include('lib/storage')

local g_state

-- OSC HANDLER CENTRAL
function osc.event(path, args, from)
    Bridge.handle_osc(path, args)
end

function init()
    print("LTRA: Initializing v0.6.1...")
    
    -- 1. Crear directorios
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    -- 2. Estado Global
    g_state = Globals.new()
    
    -- 3. Inicializar Subsistemas
    Bridge.init(g_state)
    Scales.init(g_state)
    Matrix.init(g_state)
    Loopers.init(g_state)
    UI.init(g_state)
    Arp.init(g_state)
    Enc.init(g_state)
    Keys.init(g_state)
    Storage.init(g_state)
    
    -- 4. Grid (Inyección de Dependencias)
    GridPages.init(g_state)
    GridHW.init(g_state, 1, GridPages)
    GridPages.set_hw(GridHW)
    
    -- 5. Parámetros del Sistema (CORRECCIÓN AQUÍ)
    -- Pasamos g_state para que Params pueda actualizar Globals
    if Params then Params.init(g_state) end
    
    -- 6. Tareas Diferidas (MIDI y Audio Handshake)
    clock.run(function()
        clock.sleep(0.5)
        Midi16n.init(g_state, UI)
        Bridge.query_config()
    end)
    
    -- 7. Secuenciador
    Gestures.init(g_state, GridPages)
    
    -- 8. Defaults Audio
    Bridge.set_filter_tone(1, 0.0)
    Bridge.set_filter_tone(2, 0.0)
    Bridge.set_param("delay_send", 0.5)
    
    -- 9. UI Loop (Dirty Flag)
    local fps = metro.init()
    fps.time = 1/15
    fps.event = function() 
        if g_state.dirty then UI.redraw(); g_state.dirty = false end
    end
    fps:start()
    
    -- 10. Grid Loop (Buffer Cache)
    local grid_fps = metro.init()
    grid_fps.time = 1/30
    grid_fps.event = function() GridHW.redraw() end
    grid_fps:start()
    
    print("LTRA: System Ready.")
end

function key(n, z)
    Keys.event(n, z)
end

function enc(n, d)
    Enc.delta(n, d)
end

function redraw()
    UI.redraw()
end

function cleanup()
    print("LTRA: Cleanup")
end
