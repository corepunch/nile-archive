-- Volcano · After the Eruption. All presentation uses the shared engine.
local sim=require('volcano_sim')
local levels=require('volcano_levels')
local art=require('volcano_art')
local S={chapter=1,unlocked=1,completed=0,sound=true,screen='menu',textures={},backs={},best={0,0,0,0,0}}
local C={cream=color.hex(0xFFF2D2),ink=color.hex(0x193D43),gold=color.hex(0xF4CB78),teal=color.hex(0x234F55)}
local white=color.WHITE
-- Relic Rush's Lilita One palettes, with the rim and cast shadow scaled by em.
local palettes={
    cream={color(255,249,226),color(244,221,166)},
    gold={color(255,255,219),color(239,169,57)},
    green={color(199,255,201),color(91,198,130)},
    white={white,color(196,232,220)},
}
local function lettering(size,palette)
    local colors=palettes[palette or 'cream']
    local em=size/1.171875
    return style{font=S.font,size=size,fill=colors[1],fill2=colors[2],
        outline=color(62,49,29),outline_width=em*4/64,
        shadow=color(31,35,24,184),shadow_offset=vec2(0,em*5/64)}
end
local function label(box,value,size,align,palette)
    ui.label(box,lettering(size or 23,palette),align or vec2(0,.5),value)
end
local function serialize(s)
    s:int('version',1)
    S.unlocked=num.clampi(s:int('unlocked',S.unlocked),1,#levels)
    S.completed=s:int('completed',S.completed)&31
    S.sound=s:int('sound',S.sound and 1 or 0)~=0
    S.best=s:ints('best',S.best)
    story.serialize(s)
end
local function persist() if not S.testing then save.write('campaign',serialize) end end
local function load_back(i)
    if not S.backs[i] then S.backs[i]=texture.load(levels[i].background) end
    return S.backs[i]
end
local function camera_reset()
    S.cam=camera{center=vec2(684,513),zoom=1,world=size2(1368,1026),view=app.screen(),min_zoom=1,max_zoom=2.5}:clamp()
end
local function start(i,quiet)
    S.chapter=num.clampi(i,1,#levels);S.g=sim.new(levels[S.chapter]);S.screen='play';S.modal=nil;S.selected=nil
    S.banked=false;load_back(S.chapter);camera_reset();fx.clear()
    if not quiet then story.play('briefing-'..i,{{'dispatch',levels[i].briefing}}) end
end
local function animation(e)
    local d=e.def
    if d.kind=='worker' then
        if e.phase=='working' then return 'worker_'..e.target.def.action..(e.direction or 0) end
        if e.phase=='returning' or e.phase=='outbound' then return 'worker_run'..(e.direction or 0) end
        return 'worker_wait0'
    elseif d.kind=='civilian' then
        local prefix=e.id%2==0 and 'man_' or 'wman_'
        return prefix..(e.phase=='returning' and 'run'..(e.direction or 0) or 'idle0')
    elseif d.kind=='animal' then return e.type..e.variant..'_idle0'
    elseif d.kind=='station' then return d.sprite..(e.done and '' or '-damaged') end
    return d.sprite
end
local function frame_for(e)
    local name=animation(e);local a=art[name]
    if not a then return end
    return sprite.sample(a.frames,a.fps,S.g.time),a
end
local function sprite_rect(e)
    local f,a=frame_for(e)
    if f then return sprite.bounds(f,S.cam:to_screen(vec2(e.x,e.y)),a.scale*S.cam.zoom) end
end
local function visible(e)
    if e.def.kind=='obstacle' or e.def.kind=='animal' then return not e.done end
    return e.phase~='safe'
end
local function draw_one(e)
    if not visible(e) then return end
    local f,a=frame_for(e);if not f then return end
    local p=S.cam:to_screen(vec2(e.x,e.y))
    if e==S.selected or e.queued then gfx.ring(p,27*S.cam.zoom,2.5,C.gold) end
    sprite.draw(S.textures[a.image],f,p,a.scale*S.cam.zoom,white)
    if e.assigned and not e.done then
        local frac=0
        for _,w in ipairs(S.g.workers) do if w.target==e and w.phase=='working' then frac=w.work/(e.def.duration or 5) end end
        ui.progress(rect(p.x-31,p.y-70*S.cam.zoom,62,9),frac,'')
    elseif e.def.kind=='station' and e.done then
        ui.progress(rect(p.x-27,p.y-85*S.cam.zoom,54,6),e.clock/5,'')
    end
    if e.def.kind=='worker' and e.target and e.target.def.kind=='animal' and e.phase=='returning' then
        local pet=e.target;local run=art[pet.type..pet.variant..'_run'..(e.direction or 0)]
        sprite.draw(S.textures[run.image],sprite.sample(run.frames,run.fps,S.g.time),p+vec2(12,6),run.scale*S.cam.zoom,white)
    end
end
local function pick(p)
    local chosen,best=nil,math.huge
    for _,e in ipairs(S.g.objects) do if visible(e) then
        local r=sprite_rect(e)
        if r then
            local anchor=S.cam:to_screen(vec2(e.x,e.y))
            local dist=vec2.dist(p,anchor)
            if (r:inflate(9):contains(p) or dist<24) then
                local priority=sim.actionable(e) and 0 or 1000
                if dist+priority<best then chosen,best=e,dist+priority end
            end
        end
    end end
    return chosen
end
local function world()
    S.cam:draw_texture(load_back(S.chapter))
    local sorted={}
    for _,e in ipairs(S.g.objects) do sorted[#sorted+1]=e end
    table.sort(sorted,function(a,b) if a.y==b.y then return a.id<b.id end;return a.y<b.y end)
    for _,e in ipairs(sorted) do draw_one(e) end
end
local function hud()
    local g=S.g
    ui.panel(rect(14,12,1340,68))
    label(rect(34,20,336,24),('VOLCANO  /  %02d'):format(S.chapter),19,nil,'gold')
    label(rect(34,44,330,27),levels[S.chapter].title,25)
    local total=0;local idle=0
    for _,w in ipairs(g.workers) do if not w.recruit then total=total+1;if w.phase=='idle' then idle=idle+1 end end end
    for i,r in ipairs({'food','wood','money'}) do
        label(rect(385+(i-1)*167,20,155,23),r:upper(),15)
        label(rect(385+(i-1)*167,42,155,30),tostring(g.wallet[r]),29,nil,'gold')
    end
    label(rect(887,23,206,23),('WORKERS  %d / %d'):format(idle,total),20)
    label(rect(887,48,195,20),('%02d:%02d'):format(math.floor(g.time/60),math.floor(g.time%60)),17,nil,'white')
    if ui.button(rect(1114,24,106,44),'Hint') then
        S.selected=sim.suggest(g)
        if S.selected then
            S.cam=S.cam:look(vec2(S.selected.x,S.selected.y));ui.toast(S.selected.def.title..': '..sim.detail(g,S.selected))
        else ui.toast('Let the team finish its jobs and the stations deliver supplies.') end
    end
    if ui.button(rect(1230,24,110,44),'Pause') then S.modal='pause';g.paused=true end
    ui.panel(rect(14,932,1340,80))
    label(rect(34,943,440,26),S.selected and S.selected.def.title or 'Restore the city, one route at a time',23)
    label(rect(34,975,900,24),sim.detail(g,S.selected),17,nil,'white')
    local denominator=g.level.people+g.level.animals+g.routes
    local complete=g.rescued+g.animals+g.cleared
    label(rect(963,942,366,26),('People %d/%d   Pets %d/%d   Roads %d/%d'):format(g.rescued,g.level.people,g.animals,g.level.animals,g.cleared,g.routes),17)
    ui.progress(rect(966,978,361,12),complete/denominator,'')
end
local function menu()
    gfx.image(load_back(S.chapter),app.screen(),white)
    ui.modal_backdrop(.85)
    ui.panel(rect(325,110,718,806))
    label(rect(365,145,638,62),'VOLCANO',62,vec2(.5,.5),'gold')
    label(rect(365,215,638,30),'AFTER THE ERUPTION',24,vec2(.5,.5))
    label(rect(374,264,620,53),'Reopen the streets. Restore supplies. Bring everyone home.',23,vec2(.5,.5))
    for i,level in ipairs(levels) do
        local done=(S.completed&(1<<(i-1)))~=0
        local title=('%02d   %s%s'):format(i,level.title,done and '   - restored' or '')
        if ui.button(rect(380,340+(i-1)*82,608,64),title,i>S.unlocked and ui.DISABLED or (i==S.unlocked and ui.ACCENT or 0)) then start(i,false) end
    end
    if ui.button(rect(380,774,292,54),'How to play') then S.modal='help' end
    if ui.button(rect(690,774,298,54),S.sound and 'Sound: on' or 'Sound: off') then S.sound=not S.sound;sfx.enable(S.sound);persist() end
    label(rect(374,850,620,27),'Five districts. One rescue team. A fresh start.',20,vec2(.5,.5))
end
local function modal()
    local kind=S.modal
    if not kind then return end
    -- each panel fits its content: no empty band under the last button
    ui.set_enabled(true);ui.modal_backdrop(1);ui.panel(rect(344,226,680,kind=='pause' and 494 or kind=='win' and 534 or 544))
    local title=kind=='pause' and 'Rescue paused' or kind=='win' and 'District restored!' or 'Every route matters'
    label(rect(385,267,598,62),title,42,vec2(.5,.5),'gold')
    if kind=='win' then
        local g=S.g
        label(rect(390,342,588,112),('All %d residents and %d pets are safe.\n%d roads restored in %d:%02d.'):format(g.rescued,g.animals,g.routes,math.floor(g.time/60),math.floor(g.time%60)),27,vec2(.5,.5))
        if ui.button(rect(414,495,540,64),S.chapter<#levels and 'Next district' or 'Play the episode again',ui.ACCENT) then
            start(S.chapter<#levels and S.chapter+1 or 1,false)
        end
        if ui.button(rect(414,580,540,58),'Replay district') then start(S.chapter,false) end
        if ui.button(rect(414,660,540,58),'Districts') then S.screen='menu';S.modal=nil end
    elseif kind=='pause' then
        label(rect(398,350,572,52),'Your team and production are paused.',25,vec2(.5,.5))
        if ui.button(rect(414,442,540,64),'Resume rescue',ui.ACCENT) then S.modal=nil;S.g.paused=false end
        if ui.button(rect(414,533,540,58),'Restart district') then start(S.chapter,true) end
        if ui.button(rect(414,620,540,58),'Districts') then S.screen='menu';S.modal=nil end
    else
        label(rect(390,342,588,262),'Tap rubble, damaged roads or a station to assign a worker. Unavailable jobs join the queue; tap again to cancel.\n\nKitchens, timber yards and offices produce supplies automatically. Residents and stranded workers return when their route is safe. Assign a worker to rescue pets.\n\nDrag to pan. Pinch or scroll to zoom. Restore every road and bring everyone home.',23,vec2(0,0))
        if ui.button(rect(414,630,540,62),'Ready',ui.ACCENT) then S.modal=nil end
    end
end
local function smoke()
    S.smoke_frames=(S.smoke_frames or 0)+1
    if S.smoke_frames>130000 then error('Volcano smoke timed out at chapter '..S.chapter) end
    if S.smoke_frames%5~=0 then return end
    S.smoke_stage=S.smoke_stage or 0
    if story.active() then app.inject_click(vec2(680,510));return end
    if S.screen=='menu' then app.inject_click(vec2(680,372));return end
    if S.modal=='win' then
        assert(S.g.won,'smoke results without victory')
        if S.chapter==#levels then
            assert(S.completed==31,'smoke did not bank the entire campaign')
            S.smoke_stage=9;app.inject_click(vec2(680,527))
        else app.inject_click(vec2(680,527)) end
        return
    end
    if S.smoke_stage==9 then
        assert(S.chapter==1 and S.g.cleared==0,'final replay did not restart the episode')
        print('Volcano smoke: all five districts, pause, restart and final replay passed through injected clicks')
        app.quit();return
    elseif S.smoke_stage==0 then
        S.smoke_stage=1;app.inject_click(vec2(1280,46));return
    elseif S.smoke_stage==1 then
        assert(S.modal=='pause' and S.g.paused,'pause button failed')
        S.smoke_time=S.g.time;S.smoke_stage=2;return
    elseif S.smoke_stage==2 then
        assert(S.g.time==S.smoke_time,'paused world advanced')
        S.smoke_stage=3;app.inject_click(vec2(680,474));return
    elseif S.smoke_stage==3 then
        assert(not S.modal and not S.g.paused,'resume button failed')
        S.smoke_stage=4;app.inject_click(vec2(1280,46));return
    elseif S.smoke_stage==4 then
        assert(S.modal=='pause','second pause failed')
        S.smoke_stage=5;app.inject_click(vec2(680,562));return
    elseif S.smoke_stage==5 then
        assert(not S.modal and S.g.cleared==0 and S.g.wallet.food==40,'restart did not reset the district')
        S.smoke_stage=6
    end
    local e=sim.suggest(S.g)
    if e then app.inject_click(S.cam:to_screen(vec2(e.x,e.y))) end
end
local function frame(dt)
    if S.smoke then dt=1/30 end
    if input.get().back then
        if story.active() then story.next()
        elseif S.modal=='pause' then S.modal=nil;S.g.paused=false
        elseif S.screen=='play' and not S.modal then S.modal='pause';S.g.paused=true
        elseif S.modal=='help' then S.modal=nil end
    end
    if S.g and S.screen=='play' then
        if not S.modal and not story.active() then
            for _=1,(S.smoke and 12 or 1) do sim.update(S.g,dt) end
        end
        if S.g.won and not S.banked then
            S.banked=true;S.completed=S.completed|(1<<(S.chapter-1));S.unlocked=math.max(S.unlocked,math.min(S.chapter+1,#levels))
            if S.best[S.chapter]==0 or S.g.time<S.best[S.chapter] then S.best[S.chapter]=math.floor(S.g.time) end
            persist();S.modal='win';sfx.tone(880,.4)
        end
        for _,ev in ipairs(S.g.events) do
            local p=S.cam:to_screen(vec2(ev.x,ev.y))
            if ev.kind=='income' then fx.text(p,lettering(18,'green'),'+ supplies')
            else fx.burst(p,12,C.gold,70,3);sfx.tone(ev.kind=='rescue' and 660 or 440,.12) end
        end
        S.g.events={}
        ui.set_enabled(not S.modal and not story.active())
        if not S.modal and not story.active() then
            local in_=input.world();S.cam=S.cam:input(in_)
            if in_.tap then
                local e=pick(in_.pos);S.selected=e
                if e then sim.click(S.g,e) end
            end
        end
        world();hud()
    else ui.set_enabled(not S.modal);menu() end
    modal();fx.update(dt);fx.draw();story.frame(dt)
    if S.smoke then smoke() end
end
local function init()
    S.font=font.load('fonts/LilitaOne-Regular.ttf')
    ui.set_theme(ui_theme{text=lettering(24),small=lettering(16),title=lettering(36,'gold'),button=lettering(25),accent_text=lettering(25),
        panel=color(25,57,62,246),panel2=color(18,43,48,248),border=color(226,201,150,135),
        button_bg=color.hex(0x346068),button_bg2=color.hex(0x23474E),button_hot=color.hex(0x477A7E),button_border=color(235,211,164,130),
        accent=C.gold,accent2=color.hex(0xD6A050),active=C.gold,dim=color(9,23,28,196),toast_bg=C.cream,toast_text=C.ink,radius=13})
    -- briefings come from the rescue dispatcher: a caption with a name tag, no portrait
    story.setup({{id='dispatch',name='Rescue dispatch',color=color.hex(0xB4532A)}},
        story_style{text=style{font=S.font,size=27,fill=C.ink},name=lettering(21),bubble=C.cream,edge=C.teal,dim=color(9,23,28,150),skip='START RESCUE'})
    S.testing=app.arg('fresh')~=nil or app.arg('shot')~=nil or app.arg('smoke')~=nil
    S.smoke=app.arg('smoke')~=nil
    if not S.testing then save.read('campaign',serialize) end
    sfx.enable(S.sound and app.arg('mute')==nil)
    for _,a in pairs(art) do if not S.textures[a.image] then S.textures[a.image]=texture.load(a.image) end end
    local level=tonumber(app.arg('level'))
    if level then start(num.clampi(math.floor(level),1,#levels),app.arg('dialog')==nil) end
    local preview=app.arg('preview')
    if preview and S.g then
        assert(preview=='repaired' or preview=='complete','unknown preview stage')
        local steps=0
        while not S.g.won and steps<18000 do
            if steps%10==0 then local e=sim.suggest(S.g);if e then sim.click(S.g,e) end end
            sim.update(S.g,.1);S.g.events={};steps=steps+1
            if preview=='repaired' then
                local ready=true
                for _,e in ipairs(S.g.objects) do if e.def.kind=='station' and not e.done then ready=false end end
                if ready then break end
            end
        end
        assert(steps<18000,'preview playthrough stalled')
    end
    if app.arg('pause') and S.g then S.modal='pause';S.g.paused=true end
end
return {title='Volcano - After the Eruption',id='volcano',design=size2(1368,1026),fixed=true,landscape=true,clear=C.ink,init=init,frame=frame}
