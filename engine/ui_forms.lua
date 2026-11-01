-- Engine-owned declarative forms. Compiled into the runtime by make gen.
-- Templates own layout/bindings; skins own paint; games handle command IDs.
local Form, Stack = {}, {}
Form.__index, Stack.__index = Form, Stack
local kinds = {column=true, row=true, list=true, overlay=true, label=true, image=true, button=true, toggle=true, checkbox=true, progress=true, spacer=true, custom=true}
local function fail(message) error('ui.form: ' .. message, 3) end
local function padding(p)
    if type(p) == 'number' then return p,p,p,p end
    p = p or {}; return p.left or p[1] or 0, p.top or p[2] or 0, p.right or p[3] or 0, p.bottom or p[4] or 0
end
local function path_get(model, path)
    local value = model
    for key in path:gmatch('[^.]+') do
        key=tonumber(key) or key
        if type(value) ~= 'table' then return nil end
        value = value[key]
    end
    return value
end
local function path_parent(model, path)
    local parent, last = model, nil
    for key in path:gmatch('[^.]+') do
        key=tonumber(key) or key
        if last then parent = parent[last] end
        if type(parent) ~= 'table' then return nil end
        last = key
    end
    return parent, last
end
local function valid(value, binding)
    local t = binding.type or 'string'
    if t == 'integer' then
        if type(value) ~= 'number' or value % 1 ~= 0 then return false end
    elseif t == 'number' then
        if type(value) ~= 'number' or value ~= value or math.abs(value) == math.huge then return false end
    elseif t == 'texture' then
        if type(value) ~= 'table' or not value.tex then return false end
    elseif type(value) ~= t then return false end
    if type(value) == 'number' and ((binding.min and value < binding.min) or (binding.max and value > binding.max)) then return false end
    return true
end
local function copy_node(source, ids, depth, prefix, source_id, item_key)
    if depth > 32 then fail('template nesting exceeds 32') end
    if type(source) ~= 'table' or not kinds[source.kind] then fail('unknown node kind ' .. tostring(source and source.kind)) end
    local n = {}
    for k,v in pairs(source) do if k ~= 'children' then n[k] = v end end
    n._depth=depth
    if prefix then
        n.local_id, n.source_id, n.item_key = n.id, source_id, item_key
        for _,key in ipairs({'id','visible_field','enabled_field'}) do
            if n[key] then n[key]=prefix..n[key] end
        end
    end
    if n.id then
        if ids[n.id] then fail('duplicate control ID ' .. n.id) end
        ids[n.id] = n
    end
    if (n.kind == 'button' or n.kind == 'toggle' or n.kind == 'checkbox') and type(n.id) ~= 'string' then fail('interactive controls require an ID') end
    if n.kind=='list' and (type(n.id)~='string' or type(n.item)~='function' or #(source.children or {})>0) then fail('list requires an ID and item builder; children come from its data source') end
    if n.kind=='list' and n.direction and n.direction~='row' and n.direction~='column' then fail('invalid list direction') end
    if n.text_align and not ({start=true,center=true,['end']=true})[n.text_align] then fail('invalid text_align') end
    for _, key in ipairs({'width','height','grow','gap','min_width','min_height'}) do
        if n[key] and (type(n[key]) ~= 'number' or n[key] < 0 or n[key] ~= n[key] or n[key] == math.huge) then fail('invalid ' .. key) end
    end
    if n.scroll and (n.kind~='list' or n.direction=='row') then fail('scroll requires a vertical list') end
    n.children = {}
    for _, child in ipairs(source.children or {}) do n.children[#n.children+1] = copy_node(child, ids, depth+1, prefix, source_id, item_key) end
    return n
end
function ui.form(template)
    assert(type(template) == 'table', 'ui.form expects a template')
    local self = setmetatable({nodes={}, values={}, boxes={}, bindings={}, focus=nil}, Form)
    self.root = copy_node(template.root or template, self.nodes, 1)
    for id,node in pairs(self.nodes) do if node.value~=nil then self.values[id]=node.value end end
    local bound = {}
    for _, b in ipairs(template.bindings or {}) do
        if not self.nodes[b.id] or type(b.field) ~= 'string' or not b.field:match('^[%w_]+[.%w_]*$') or b.field:match('%.%.') or b.field:match('%.$') then fail('invalid binding') end
        if bound[b.id] then fail('duplicate binding for ' .. b.id) end
        if not ({string=true,boolean=true,integer=true,number=true,texture=true})[b.type or 'string'] then fail('unknown binding type') end
        local entry = {}; for k,v in pairs(b) do entry[k]=v end
        self.bindings[#self.bindings+1], bound[b.id] = entry, true
    end
    return self
end
function Form:set(id, value)
    if not self.nodes[id] then fail('unknown control ID ' .. tostring(id)) end
    self.values[id] = value; return self
end
function Form:get(id) return self.values[id] end
-- Data-backed stack. Row builders return ordinary resources, never positions.
-- Build/validate the entire replacement before touching the live list.
function Form:set_items(id, items)
    local list=self.nodes[id]
    if not list or list.kind~='list' then fail('unknown list ID '..tostring(id)) end
    local removed={}
    local function collect(n)
        if n.id then removed[n.id]=true end
        for _,child in ipairs(n.children) do collect(child) end
    end
    for _,child in ipairs(list.children) do collect(child) end
    local nodes={};for name,node in pairs(self.nodes) do if not removed[name] then nodes[name]=node end end
    local ok,children=pcall(function()
        if type(items)~='table' then fail('items must be a dense array') end
        local count,seen=#items,0
        for index in pairs(items) do
            if type(index)~='number' or index%1~=0 or index<1 or index>count then fail('items must be a dense array') end
            seen=seen+1
        end
        if seen~=count then fail('items must be a dense array') end
        local rows,keys={},{}
        for index,record in ipairs(items) do
            local key=type(record)=='table' and record[list.key or 'id']
            if (type(key)~='string' or key=='') and (type(key)~='number' or key%1~=0) then fail('items require a stable string/integer key') end
            local token=type(key)..':'..tostring(key)
            if keys[token] then fail('duplicate item key '..tostring(key)) end
            keys[token]=true
            local prefix=id..'['..#token..':'..token..']/'
            rows[#rows+1]=copy_node(list.item(record,index),nodes,list._depth+1,prefix,id,key)
        end
        return rows
    end)
    if not ok then return false,children end
    for name in pairs(removed) do self.values[name]=nil end
    for name,node in pairs(nodes) do
        if not self.nodes[name] or removed[name] then self.values[name]=node.value end
    end
    list.children,self.nodes,self.boxes=children,nodes,{}
    if self.focus and not nodes[self.focus] then self.focus=nil end
    return true
end
function Form:push(model)
    local values = {}
    for _, b in ipairs(self.bindings) do
        local value = path_get(model, b.field)
        if not valid(value, b) then return false, 'Invalid ' .. b.field end
        values[b.id] = value
    end
    for k,v in pairs(values) do self.values[k] = v end
    return true
end
function Form:pull(model, validator)
    local writes, staged = {}, {}
    for _, b in ipairs(self.bindings) do
        if not b.readonly then
            local value = self.values[b.id]
            if not valid(value, b) then return false, 'Invalid ' .. b.field end
            local parent, key = path_parent(model, b.field)
            if not parent then return false, 'Missing ' .. b.field end
            writes[#writes+1] = {parent, key, value}; staged[b.field] = value
        end
    end
    if validator then local ok, message = validator(staged); if not ok then return false, message end end
    for _, w in ipairs(writes) do w[1][w[2]] = w[3] end
    return true
end
local function visible(n, values)
    if n.visible == false then return false end
    return not n.visible_field or not not values[n.visible_field]
end
local function caption(n, values)
    local v = values[n.id]
    if n.kind == 'toggle' then return (v and n.on_text or n.off_text) or n.text or n.local_id or n.id end
    if n.kind == 'checkbox' then return n.text or n.local_id or n.id end
    if v == nil then return n.text or '' end
    return n.format and n.format:format(v) or tostring(v)
end
local function style_for(n, skin)
    return n.style or (skin.style and skin.style(n)) or (skin.styles and skin.styles[n.role or n.kind]) or (skin.theme or ui.theme())[n.role == 'title' and 'title' or (n.kind == 'button' or n.kind == 'toggle') and (n.accent and 'accent_text' or 'button') or 'text']
end
local function horizontal(n) return n.kind=='row' or (n.kind=='list' and n.direction=='row') end
local function measure(n, width, skin, values)
    if not visible(n, values) then return 0,0 end
    width=n.width or width
    local l,t,r,b = padding(n.padding)
    local w,h = 0,0
    if n.kind == 'row' or n.kind == 'column' or n.kind == 'list' or n.kind == 'overlay' then
        local count = 0
        local fixed,weight=0,0
        if horizontal(n) then
            for _,child in ipairs(n.children) do if visible(child,values) then
                count=count+1
                if (child.grow or 0)>0 then weight=weight+child.grow
                else local cw=measure(child,math.max(0,width-l-r),skin,values);fixed=fixed+cw end
            end end
        end
        local remaining=math.max(0,width-l-r-fixed-math.max(0,count-1)*(n.gap or 0))
        count=0
        for _, child in ipairs(n.children) do
            if visible(child, values) then
                local child_width=horizontal(n) and (child.grow or 0)>0 and remaining*child.grow/weight or math.max(0,width-l-r)
                local cw,ch = measure(child, child_width, skin, values)
                if horizontal(n) then w,h = w+(child.grow and child.grow>0 and child_width or cw),math.max(h,ch)
                elseif n.kind == 'column' or n.kind=='list' then w,h = math.max(w,cw),h+ch
                else w,h = math.max(w,cw),math.max(h,ch) end
                count=count+1
            end
        end
        local gaps = math.max(0,count-1)*(n.gap or 0)
        if horizontal(n) then w=w+gaps elseif n.kind == 'column' or n.kind=='list' then h=h+gaps end
    elseif n.kind == 'label' then
        local s = style_for(n,skin)
        if n.wrap then
            local measured = text.box_size(s, math.max(1,(n.width or width)-l-r), caption(n,values)); w,h=measured.w,measured.h
        else local measured = text.measure(s,caption(n,values)); w,h=measured.w,measured.h end
    elseif n.kind == 'image' then
        local image = values[n.id] or n.image; w,h=image and image.w or 0,image and image.h or 0
    elseif n.kind == 'button' or n.kind == 'toggle' then
        local s=style_for(n,skin); local measured=text.measure(s,caption(n,values)); w,h=measured.w+24,math.max(44,measured.h+16)
    elseif n.kind == 'checkbox' then
        if skin.measure_checkbox then w,h=skin.measure_checkbox(n,caption(n,values))
        else local measured=text.measure(style_for(n,skin),caption(n,values)); w,h=measured.w+38,math.max(44,measured.h) end
    elseif n.kind == 'progress' then w,h=100,20 end
    return math.max(n.min_width or 0,n.width or w+l+r),math.max(n.min_height or 0,n.height or h+t+b)
end
local function arrange(n, box, skin, form)
    n.box=box
    if n.id then form.boxes[n.id]=box end
    if #n.children == 0 then return end
    local l,t,r,b=padding(n.padding)
    local inner=rect(box.x+l,box.y+t,math.max(0,box.w-l-r),math.max(0,box.h-t-b))
    local across=horizontal(n)
    local total,weight,count=0,0,0
    for _,child in ipairs(n.children) do
        if visible(child,form.values) then
            local cw,ch=measure(child,inner.w,skin,form.values)
            child.measured={cw,ch}; count=count+1
            if child.grow and child.grow>0 then weight=weight+child.grow else total=total+(across and cw or ch) end
        end
    end
    local gap=n.gap or 0
    local available=across and inner.w or inner.h
    local remaining=math.max(0,available-total-gap*math.max(0,count-1))
    if n.scroll then
        n.scroll_state=n.scroll_state or {offset=0,velocity=0}
        n.scroll_max=math.max(0,total+gap*math.max(0,count-1)-inner.h)
        n.scroll_state.offset=math.max(0,math.min(n.scroll_max,n.scroll_state.offset))
    end
    local cursor=(across and inner.x or inner.y)-(n.scroll and n.scroll_state.offset or 0)
    for _,child in ipairs(n.children) do
        if visible(child,form.values) then
            local cw,ch=child.measured[1],child.measured[2]
            if across and (child.grow or 0)>0 then
                cw,ch=measure(child,remaining*child.grow/weight,skin,form.values)
            end
            if n.kind=='overlay' then arrange(child,inner,skin,form)
            else
                local main=across and cw or ch
                if child.grow and child.grow>0 then main=remaining*child.grow/weight end
                if not n.scroll then main=math.max(0,math.min(main, (across and inner.x+inner.w or inner.y+inner.h)-cursor)) end
                local cross=(n.align or 'stretch')=='stretch' and (across and inner.h or inner.w) or math.min(across and ch or cw,across and inner.h or inner.w)
                local explicit=across and child.height or child.width
                if explicit then cross=math.min(cross,explicit) end
                local free=(across and inner.h or inner.w)-cross
                local offset=n.align=='center' and free/2 or n.align=='end' and free or 0
                local cb=across and rect(cursor,inner.y+offset,main,cross) or rect(inner.x+offset,cursor,cross,main)
                arrange(child,cb,skin,form); cursor=cursor+main+gap
            end
        end
    end
end
function Form:measure(width, skin) return measure(self.root,width,skin or {},self.values) end
function Form:layout(box,skin)
    self.boxes={};arrange(self.root,box,skin or {},self);return self.boxes
end
local function paint(n,skin,form,options,event)
    if not visible(n,form.values) then return event end
    local box=n.box; local theme=skin.theme or ui.theme()
    if options.clip then local visible_box=box:intersect(options.clip);if visible_box.w<=0 or visible_box.h<=0 then return event end end
    if n.scroll then
        local opts={};for k,v in pairs(options) do opts[k]=v end
        opts.clip=options.clip and box:intersect(options.clip) or box
        opts.suppress_hit=options.suppress_hit or n.scroll_state.moved
        options=opts
        gfx.clip(opts.clip);ui.block(opts.clip)
    end
    if n.panel then
        if skin.panel then skin.panel(box,n) else ui.panel(box) end
    end
    if n.kind=='label' then
        local align=vec2(n.text_align=='start' and 0 or n.text_align=='end' and 1 or .5,.5)
        if skin.label then skin.label(box,caption(n,form.values),n,style_for(n,skin))
        elseif n.wrap then text.box(style_for(n,skin),box,align,caption(n,form.values))
        else text.inside(style_for(n,skin),box,align,caption(n,form.values)) end
    elseif n.kind=='image' then
        local im=form.values[n.id] or n.image
        if im and im.tex then
            if skin.image then skin.image(box,im,n)
            else gfx.image(im,n.cover and box or box:fit(texture.size(im)),color.WHITE) end
        end
    elseif n.kind=='progress' then
        local fraction=tonumber(form.values[n.id]) or n.value or 0
        if skin.progress then skin.progress(box,fraction,n) else ui.progress(box,fraction,n.text) end
    elseif n.kind=='custom' then
        if n.paint then n.paint(box,form.values[n.id],options) end
    elseif n.kind=='button' or n.kind=='toggle' or n.kind=='checkbox' then
        local enabled=options.interactive~=false and n.enabled~=false and (not n.enabled_field or form.values[n.enabled_field])
        local selected=(n.kind=='toggle' or n.kind=='checkbox') and not not form.values[n.id]
        local flags=(enabled and 0 or ui.DISABLED)|(n.accent and ui.ACCENT or 0)|(selected and ui.ACTIVE or 0)|(n.flat and ui.FLAT or 0)
        local hitbox=options.hit_offset and box:offset(options.hit_offset) or box
        if options.clip then hitbox=hitbox:intersect(options.hit_offset and options.clip:offset(options.hit_offset) or options.clip) end
        local st=ui.hit(hitbox,flags)
        if options.suppress_hit then st.clicked,st.held,st.hot=false,false,false end
        local checkbox=n.kind=='checkbox'
        if not checkbox and not skin.button and not skin.button_states then ui.button_paint(box,flags,st) end
        st.disabled,st.selected,st.focused=not enabled,selected,form.focus==n.id
        if checkbox then
            if skin.checkbox then skin.checkbox(box,caption(n,form.values),n,st)
            else   -- the native look: a themed box, a tick when checked, then the caption
                local side=rect(box.x,box.y+(box.h-28)/2,28,28)
                gfx.round_rect(side,6,enabled and theme.button_bg or color.alpha(theme.button_bg,.45))
                gfx.round_rect_line(side,6,1.5,st.hot and theme.active or theme.button_border)
                if selected then gfx.polyline({side:point(vec2(.2,.52)),side:point(vec2(.42,.74)),side:point(vec2(.8,.28))},3,theme.active) end
                text.inside(style_for(n,skin),rect(box.x+38,box.y,math.max(0,box.w-38),box.h),vec2(0,.5),caption(n,form.values))
            end
        elseif skin.button then skin.button(box,st,n)
        elseif skin.button_states then
            local state=not enabled and 'disabled' or st.held and 'pressed' or selected and 'selected' or st.hot and 'hover' or 'normal'
            local im=skin.button_states[state] or skin.button_states.normal
            if im then gfx.image(im,box,color.WHITE) end
        end
        if not checkbox then   -- a checkbox paints its own caption beside the box
            if skin.button_text then skin.button_text(box,caption(n,form.values),n,st)
            else text.inside(style_for(n,skin),box:inflate(-8),vec2(.5,.5),caption(n,form.values)) end
        end
        if st.focused and form.focus_visible and options.interactive~=false then
            if skin.focus then skin.focus(box,n) else gfx.round_rect_line(box:inflate(3),theme.radius or 8,2,theme.active) end
        end
        local keyboard=options.interactive~=false and form.focus==n.id and (options.input.key==input.KEY_RETURN or options.input.key==input.KEY_SPACE)
        if enabled and (st.clicked or keyboard) and not event then
            form.focus=n.id
            if n.kind=='toggle' or checkbox then form.values[n.id]=not selected end
            event={id=n.action or n.local_id or n.id,kind=(n.kind=='toggle' or checkbox) and 'change' or 'click',value=form.values[n.id],source=n.source_id,key=n.item_key}
        end
    end
    for _,child in ipairs(n.children) do event=paint(child,skin,form,options,event) end
    if n.scroll then
        local length=n.scroll_max or 0
        if length>0 then
            local h=box.h*box.h/(box.h+length)
            gfx.round_rect(rect(box:max().x-4,box.y+(box.h-h)*n.scroll_state.offset/length,3,h),1.5,color(150,114,63,180))
        end
        gfx.unclip()
    end
    return event
end
function Form:draw(box,skin,options)
    skin,options=skin or {},options or {}; options.input=options.input or input.get()
    if not skin.theme then skin=setmetatable({theme=ui.theme()},{__index=skin}) end
    self:layout(box,skin)
    -- Scrolling belongs to the form, before any child hit test. It uses the
    -- engine dt (CAAnimation clock on iOS), not per-control wall clocks.
    local function scroll(n)
        if not visible(n,self.values) then return end
        if n.scroll and options.interactive~=false then
            local st,inp=n.scroll_state,options.input
            local inside=inp.pos and n.box:contains(inp.pos)
            if inp.pressed then
                st.down=inside;st.moved=inside and math.abs(st.velocity)>20 or false
                st.last=inp.pos and inp.pos.y or 0;st.last_time=app.time();st.velocity=0
            end
            local dt=options.dt or app.dt()
            if st.down and inp.down and inp.pos then
                local dy=st.last-inp.pos.y
                if inp.dragging or math.abs(dy)>8 then st.moved=true end
                if st.moved and dy~=0 then
                    st.offset=math.max(0,math.min(n.scroll_max,st.offset+dy))
                    st.velocity=math.max(-1800,math.min(1800,dy/math.max(dt,1/120)))
                    st.last,st.last_time=inp.pos.y,app.time()
                end
            end
            if inp.released or inp.cancelled or inp.multi_touch or (st.down and not inp.down) then
                st.down=false
                if inp.cancelled or inp.multi_touch or app.time()-(st.last_time or 0)>.1 or not st.moved then st.velocity=0 end
            end
            if not st.down then
                if options.reduced_motion or tween.instant() then st.velocity=0 end
                local decay=math.exp(-7*dt)
                local next_offset=st.offset+st.velocity*(1-decay)/7
                st.offset=math.max(0,math.min(n.scroll_max,next_offset));st.velocity=st.velocity*decay
                if st.offset~=next_offset or math.abs(st.velocity)<2 then st.velocity=0 end
            end
            if inside and inp.wheel and inp.wheel~=0 then st.offset=math.max(0,math.min(n.scroll_max,st.offset-inp.wheel*45));st.velocity=0 end
        end
        for _,child in ipairs(n.children) do scroll(child) end
    end
    scroll(self.root);self:layout(box,skin)
    local focusable={}
    local function collect(n)
        if not visible(n,self.values) then return end
        if (n.kind=='button' or n.kind=='toggle' or n.kind=='checkbox') and n.enabled~=false and (not n.enabled_field or self.values[n.enabled_field]) then focusable[#focusable+1]=n.id end
        for _,child in ipairs(n.children) do collect(child) end
    end
    collect(self.root)
    if options.input.pressed then self.focus_visible=false end
    if options.interactive~=false and options.input.key==input.KEY_TAB then
        self.focus_visible=true
        local current=0; for i,id in ipairs(focusable) do if id==self.focus then current=i end end
        self.focus=focusable[current%math.max(1,#focusable)+1]
    end
    local focused=self.focus and self.nodes[self.focus]
    local owner=focused and focused.source_id and self.nodes[focused.source_id]
    if self.focus_visible and owner and owner.scroll then
        local delta=focused.box.y<owner.box.y and focused.box.y-owner.box.y or math.max(0,focused.box:max().y-owner.box:max().y)
        owner.scroll_state.offset=math.max(0,math.min(owner.scroll_max,owner.scroll_state.offset+delta));self:layout(box,skin)
    end
    local old=ui.theme(); if skin.theme then ui.set_theme(skin.theme) end
    local ok,event=pcall(paint,self.root,skin,self,options,nil)
    if skin.theme then ui.set_theme(old) end
    if not ok then error(event,0) end
    return event
end
function ui.modals(skin)
    return setmetatable({layers={},skin=skin or {}},Stack)
end
-- Shared cancellation for both form stacks and custom painted dialogs. A tap
-- must begin AND end on the backdrop; drags and inherited opening releases
-- cannot dismiss a dialog or activate the world underneath it.
function ui.modal_dismiss(bounds,options)
    options=options or {}
    ui.block(app.bleed())
    if options.fresh or options.interactive==false then return false end
    local inp=options.input or input.get()
    if inp.back then return true end
    return options.close_on_background~=false and inp.captured and inp.released and inp.tap
        and not inp.dragging and not inp.multi_touch and inp.pos and inp.press_pos
        and not bounds:contains(inp.pos) and not bounds:contains(inp.press_pos) or false
end
function Stack:active() return #self.layers>0 end
function Stack:begin()
    ui.set_enabled(not self:active())
    if self:active() then ui.block(app.bleed()) end
    return not self:active()
end
function Stack:open(id,form,model,options)
    for _,layer in ipairs(self.layers) do if layer.id==id then fail('modal already open: '..id) end end
    local ok,message=form:push(model or {});if not ok then return false,message end
    local layer={id=id,form=form,model=model or {},options=options or {},fade=0,fresh=true}
    self.layers[#self.layers+1]=layer
    tween.to(layer,.2,{fade=1}):ease('linear')   -- the backdrop fades in on the engine's tween module
    ui.block(app.bleed());return true
end
function Stack:close(id)
    local top=self.layers[#self.layers]
    if not top or (id and id~=top.id) then return false end
    self.layers[#self.layers]=nil;return true
end
function Stack:draw(dt,options)
    options=options or {};local event;local top_fresh=false;local top_bounds
    ui.set_enabled(true)
    for i,layer in ipairs(self.layers) do
        local config=layer.options;local fade=options.reduced_motion and 1 or layer.fade
        local theme=self.skin.theme or ui.theme()
        local backdrop=config.snap_backdrop and 1 or fade
        ui.modal_layer((config.blur or theme.backdrop_blur or 0)*backdrop,color.alpha(config.dim or theme.dim,backdrop))
        local bounds=config.bounds
        if not bounds then
            local screen=app.screen();local width=math.min(config.width or 400,screen.w-32)
            local _,height=layer.form:measure(width,self.skin)
            bounds=rect.centered(screen:center(),size2(width,math.min(config.height or height,screen.h-32)))
        end
        -- The release/key that opened a modal belongs to the previous screen.
        -- In particular it must not activate a new button underneath that tap.
        if i==#self.layers then top_fresh,top_bounds=layer.fresh,bounds end
        local result=layer.form:draw(bounds,self.skin,{interactive=i==#self.layers and not layer.fresh,input=options.input or input.get(),dt=dt,reduced_motion=options.reduced_motion})
        layer.fresh=false
        if result then event={modal=layer.id,id=result.id,kind=result.kind,value=result.value,source=result.source,key=result.key} end
    end
    local top=self.layers[#self.layers]
    if top and not event and ui.modal_dismiss(top_bounds,{fresh=top_fresh,input=options.input,
            close_on_background=top.options.close_on_background}) then
        event={modal=top.id,id=top.options.cancel or 'cancel',kind='cancel'}
    end
    return event
end
