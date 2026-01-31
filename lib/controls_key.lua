-- =============================================================================
-- PROJECT: LTRA
-- FILE: lib/controls_key.lua
-- VERSION: v1.0 (Golden Master)
-- DESCRIPTION: Gestión de Teclas K2/K3 (Toggles y Funciones Globales).
-- =============================================================================

local Keys = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Keys.init(g_ref) Globals = g_ref end

function Keys.event(n, z)
    if z==0 then return end
    Globals.dirty = true
    
    -- MODO MENÚ
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==2 then -- Toggle Arp
                local curr = params:get("osc"..t.."_arp")
                params:set("osc"..t.."_arp", 1-curr)
            elseif n==3 then -- Toggle Route
                local curr = params:get("osc"..t.."_route")
                params:set("osc"..t.."_route", 1-curr)
            end
            
        elseif Globals.menu_mode == Consts.MENU.FILTER then
            if n==2 then -- Toggle Type
                local curr = params:get("filt_type")
                params:set("filt_type", 1-curr)
            end
            
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            if n==2 then -- Pre/Post
                local curr = params:get("loop"..t.."_pre")
                params:set("loop"..t.."_pre", 1-curr)
            elseif n==3 then -- Half Speed Toggle (Simulado)
                local curr = params:get("loop"..t.."_speed")
                if math.abs(curr) == 0.5 then params:set("loop"..t.."_speed", 1.0)
                else params:set("loop"..t.."_speed", 0.5) end
            end
            
        elseif Globals.menu_mode == Consts.MENU.MATRIX then
            if n==2 then -- Invertir Polaridad
                local src_idx = Consts.SOURCES[Globals.menu_target.src_name]
                local dst_idx = Consts.DESTINATIONS[Globals.menu_target.dest_name]
                if src_idx and dst_idx then
                    local current = Globals.matrix[src_idx][dst_idx]
                    local id = "mat_"..Globals.menu_target.src_name.."_"..Globals.menu_target.dest_name
                    params:set(id, current * -1)
                end
            end
        end
        return
    end
    
    -- GLOBAL
    if n==2 then
        -- K2 Global: Tap Tempo (Backup) o Panic
    elseif n==3 then
        -- K3 Global
    end
end
return Keys
