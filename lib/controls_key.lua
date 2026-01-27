-- code/ltra/lib/controls_key.lua | v0.9.5
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
            end
        end
        return
    end
    
    -- GLOBAL
    if n==2 then
        -- Tap Tempo (K2) ? O K1+K2?
        -- Norns nativo usa K1+K2 para params.
        -- Dejamos libre para futuro
    elseif n==3 then
        -- Panic?
    end
end
return Keys
