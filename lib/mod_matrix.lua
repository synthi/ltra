-- code/ltra/lib/mod_matrix.lua | v1.0
-- LTRA: Matrix Logic

local Matrix = {}
local Globals
local Bridge = require 'ltra/lib/engine_bridge'
local Consts = require 'ltra/lib/consts'

function Matrix.init(g_ref) Globals = g_ref end

local ROW_TO_SOURCE = { [1]="LFO1", [2]="LFO2", [3]="CHAOS", [4]="OUTLINE" }
local COL_TO_DEST = {
    [1]="PITCH1", [2]="PITCH2", [3]="PITCH3", [4]="PITCH4",
    [5]="AMP1",   [6]="AMP2",   [7]="AMP3",   [8]="AMP4",
    [9]="MORPH1", [10]="MORPH2", [11]="MORPH3", [12]="MORPH4",
    [13]="FILT1", [14]="FILT2",  [15]="DELAY_T", [16]="DELAY_F"
}

function Matrix.key(x, y, z)
    if z == 1 then
        -- Check Hold (Si es pulsación larga, GridPages abre menú, no cambiamos valor)
        -- Aquí asumimos click simple para cambiar valor
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
            
            local param_id = "mat_"..src_name.."_"..dest_name
            params:set(param_id, next_val)
        end
    end
end

function Matrix.draw(hw, led_func)
    for y=1, 4 do
        local mod_val = 0
        if y == 1 then mod_val = Globals.visuals.lfo_vals[1] or 0
        elseif y == 2 then mod_val = Globals.visuals.lfo_vals[2] or 0 end
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
                local base = 6
                if val > 0.4 then base = 9 end
                if val > 0.8 then base = 11 end
                active_b = math.min(15, math.floor(base + (anim_offset * 4)))
            end
            
            if active_b then led_func(x, y, active_b)
            else led_func(x, y, bg) end
        end
    end
end

return Matrix
