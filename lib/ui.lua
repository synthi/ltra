-- code/ltra/lib/ui.lua | v1.2.1
-- LTRA: Screen Interface
-- FIX: Restored Latch Indicator (Regression Fix)

local UI = {}
local Globals
local Consts = require 'ltra/lib/consts'

function UI.init(g_ref) Globals = g_ref end

local function draw_ghost_arrows()
    screen.level(15)
    for i=1, 16 do
        if Globals.fader_ghost[i] then
            local phys = Globals.fader_values[i] / 127
            local virt = Globals.fader_virtual[i]
            local x = 2 + ((i-1) * 8)
            local y = 62
            if math.abs(phys - virt) > 0.05 then
                if phys < virt then screen.move(x, y); screen.text("^")
                else screen.move(x, y); screen.text("v") end
            else screen.move(x, y); screen.text("-") end
        end
    end
end

local function draw_menu()
    screen.level(15); screen.rect(0,0,128,64); screen.fill(); screen.level(0)
    local t = Globals.menu_target
    local mode = Globals.menu_mode
    
    if mode == Consts.MENU.OSC then
        screen.move(5,10); screen.text("OSC "..t.." EDIT")
        screen.move(5,25); screen.text("E1 Shape: "..string.format("%.2f", params:get("osc"..t.."_shape")))
        screen.move(5,35); screen.text("E2 Pan: "..string.format("%.2f", params:get("osc"..t.."_pan")))
        screen.move(5,45); screen.text("E3 Tune: "..string.format("%.2f", params:get("osc"..t.."_tune")))
        local arp_state = params:get("osc"..t.."_arp") == 1 and "ON" or "OFF"
        screen.move(5,58); screen.text("K2: ARP ["..arp_state.."]")
        
    elseif mode == Consts.MENU.LFO then
        screen.move(5,10); screen.text("LFO "..t.." EDIT")
        screen.move(5,25); screen.text("E1 Shape: "..string.format("%.2f", params:get("lfo"..t.."_shape")))
        screen.move(5,35); screen.text("E2 Depth: "..string.format("%.2f", params:get("lfo"..t.."_depth")))
        screen.move(5,45); screen.text("E3 Rate: "..string.format("%.2f", params:get("lfo"..t.."_rate")))
        
    elseif mode == Consts.MENU.FILTER then
        screen.move(5,10); screen.text("FILTER EDIT")
        local f_idx = t
        screen.move(5,25); screen.text("E1 Tone: "..string.format("%.2f", params:get("filt"..f_idx.."_tone")))
        screen.move(5,35); screen.text("E2 Res: "..string.format("%.2f", params:get("filt"..f_idx.."_res")))
        screen.move(5,45); screen.text("E3 Drive: "..string.format("%.2f", params:get("filt_drive")))
        local type_str = params:get("filt_type") == 0 and "SVF" or "MOOG"
        screen.move(5,58); screen.text("K2: TYPE ["..type_str.."]")

    elseif mode == Consts.MENU.DELAY then
        screen.move(5,10); screen.text("TAPE DELAY")
        screen.move(5,25); screen.text("E1 Spread: "..string.format("%.2f", params:get("delay_spread")))
        screen.move(5,35); screen.text("E2 Erosion: "..string.format("%.2f", params:get("tape_erosion")))
        screen.move(5,45); screen.text("E3 Wow/Flut: "..string.format("%.2f", params:get("tape_wow")))
        
    elseif mode == Consts.MENU.REVERB then
        screen.move(5,10); screen.text("ATMOSPHERE / REV")
        screen.move(5,25); screen.text("E1 Dirt: "..string.format("%.2f", params:get("system_dirt")))
        screen.move(5,35); screen.text("E2 Decay: "..string.format("%.1fs", params:get("reverb_decay")))
        screen.move(5,45); screen.text("E3 Damp: "..string.format("%.2f", params:get("reverb_damp")))
        
    elseif mode == Consts.MENU.LOOPER then
        screen.move(5,10); screen.text("LOOPER "..t)
        screen.move(5,25); screen.text("E1 Send: "..string.format("%.2f", params:get("loop"..t.."_send")))
        screen.move(5,35); screen.text("E2 Fdbk: "..string.format("%.2f", params:get("loop"..t.."_feedback")))
        screen.move(5,45); screen.text("E3 Vol: "..string.format("%.2f", params:get("loop"..t.."_vol")))
        local pre_str = params:get("loop"..t.."_pre") == 1 and "PRE" or "POST"
        screen.move(5,58); screen.text("K2: ROUTE ["..pre_str.."]")
        
    elseif mode == Consts.MENU.MATRIX then
        screen.move(5,10); screen.text("MATRIX EDIT")
        if t and t.src_name then
            screen.move(5,25); screen.text(t.src_name .. " > " .. t.dest_name)
            local id = "mat_"..t.src_name.."_"..t.dest_name
            local val = params:get(id)
            screen.move(5,40); screen.text("AMOUNT: " .. string.format("%.2f", val))
            screen.move(5,55); screen.text("E3: Adjust  K2: Invert")
        end
    end
end

function UI.redraw()
    screen.clear()
    screen.aa(0)
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        draw_menu()
    elseif Globals.ui_popup.active then
        if util.time() > Globals.ui_popup.deadline then 
            Globals.ui_popup.active = false 
        else
            screen.level(15); screen.rect(10,20,108,20); screen.fill(); screen.level(0)
            screen.move(64,34); screen.text_center(Globals.ui_popup.text.." "..Globals.ui_popup.val)
        end
        draw_ghost_arrows()
    else
        screen.level(15); screen.move(0,10); screen.text("LTRA v1.2")
        
        -- INDICADOR DE LATCH (RECUPERADO)
        if Globals.latch_mode then 
            screen.move(120, 10); screen.text("L") 
        end
        
        screen.level(3)
        local s_name = Consts.SCALES_A[Globals.scale.current_idx].name
        if Globals.scale.current_idx > #Consts.SCALES_A then 
            s_name = Consts.SCALES_B[Globals.scale.current_idx-#Consts.SCALES_A].name 
        end
        screen.move(0, 30); screen.text("Scl: "..s_name)
        screen.move(0, 40); screen.text("Root: "..Consts.NOTE_NAMES[Globals.scale.root_note])
        
        local vu_l = util.clamp(Globals.visuals.amp_l * 40, 0, 40)
        local vu_r = util.clamp(Globals.visuals.amp_r * 40, 0, 40)
        screen.level(15)
        screen.rect(110, 50, 4, -vu_l); screen.fill()
        screen.rect(116, 50, 4, -vu_r); screen.fill()
        
        draw_ghost_arrows()
    end
    screen.update()
end

return UI
