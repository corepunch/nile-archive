-- Full original simulation/rendering is game-local C; Lua schedules the app.
local ready,acc,font_id=false,0
local buttons={{'↑',string.byte('w'),15,400},{'↓',string.byte('s'),65,400},{'←',string.byte('a'),15,445},{'→',string.byte('d'),65,445},
 {'HQ',string.byte('r'),430,400},{'HF',string.byte('t'),510,400},{'LQ',string.byte('f'),430,445},{'LF',string.byte('g'),510,445},
 {'SELECT',13,210,445},{'BACK',27,310,445}}
local held={}
local function init() ready=clay.start();font_id=font.load('LilitaOne-Regular.ttf') end
local function frame(dt)
    if not ready then
        ui.label(app.screen(),style{font=font_id,size=22,fill=color.WHITE},vec2(.5,.5),
            'CLAYFIGHT\nSupply your Primal Rage arcade ROMs.\nSee games/clayfight/README.md')
        return
    end
    acc=math.min(acc+dt,8/60)
    while acc>=1/60 do clay.tick();acc=acc-1/60 end
    clay.present()
    -- Desktop pointer controls; iOS has a native multi-touch overlay.
    if app.arg('touch') then
        local p=input.get()
        for i,b in ipairs(buttons) do
            local box=rect(b[3],b[4],75,32)
            local down=p.down and box:contains(p.pos)
            if down~=not not held[i] then clay.key(b[2],down);held[i]=down end
            gfx.rect(box,color(0,0,0,170))
            ui.label(box,style{font=font_id,size=16,fill=color.WHITE},vec2(.5,.5),b[1])
        end
    end
end
return {title='Clayfight',id='clayfight',design=size2(672,480),fixed=true,landscape=true,
 clear=color.BLACK,init=init,frame=frame,quit=function()clay.stop()end}
