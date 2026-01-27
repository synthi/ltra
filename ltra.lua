-- ltra.lua | v0.9.6
-- LTRA: Main Script
-- FIX: Strict Initialization Order (Params before Active Subsystems)

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

function osc.event(path, args, from) Bridge.handle_osc(path, args) end

function init()
    print("LTRA: Initializing v0.9.6 (Golden Order)...")
    
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    -- NIVEL 0: ESTADO
    g_state = Globals.new()
    
    -- NIVEL 1: LÓGICA PASIVA
    Bridge.init(g_state)
    Scales.init(g_state)
    Matrix.init(g_state)
    
    -- NIVEL 2: DEFINICIÓN DE DATOS (CRÍTICO: ANTES DE ARP)
    if Params then Params.init(g_state) end
    
    -- NIVEL 3: SUBSISTEMAS ACTIVOS (Lectores de Params)
    Arp.init(g_state)      -- Lee 'arp_div' -> OK
    Loopers.init(g_state)  -- Configura softcut -> OK
    
    -- NIVEL 4: INTERFAZ Y CONTROL
    UI.init(g_state)
    Enc.init(g_state)
    Keys.init(g_state)
    Storage.init(g_state)
    
    -- NIVEL 5: HARDWARE GRID (Inyección)
    GridPages.init(g_state)
    GridHW.init(g_state, 1, GridPages)
    GridPages.set_hw(GridHW)
    
    -- NIVEL 6: SECUENCIADOR Y DIFERIDOS
    Gestures.init(g_state, GridPages)
    
    clock.run(function()
        clock.sleep(0.5)
        Midi16n.init(g_state, UI)
        Bridge.query_config()
    end)
    
    -- DEFAULTS
    Bridge.set_filter_tone(1, 0.0)
    Bridge.set_filter_tone(2, 0.0)
    Bridge.set_param("delay_send", 0.5)
    
    -- LOOPS
    local fps = metro.init()
    fps.time = 1/15
    fps.event = function() 
        if g_state.dirty then UI.redraw(); g_state.dirty = false end
    end
    fps:start()
    
    local grid_fps = metro.init()
    grid_fps.time = 1/30
    grid_fps.event = function() GridHW.redraw() end
    grid_fps:start()
    
    print("LTRA: System Ready.")
end

function key(n,z) Keys.event(n,z) end
function enc(n,d) Enc.delta(n,d) end
function redraw() UI.redraw() end
function cleanup() print("LTRA: Cleanup") end
