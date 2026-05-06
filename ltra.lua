-- ltra.lua | v3.0.0
-- FIX: sync_watcher BPM change triggers LFO phase reset

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
local MidiIn = require('ltra/lib/midi_in')

local g_state

function osc.event(path, args, from) 
    if path == "/ltra/ready" then
        if not g_state.engine_ready then
            g_state.engine_ready = true
            g_state.loaded = true -- FIX: Set loaded BEFORE bang so actions execute
            params:bang()
            Midi16n.sync_faders() 
            Scales.update_all_voices() -- FIX: Force scale map to SC on init
            g_state.dirty = true
            print("LTRA: Engine Ready. Handshake complete.")
        end
    end
    Bridge.handle_osc(path, args) 
end

function init()
    print("LTRA: Initializing v3.0.0...")
    
    util.make_dir(_path.data .. "ltra")
    util.make_dir(_path.audio .. "ltra/snapshots")
    
    g_state = Globals.new()
    g_state.tap_last = 0
    g_state.loaded = false 
    g_state.engine_ready = false
    
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
    MidiIn.init(g_state)
    
    GridPages.init(g_state, nil)
    GridHW.init(g_state, 1, GridPages)
    GridPages.set_hw(GridHW)
    
    local amp_out_l = poll.set("amp_out_l")
    local amp_out_r = poll.set("amp_out_r")
    amp_out_l.time = 1/15
    amp_out_r.time = 1/15
    amp_out_l.callback = function(v) g_state.visuals.amp_l = v end
    amp_out_r.callback = function(v) g_state.visuals.amp_r = v end
    amp_out_l:start()
    amp_out_r:start()
    
    clock.run(function()
        clock.sleep(0.5) 
        Midi16n.init(g_state, UI)
        Bridge.query_config()
        engine.ping() 
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
    local last_sync_bpm = 0
    sync_watcher.event = function()
        if not g_state.loaded then return end
        local bpm = params:get("clock_tempo")
        -- FIX #7: Detect BPM change and trigger LFO phase reset
        if last_sync_bpm > 0 and math.abs(bpm - last_sync_bpm) > 0.5 then
            Bridge.reset_lfo()
        end
        last_sync_bpm = bpm
        local function update_sync(name)
            if params:get(name.."_sync") == 1 then
                local div_idx = params:get(name.."_div")
                local div_val = Consts.SYNC_DIVS[div_idx].v
                local hz = (bpm / 60) / div_val
                Bridge.set_param(name.."_rate", hz)
            end
        end
        for i=1, 4 do
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
    MidiIn.stop() 
    
    if g_state and g_state.gesture_loopers then
        for i=1, 4 do
            if g_state.gesture_loopers[i].clock then
                clock.cancel(g_state.gesture_loopers[i].clock)
            end
        end
    end
    
    metro.free_all()
end
