-- Exercise the shipped Lua scheduler and pointer bindings without retail data.
local saved = {clay=clay, font=font, app=app, input=input, gfx=gfx, ui=ui}
local ticks, presents, keys = 0, 0, {}
local pointer = {down=false,pos=vec2()}
clay = {start=function() return true end, tick=function() ticks=ticks+1 end,
    present=function() presents=presents+1 end, stop=function() end,
    key=function(key,down) keys[#keys+1]={key,down} end}
font={load=function() return 0 end}
app={arg=function() return true end}
input={get=function() return pointer end}
gfx={rect=function() end}
ui={label=function() end}
local game=require('main')
game.init()
for _=1,120 do game.frame(1/120) end
assert(ticks==60 and presents==120, '60 Hz simulation at 120 Hz display')
game.frame(10)
assert(ticks==68, 'stalls are capped at eight simulation ticks')
pointer={down=true,pos=vec2(25,410)};game.frame(0)
assert(keys[#keys][1]==string.byte('w') and keys[#keys][2], 'touch movement belongs to player one')
pointer={down=false,pos=vec2(25,410)};game.frame(0)
assert(keys[#keys][1]==string.byte('w') and not keys[#keys][2], 'touch release clears movement')
game.quit()
clay,font,app,input,gfx,ui=saved.clay,saved.font,saved.app,saved.input,saved.gfx,saved.ui
