-- code/ltra/lib/controls_enc.lua | v0.6
local Enc = {}
local Globals
local Consts = require 'ltra/lib/consts'
local Bridge = require 'ltra/lib/engine_bridge'

function Enc.init(g_ref) Globals = g_ref end

function Enc.delta(n, d)
    Globals.dirty = true
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        local t = Globals.menu_target
        
        if Globals.menu_mode == Consts.MENU.OSC then
            if n==1 then params:delta("osc"..t.."_shape", d)
            elseif n==2 then params:delta("osc"..t.."_pan", d)
            elseif n==3 then params:delta("osc"..t.."_tune", d) end
            
        elseif Globals.menu_mode == Consts.MENU.FILTER then
            if n==1 then params:delta("filt"..t.."_tone", d)
            elseif n==2 then params:delta("filt"..t.."_res", d)
            elseif n==3 then params:delta("filt_drive", d) end
            
        elseif Globals.menu_mode == Consts.MENU.DELAY then
            if n==1 then params:delta("delay_spread", d)
            elseif n==2 then params:delta("tape_erosion", d)
            elseif n==3 then params:delta("tape_wow", d) end
            
        elseif Globals.menu_mode == Consts.MENU.REVERB then
            if n==1 then params:delta("system_dirt", d)
            elseif n==2 then params:delta("reverb_decay", d)
            elseif n==3 then params:delta("reverb_damp", d) end
            
        elseif Globals.menu_mode == Consts.MENU.LOOPER then
            if n==1 then 
                Globals.tracks[t].send_space = util.clamp(Globals.tracks[t].send_space + d*0.05, 0, 1)
            elseif n==2 then 
                Globals.tracks[t].feedback = util.clamp(Globals.tracks[t].feedback + d*0.05, 0, 1)
            elseif n==3 then 
                Globals.tracks[t].vol = util.clamp(Globals.tracks[t].vol + d*0.05, 0, 1)
            end
        end
        return
    end
    
    -- Main Nav
    if n==1 then params:delta("output_level", d) end
end
return Enc
