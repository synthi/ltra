-- code/ltra/lib/controls_key.lua | v0.6
local Keys = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Keys.init(g_ref) Globals = g_ref end

function Keys.event(n, z)
    if z==0 then return end
    Globals.dirty = true
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==2 then Globals.voices[t].arp_enabled = not Globals.voices[t].arp_enabled
            elseif n==3 then Globals.voices[t].to_looper = not Globals.voices[t].to_looper end
            
        elseif Globals.menu_mode == Consts.MENU.FILTER then
            if n==2 then -- Toggle Type
                local curr = params:get("filt_type")
                params:set("filt_type", 1-curr)
            end
            
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            if n==2 then Globals.tracks[t].pre_fx = not Globals.tracks[t].pre_fx
            elseif n==3 then -- Half Speed
                if math.abs(Globals.tracks[t].speed) == 0.5 then Globals.tracks[t].speed = 1.0 
                else Globals.tracks[t].speed = 0.5 end
            end
        end
    end
end
return Keys
