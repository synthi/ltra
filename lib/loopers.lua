-- code/ltra/lib/loopers.lua | v0.9
-- LTRA: Softcut Manager (Multitouch & Inertia)

local Loopers = {}
local Globals
local Consts = require 'ltra/lib/consts'

-- Estado local de dedos para multitouch
local held_keys = { {}, {}, {} } -- [track_idx][x] = true/nil

function Loopers.init(g_ref)
    Globals = g_ref
    audio.level_adc_cut(1) 
    
    for i=1, 3 do
        local pair = Consts.LOOPER_PAIRS[i]
        local bounds = Consts.LOOPER_BOUNDS[i]
        
        for _, v in ipairs(pair) do
            softcut.enable(v, 1); softcut.buffer(v, (v%2==1) and 1 or 2)
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
    print("LTRA: Audio Routing Configured")
end

-- MANEJO DE INPUT GRID (Multitouch)
function Loopers.handle_grid_input(track_idx, x, z)
    local t = Globals.tracks[track_idx]
    local bounds = Consts.LOOPER_BOUNDS[track_idx]
    local len = bounds.max - bounds.min
    local offset = (track_idx-1)*5
    
    -- Normalizar X a 1-5 (dentro de la cinta de 5 botones)
    local local_x = x - offset
    if local_x < 1 or local_x > 5 then return end -- Fuera de rango
    
    -- Actualizar tabla de dedos
    if z == 1 then
        held_keys[track_idx][x] = util.time() -- Guardar tiempo para inercia
    else
        -- Al soltar, calcular inercia si era el último dedo
        local press_time = held_keys[track_idx][x]
        if press_time then
            local dur = util.time() - press_time
            -- Si era un seek de velocidad, aplicar inercia aquí si se desea
            -- Por ahora solo limpiamos
        end
        held_keys[track_idx][x] = nil
    end
    
    -- Analizar estado actual de dedos
    local count = 0
    local min_x, max_x = 100, 0
    for k, _ in pairs(held_keys[track_idx]) do
        count = count + 1
        if k < min_x then min_x = k end
        if k > max_x then max_x = k end
    end
    
    local pair = Consts.LOOPER_PAIRS[track_idx]
    
    if count == 1 then
        -- SEEK (Salto)
        -- Mapear min_x (global) a posición relativa 0-1
        local rel_pos = (min_x - offset - 1) / 4 -- 0.0 a 1.0 (5 pasos)
        local abs_pos = bounds.min + (rel_pos * len)
        
        for _, v in ipairs(pair) do softcut.position(v, abs_pos) end
        
    elseif count == 2 then
        -- LOOP (Definir puntos)
        local rel_start = (min_x - offset - 1) / 4
        local rel_end = (max_x - offset - 1) / 4
        -- Asegurar mínimo tamaño
        if rel_end <= rel_start then rel_end = rel_start + 0.1 end
        
        local abs_start = bounds.min + (rel_start * len)
        local abs_end = bounds.min + (rel_end * len)
        
        for _, v in ipairs(pair) do 
            softcut.loop_start(v, abs_start)
            softcut.loop_end(v, abs_end)
        end
    end
end

function Loopers.transport_action(track_idx, action)
    local t = Globals.tracks[track_idx]
    local pair = Consts.LOOPER_PAIRS[track_idx]
    
    if action == "press" then
        if t.state == 1 then -- Empty -> Rec
            t.state = 2
            for _, v in ipairs(pair) do
                softcut.pre_level(v, 0.0); softcut.rec_level(v, 1.0); softcut.rec(v, 1)
            end
        elseif t.state == 2 then -- Rec -> Play
            t.state = 3
            for _, v in ipairs(pair) do softcut.rec(v, 0) end
        elseif t.state == 3 then -- Play -> Dub
            t.state = 4
            for _, v in ipairs(pair) do
                softcut.pre_level(v, t.feedback); softcut.rec_level(v, 1.0); softcut.rec(v, 1)
            end
        elseif t.state == 4 then -- Dub -> Play
            t.state = 3
            for _, v in ipairs(pair) do softcut.rec(v, 0) end
        end
    elseif action == "hold" then
        t.state = 1
        local bounds = Consts.LOOPER_BOUNDS[track_idx]
        for _, v in ipairs(pair) do 
            softcut.rec(v, 0); softcut.rate(v, 1.0)
            softcut.loop_start(v, bounds.min); softcut.loop_end(v, bounds.max)
            softcut.position(v, bounds.min)
        end
    end
end

return Loopers
