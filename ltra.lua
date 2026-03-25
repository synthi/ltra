-- ltra.lua | v2.0.0
-- FIX: Init MidiIn

engine.name = 'Ltra'

local Globals = require('ltra/lib/globals')
local Consts = require('ltra/lib/consts')
local Bridge = require('ltra/lib/engine_bridge')
local Scales = require('ltra/lib/scales')
local GridHW = require('ltra/lib/grid_hw')
local GridPages = require('ltra/lib/grid_pages')
local Matrix = require('ltra/lib/mod_matrix')
local Midi16n = require('ltra/lib/midi_16n')
local UI = require('ltra/lib/ui')
local Params = require('ltra/lib/parameters')
local Arp = require('ltra/lib/arp')
local Enc = require('ltra/lib/controls_enc')
local Keys = require('ltra/lib/controls_key')
local Storage = require('ltra/lib/storage')
local Loopers = require('ltra/lib/loopers')
local MidiIn = require('ltra/lib/midi_in') -- FIX: Added MidiIn

local g_state

function osc.event(path, args, from) Bridge.handle_osc(path, args) end

function init()
    print("LTRA: Initializing v2.0.0 (Golden Master 8)...")
    
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    g_state = Globals.new()
    g_state.tap_last = 0
    g_state.loaded = false 
    
    g_state.latch_mode = false
    for i=1, 4 do 
        g_state.voices[i].latched = false 
        g_state.voices[i].sustained = false 
    end
    
    Bridge.init(g_state)
    Scales.init(g_state)
    Matrix.init(g_state)
    Params.init(g_state)
    UI.init(g_state)
    Arp.init(g_state)
    Enc.init(g_state)
    Keys.init(g_state)
    Storage.init(g_state)
    Loopers.init(g_state)
    MidiIn.init(g_state) -- FIX: Init MidiIn
    
    GridPages.init(g_state, nil)
    GridHW.init(g_state, 1, GridPages)
    GridPages.set_hw(GridHW)
    
    clock.run(function()
        clock.sleep(1.0) 
        Midi16n.init(g_state, UI)
        Bridge.query_config()
        
        params:bang()
        g_state.dirty = true
        
        g_state.loaded = true
        print("LTRA: System Ready. Audio Engine Active.")
    end)
    
    local fps = metro.init()
    fps.time = 1/15 
    fps.event = function() 
        if g_state.ui_popup.active and util.time() > g_state.ui_popup.deadline then
            g_state.ui_popup.active = false
            g_state.dirty = true
        end
        if g_state.dirty then 
            redraw() 
            g_state.dirty = false 
        end
    end
    fps:start()
    
    local grid_fps = metro.init()
    grid_fps.time = 1/30
    grid_fps.event = function() 
        if g_state.loaded then GridHW.redraw() end 
    end
    grid_fps:start()
    
    local sync_watcher = metro.init()
    sync_watcher.time = 0.5
    sync_watcher.event = function()
        if not g_state.loaded then return end
        local bpm = params:get("clock_tempo")
        local function update_sync(name)
            if params:get(name.."_sync") == 1 then
                local div_idx = params:get(name.."_div")
                local div_val = Consts.SYNC_DIVS[div_idx].v
                local hz = (bpm / 60) / div_val
                Bridge.set_param(name.."_rate", hz)
            end
        end
        for i=1, 3 do
            update_sync("mod"..i.."_lfo")
            update_sync("mod"..i.."_chaos")
        end
    end
    sync_watcher:start()
end

function key(n,z) 
    if not g_state or not g_state.loaded then return end
    pcall(Keys.event, n, z) 
end

function enc(n,d) 
    if not g_state or not g_state.loaded then return end
    pcall(Enc.delta, n, d) 
end

function redraw()
    if not g_state or not g_state.loaded then return end
    pcall(UI.redraw)
end

function cleanup() 
    print("LTRA: Cleanup")
    Arp.stop()
    Midi16n.stop()
    metro.free_all()
end
