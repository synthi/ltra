-- code/ltra/lib/loopers.lua | v1.2
-- LTRA: Softcut Manager
-- FIX: Audio Routing Activation

local Loopers = {}
local Globals
local Consts = require 'ltra/lib/consts'
local held_keys = { {}, {}, {} } 

function Loopers.init(g_ref)
    Globals = g_ref
    
    -- Configuración Inicial Softcut
    audio.level_adc_cut(1) 
    
    for i=1, 3 do
        local pair = Consts.LOOPER_PAIRS[i]
        local bounds = Consts.LOOPER_BOUNDS[i]
        for _, v in ipairs(pair) do
            softcut.enable(v, 1); softcut.buffer(v, (v%2 == 1) and 1 or 2)
            softcut.level(v, 1.0); softcut.loop(v, 1)
            softcut.loop_start(v, bounds.min); softcut.loop_end(v, bounds.max)
            softcut.position(v, bounds.min); softcut.play(v, 1)
            softcut.rate(v, 1.0); softcut.fade_time(v, 0.05)
            softcut.post_filter_lp(v, 1.0); softcut.post_filter_dry(v, 0.0)
            softcut.post_filter_fc(v, 18000); softcut.post_filter_rq(v, 2.0)
        end
    end
    
    softcut.event_phase(function(v, pos)
        if v == 1 or v == 3 or v == 5 then
            local track_idx = (v+1)/2
            local bounds = Consts.LOOPER_BOUNDS[track_idx]
            local len = bounds.max - bounds.min
            local rel_pos = (pos - bounds.min) / len
            Globals.visuals.tape_heads[track_idx] = util.clamp(rel_pos, 0, 1)
            Globals.dirty = true
        end
    end)
    softcut.poll_start_phase()
end

function Loopers.configure_audio_routing(g_ref)
    -- ACTIVAR RUTEO GLOBAL SOFTCUT -> ENGINE
    audio.level_cut_eng(1.0) 
    -- Mantener salida directa también (Dry)
    audio.level_cut_dac(1.0)
    print("LTRA: Audio Routing Active (Cut->Eng)")
end

function Loopers.handle_grid_input(track_idx, x, z)
    local t = Globals.tracks[track_idx]
    local bounds = Consts.LOOPER_BOUNDS[track_idx]
    local len = bounds.max - bounds.min
    local offset = (track_idx-1)*5
    local local_x = x - offset
    if local_x < 1 or local_x > 5 then return end
    
    if z == 1 then held_keys[track_idx][x] = util.time()
    else held_keys[track_idx][x] = nil end
    
    local count = 0
    local min_x, max_x = 100, 0
    for k, _ in pairs(held_keys[track_idx]) do
        count = count + 1
        if k < min_x then min_x = k end
        if k > max_x then max_x = k end
    end
    
    local pair = Consts.LOOPER_PAIRS[track_idx]
    
    if count == 1 then
        local rel_pos = (min_x - offset - 1) / 4 
        local abs_pos = bounds.min + (rel_pos * len)
        for _, v in ipairs(pair) do softcut.position(v, abs_pos) end
    elseif count == 2 then
        local rel_start = (min_x - offset - 1) / 4
        local rel_end = (max_x - offset - 1) / 4
        if rel_end <= rel_start then rel_end = rel_start + 0.1 end
        local abs_start = bounds.min + (rel_start * len)
        local abs_end = bounds.min + (rel_end * len)
        for _, v in ipairs(pair) do 
            softcut.loop_start(v, abs_start); softcut.loop_end(v, abs_end)
        end
    end
end

function Loopers.transport_action(track_idx, action)
    local t = Globals.tracks[track_idx]
    local pair = Consts.LOOPER_PAIRS[track_idx]
    if action == "press" then
        if t.state == 1 then t.state = 2; for _, v in ipairs(pair) do softcut.pre_level(v, 0.0); softcut.rec_level(v, 1.0); softcut.rec(v, 1) end
        elseif t.state == 2 then t.state = 3; for _, v in ipairs(pair) do softcut.rec(v, 0) end
        elseif t.state == 3 then t.state = 4; for _, v in ipairs(pair) do softcut.pre_level(v, t.feedback); softcut.rec_level(v, 1.0); softcut.rec(v, 1) end
        elseif t.state == 4 then t.state = 3; for _, v in ipairs(pair) do softcut.rec(v, 0) end end
    elseif action == "hold" then
        t.state = 1
        local bounds = Consts.LOOPER_BOUNDS[track_idx]
        for _, v in ipairs(pair) do 
            softcut.rec(v, 0); softcut.rate(v, 1.0)
            softcut.loop_start(v, bounds.min); softcut.loop_end(v, bounds.max)
            softcut.position(v, bounds.min); softcut.pre_level(v, 1.0)
        end
    end
end

return Loopers
