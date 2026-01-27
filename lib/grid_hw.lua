-- code/ltra/lib/grid_hw.lua | v0.6
local GridHW = {}
local Globals; local Pages; local g
local next_frame = {}

function GridHW.init(g_ref, dev, p_ref)
    Globals = g_ref; Pages = p_ref; g = grid.connect(dev)
    for x=1,16 do next_frame[x]={} for y=1,8 do next_frame[x][y]=0 end end
    g.key = function(x,y,z) Globals.button_state[x][y]=(z==1); if Pages then Pages.key(x,y,z) end end
end

function GridHW.led(x,y,v) next_frame[x][y]=math.floor(v) end

function GridHW.redraw()
    if not g then return end
    if Pages then Pages.redraw() end
    for x=1,16 do for y=1,8 do
        if next_frame[x][y] ~= Globals.led_cache[x][y] then
            g:led(x,y,next_frame[x][y]); Globals.led_cache[x][y]=next_frame[x][y]
        end
        next_frame[x][y]=0
    end end
    g:refresh()
end
return GridHW
