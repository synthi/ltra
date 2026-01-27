-- code/ltra/lib/mod_matrix.lua | v0.7
-- LTRA: Matriz Animada

local Matrix = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Matrix.init(g_ref) Globals = g_ref end

local ROW_TO_SOURCE = { [1]="LFO1", [2]="LFO2", [3]="CHAOS", [4]="OUTLINE" }
local COL_TO_DEST = {
    [1]="pitch1", [2]="pitch2", [3]="pitch3", [4]="pitch4",
    [5]="amp1",   [6]="amp2",   [7]="amp3",   [8]="amp4",
    [9]="shape1", [10]="shape2", [11]="shape3", [12]="shape4",
    [13]="filt1", [14]="filt2",  [15]="delay_t", [16]="delay_f"
}

function Matrix.key(x, y, z)
    -- (Lógica de click igual que v0.5.3)
    if z == 1 then
        local src_name = ROW_TO_SOURCE[y]
        local dest_name = COL_TO_DEST[x]
        if src_name and dest_name then
            local src_idx = Consts.SOURCES[src_name]
            local current_val = Globals.matrix[src_idx][x]
            local next_val = Consts.MATRIX_CYCLES[1]
            for i, v in ipairs(Consts.MATRIX_CYCLES) do
                if math.abs(current_val - v) < 0.05 then
                    if i < #Consts.MATRIX_CYCLES then next_val = Consts.MATRIX_CYCLES[i+1]
                    else next_val = Consts.MATRIX_CYCLES[1] end
                    break
                end
            end
            if current_val < 0.01 then next_val = 1.0 end
            Globals.matrix[src_idx][x] = next_val
            
            local param_type = string.match(dest_name, "^([a-z_]+)")
            local voice_idx = string.match(dest_name, "(%d+)$") or "" 
            if x >= 13 then
                local param_id = "mod_" .. string.lower(src_name) .. "_" .. dest_name
                Bridge.set_param(param_id, next_val)
            else
                Bridge.set_matrix(string.lower(src_name), param_type, voice_idx, next_val)
            end
        end
    end
end

function Matrix.draw(hw, led_func)
    for y=1, 4 do
        -- Obtener valor instantáneo de la fuente para animación
        local mod_val = 0
        if y == 1 then mod_val = Globals.visuals.lfo_vals[1] or 0
        elseif y == 2 then mod_val = Globals.visuals.lfo_vals[2] or 0
        -- Chaos/Outline no tienen visual feedback por OSC aun, usar estático
        end
        
        -- Normalizar bipolar -1..1 a 0..1 para brillo
        local anim_offset = math.abs(mod_val) 

        for x=1, 16 do
            local src_idx = Consts.SOURCES[ROW_TO_SOURCE[y]]
            local val = Globals.matrix[src_idx][x]
            
            local bg = Consts.BRIGHT.BG_MATRIX_A
            if x > 4 and x <= 8 then bg = Consts.BRIGHT.BG_MATRIX_B end 
            if x > 12 then 
                if x%2==0 then bg = Consts.BRIGHT.BG_MATRIX_B else bg = Consts.BRIGHT.BG_MATRIX_A end
            end
            
            local active_b = nil
            if val > 0.01 then
                -- Base brightness
                local base = 6
                if val > 0.4 then base = 9 end
                if val > 0.8 then base = 11 end
                
                -- Sumar animación
                active_b = math.min(15, math.floor(base + (anim_offset * 4)))
            end
            
            if active_b then led_func(x, y, active_b)
            else led_func(x, y, bg) end
        end
    end
end

return Matrix
