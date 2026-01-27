-- code/ltra/lib/ui.lua | v0.6
-- LTRA: Screen Interface (Menus & Ghost Faders)

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
            local x = 5 + ((i-1) * 8)
            local y = 60
            
            -- Dibujar flecha indicando hacia dónde mover
            if math.abs(phys - virt) > 0.05 then
                if phys < virt then
                    screen.move(x, y); screen.text("^") -- Mover arriba
                else
                    screen.move(x, y); screen.text("v") -- Mover abajo
                end
            else
                screen.move(x, y); screen.text("-") -- Cerca
            end
        end
    end
end

local function draw_menu()
    screen.level(15); screen.rect(0,0,128,64); screen.fill(); screen.level(0)
    local t = Globals.menu_target
    
    if Globals.menu_mode == Consts.MENU.OSC then
        screen.move(5,10); screen.text("OSC "..t.." EDIT")
        screen.move(5,25); screen.text("E1 Shape: "..string.format("%.2f", params:get("osc"..t.."_shape")))
        screen.move(5,35); screen.text("E2 Pan: "..string.format("%.2f", params:get("osc"..t.."_pan")))
        screen.move(5,45); screen.text("E3 Tune: "..string.format("%.2f", params:get("osc"..t.."_tune")))
        screen.move(5,58); screen.text("K2: ARP "..(Globals.voices[t].arp_enabled and "ON" or "OFF"))
        
    elseif Globals.menu_mode == Consts.MENU.FILTER then
        screen.move(5,10); screen.text("FILTER EDIT")
        screen.move(5,25); screen.text("E1 Tone: "..string.format("%.2f", params:get("filt"..t.."_tone")))
        screen.move(5,35); screen.text("E2 Res: "..string.format("%.2f", params:get("filt"..t.."_res")))
        screen.move(5,45); screen.text("E3 Drive: "..string.format("%.2f", params:get("filt_drive")))
        screen.move(5,58); screen.text("K2 Type: "..(params:get("filt_type")==0 and "SVF" or "MOOG"))

    elseif Globals.menu_mode == Consts.MENU.DELAY then
        screen.move(5,10); screen.text("TAPE DELAY")
        screen.move(5,25); screen.text("E1 Spread: "..string.format("%.2f", params:get("delay_spread")))
        screen.move(5,35); screen.text("E2 Erosion: "..string.format("%.2f", params:get("tape_erosion")))
        screen.move(5,45); screen.text("E3 Wow/Flut: "..string.format("%.2f", params:get("tape_wow")))
        
    elseif Globals.menu_mode == Consts.MENU.REVERB then
        screen.move(5,10); screen.text("ATMOSPHERE")
        screen.move(5,25); screen.text("E1 Dirt: "..string.format("%.2f", params:get("system_dirt")))
        screen.move(5,35); screen.text("E2 Decay: "..string.format("%.1fs", params:get("reverb_decay")))
        screen.move(5,45); screen.text("E3 Damp: "..string.format("%.2f", params:get("reverb_damp")))
        
    elseif Globals.menu_mode == Consts.MENU.LOOPER then
        screen.move(5,10); screen.text("LOOPER "..t)
        screen.move(5,25); screen.text("E1 Send: "..string.format("%.2f", Globals.tracks[t].send_space))
        screen.move(5,35); screen.text("E2 Feedbk: "..string.format("%.2f", Globals.tracks[t].feedback))
        screen.move(5,45); screen.text("E3 Vol: "..string.format("%.2f", Globals.tracks[t].vol))
        screen.move(5,58); screen.text("K2: "..(Globals.tracks[t].pre_fx and "PRE" or "POST"))
    end
end

function UI.redraw()
    screen.clear()
    
    if Globals.menu_mode ~= Consts.MENU.NONE then
        draw_menu()
    elseif Globals.ui_popup.active then
        if util.time() > Globals.ui_popup.deadline then Globals.ui_popup.active = false end
        screen.level(15); screen.rect(10,20,108,20); screen.fill(); screen.level(0)
        screen.move(64,34); screen.text_center(Globals.ui_popup.text.." "..Globals.ui_popup.val)
        draw_ghost_arrows()
    else
        screen.level(15); screen.move(0,10); screen.text("LTRA v0.6")
        
        -- Info básica
        screen.level(3)
        screen.move(0, 30); screen.text("Scale: "..Consts.SCALES_A[Globals.scale.current_idx].name)
        screen.move(0, 40); screen.text("Root: "..Consts.NOTE_NAMES[Globals.scale.root_note])
        
        -- Vúmetros
        screen.level(15)
        screen.rect(110, 50, 4, -Globals.visuals.amp_l * 30); screen.fill()
        screen.rect(116, 50, 4, -Globals.visuals.amp_r * 30); screen.fill()
        
        draw_ghost_arrows()
    end
    screen.update()
end

return UI
