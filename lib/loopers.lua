-- lib/loopers.lua | v2.0.0
-- FIX: 3 Stereo Loopers, 110s Buffer Allocation, Bidirectional Fades

local Loopers = {}
local Globals

function Loopers.init(g_ref)
    Globals = g_ref
    audio.level_eng_cut(1)
    
    -- 3 Loopers (6 voices total)
    for i=1, 3 do
        local v_l = (i*2)-1
        local v_r = i*2
        
        -- Left Channel (Buffer 1)
        softcut.enable(v_l, 1)
        softcut.buffer(v_l, 1)
        softcut.level(v_l, 1.0)
        softcut.loop(v_l, 1)
        softcut.rate(v_l, 1.0)
        softcut.fade_time(v_l, 0.005) -- 5ms fade to preserve transients
        softcut.post_filter_fc(v_l, 18000)
        softcut.level_input_cut(1, v_l, 1.0)
        softcut.level_input_cut(2, v_l, 0.0)
        softcut.pan(v_l, -1.0)
        
        -- Right Channel (Buffer 2)
        softcut.enable(v_r, 1)
        softcut.buffer(v_r, 2)
        softcut.level(v_r, 1.0)
        softcut.loop(v_r, 1)
        softcut.rate(v_r, 1.0)
        softcut.fade_time(v_r, 0.005)
        softcut.post_filter_fc(v_r, 18000)
        softcut.level_input_cut(1, v_r, 0.0)
        softcut.level_input_cut(2, v_r, 1.0)
        softcut.pan(v_r, 1.0)
        
        -- 110 seconds per looper (349s total memory / 3 = 116s. 110s is safe margin)
        local start_pos = (i-1) * 115
        softcut.loop_start(v_l, start_pos)
        softcut.loop_end(v_l, start_pos + 110)
        softcut.position(v_l, start_pos)
        
        softcut.loop_start(v_r, start_pos)
        softcut.loop_end(v_r, start_pos + 110)
        softcut.position(v_r, start_pos)
        
        Globals.loopers = Globals.loopers or {}
        Globals.loopers[i] = { state = 0, start_pos = start_pos, end_pos = start_pos + 110, rec_start_time = 0, current_vol = 1.0 }
    end
end

function Loopers.set_vol(idx, val)
    local l = Globals.loopers[idx]
    if l and (l.state == 1 or l.state == 2 or l.state == 3) then 
        softcut.level((idx*2)-1, val) 
        softcut.level(idx*2, val) 
        l.current_vol = val
    end
end

function Loopers.set_cut(idx, val) 
    softcut.post_filter_fc((idx*2)-1, val) 
    softcut.post_filter_fc(idx*2, val) 
end

function Loopers.set_res(idx, val) 
    local rq = util.linlin(0, 1, 2.0, 0.1, val)
    softcut.post_filter_rq((idx*2)-1, rq) 
    softcut.post_filter_rq(idx*2, rq) 
end

function Loopers.set_pan(idx, val) 
    -- Stereo Balance
    local v1_pan = val - 1
    local v2_pan = val + 1
    softcut.pan((idx*2)-1, util.clamp(v1_pan, -1, 1)) 
    softcut.pan(idx*2, util.clamp(v2_pan, -1, 1)) 
end

function Loopers.close_loop(idx)
    local l = Globals.loopers[idx]
    if l.state == 1 then
        if l.overflow_clock then clock.cancel(l.overflow_clock); l.overflow_clock = nil end
        l.state = 2
        local elapsed = util.time() - l.rec_start_time
        if elapsed > 110 then elapsed = 110 end 
        l.end_pos = l.start_pos + elapsed
        softcut.loop_end((idx*2)-1, l.end_pos)
        softcut.loop_end(idx*2, l.end_pos)
        softcut.rec((idx*2)-1, 0)
        softcut.rec(idx*2, 0)
    end
end

function Loopers.do_fade(idx, is_fade_in)
    local l = Globals.loopers[idx]
    local fade_time = params:get("looper"..idx.."_fade") or 0
    local target_vol = params:get("looper"..idx.."_vol") or 1.0

    if l.fade_clock then clock.cancel(l.fade_clock) end

    if fade_time <= 0 then
        if is_fade_in then
            l.current_vol = target_vol
            softcut.level((idx*2)-1, target_vol)
            softcut.level(idx*2, target_vol)
            softcut.play((idx*2)-1, 1)
            softcut.play(idx*2, 1)
            l.state = 2
        else
            l.current_vol = 0
            softcut.level((idx*2)-1, 0)
            softcut.level(idx*2, 0)
            softcut.play((idx*2)-1, 0)
            softcut.play(idx*2, 0)
            softcut.rec((idx*2)-1, 0)
            softcut.rec(idx*2, 0)
            l.state = 4
        end
        return
    end

    local steps = math.floor(fade_time * 20)
    if steps < 1 then steps = 1 end
    local step_time = fade_time / steps

    if is_fade_in then
        l.state = 6
        local start_vol = l.current_vol or 0
        softcut.level((idx*2)-1, start_vol)
        softcut.level(idx*2, start_vol)
        softcut.play((idx*2)-1, 1)
        softcut.play(idx*2, 1)

        l.fade_clock = clock.run(function()
            for i=1, steps do
                l.current_vol = start_vol + (target_vol - start_vol) * (i/steps)
                softcut.level((idx*2)-1, l.current_vol)
                softcut.level(idx*2, l.current_vol)
                clock.sleep(step_time)
            end
            l.current_vol = target_vol
            softcut.level((idx*2)-1, target_vol)
            softcut.level(idx*2, target_vol)
            l.state = 2
        end)
    else
        l.state = 5
        local start_vol = l.current_vol or target_vol
        l.fade_clock = clock.run(function()
            for i=1, steps do
                l.current_vol = start_vol * (1 - (i/steps))
                softcut.level((idx*2)-1, l.current_vol)
                softcut.level(idx*2, l.current_vol)
                clock.sleep(step_time)
            end
            l.current_vol = 0
            softcut.level((idx*2)-1, 0)
            softcut.level(idx*2, 0)
            softcut.play((idx*2)-1, 0)
            softcut.play(idx*2, 0)
            softcut.rec((idx*2)-1, 0)
            softcut.rec(idx*2, 0)
            l.state = 4
        end)
    end
end

function Loopers.stop_looper(idx)
    Loopers.do_fade(idx, false)
end

function Loopers.handle_button(idx)
    local l = Globals.loopers[idx]
    
    if l.state == 0 then
        l.state = 1
        l.rec_start_time = util.time()
        l.current_vol = params:get("looper"..idx.."_vol") or 1.0
        softcut.level((idx*2)-1, l.current_vol)
        softcut.level(idx*2, l.current_vol)
        softcut.position((idx*2)-1, l.start_pos)
        softcut.position(idx*2, l.start_pos)
        softcut.rec_level((idx*2)-1, 1.0)
        softcut.rec_level(idx*2, 1.0)
        softcut.pre_level((idx*2)-1, 0.0)
        softcut.pre_level(idx*2, 0.0)
        softcut.rec((idx*2)-1, 1)
        softcut.rec(idx*2, 1)
        softcut.play((idx*2)-1, 1)
        softcut.play(idx*2, 1)
        
        l.overflow_clock = clock.run(function()
            clock.sleep(110)
            Loopers.close_loop(idx)
        end)
        
    elseif l.state == 1 then
        Loopers.close_loop(idx)
    elseif l.state == 2 or l.state == 6 then
        if l.fade_clock then clock.cancel(l.fade_clock) end
        l.state = 3
        l.current_vol = params:get("looper"..idx.."_vol") or 1.0
        softcut.level((idx*2)-1, l.current_vol)
        softcut.level(idx*2, l.current_vol)
        softcut.rec_level((idx*2)-1, 1.0)
        softcut.rec_level(idx*2, 1.0)
        softcut.pre_level((idx*2)-1, 1.0)
        softcut.pre_level(idx*2, 1.0)
        softcut.rec((idx*2)-1, 1)
        softcut.rec(idx*2, 1)
    elseif l.state == 3 then
        l.state = 2
        softcut.rec((idx*2)-1, 0)
        softcut.rec(idx*2, 0)
    elseif l.state == 4 or l.state == 5 then
        Loopers.do_fade(idx, true) 
    end
end

function Loopers.clear(idx)
    local l = Globals.loopers[idx]
    if l.fade_clock then clock.cancel(l.fade_clock) end
    if l.overflow_clock then clock.cancel(l.overflow_clock) end
    l.state = 0
    l.current_vol = 0
    softcut.rec((idx*2)-1, 0)
    softcut.rec(idx*2, 0)
    softcut.play((idx*2)-1, 0)
    softcut.play(idx*2, 0)
    softcut.level((idx*2)-1, 0)
    softcut.level(idx*2, 0)
    softcut.buffer_clear_region(l.start_pos, 110)
    softcut.loop_end((idx*2)-1, l.start_pos + 110)
    softcut.loop_end(idx*2, l.start_pos + 110)
end

return Loopers
