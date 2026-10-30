-- Engine-owned declarative forms. Compiled into the runtime by make gen.
-- Templates own layout/bindings; skins own paint; games handle command IDs.
local Form, Stack = {}, {}
Form.__index, Stack.__index = Form, Stack
local kinds = {column=true, row=true, list=true, overlay=true, label=true, image=true, button=true, toggle=true, progress=true, spacer=true, custom=true}
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
    if (n.kind == 'button' or n.kind == 'toggle') and type(n.id) ~= 'string' then fail('interactive controls require an ID') end
    if n.kind=='list' and (type(n.id)~='string' or type(n.item)~='function' or #(source.children or {})>0) then fail('list requires an ID and item builder; children come from its data source') end
    if n.kind=='list' and n.direction and n.direction~='row' and n.direction~='column' then fail('invalid list direction') end
    if n.text_align and not ({start=true,center=true,['end']=true})[n.text_align] then fail('invalid text_align') end
    for _, key in ipairs({'width','height','grow','gap','min_width','min_height'}) do
        if n[key] and (type(n[key]) ~= 'number' or n[key] < 0 or n[key] ~= n[key] or n[key] == math.huge) then fail('invalid ' .. key) end
    end
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
    elseif n.kind == 'progress' then w,h=100,20 end
    return math.max(n.min_width or 0,n.width or w+l+r),math.max(n.min_height or 0,n.height or h+t+b)
end
local function arrange(n, box, skin, form)
    n.box=box
    if n.id then form.boxes[n.id]=box end
    if #n.children == 0 then return end
    local l,t,r,b=padding(n.padding)
    local inner=rect(box.x+l,box.y+t,math.max(0,box.w-l-r),math.max(0,box.h-t-b))
    local horizontal=horizontal(n)
    local total,weight,count=0,0,0
    for _,child in ipairs(n.children) do
        if visible(child,form.values) then
            local cw,ch=measure(child,inner.w,skin,form.values)
            child.measured={cw,ch}; count=count+1
            if child.grow and child.grow>0 then weight=weight+child.grow else total=total+(horizontal and cw or ch) end
        end
    end
    local gap=n.gap or 0
    local available=horizontal and inner.w or inner.h
    local remaining=math.max(0,available-total-gap*math.max(0,count-1))
    local cursor=horizontal and inner.x or inner.y
    for _,child in ipairs(n.children) do
        if visible(child,form.values) then
            local cw,ch=child.measured[1],child.measured[2]
            if horizontal and (child.grow or 0)>0 then
                cw,ch=measure(child,remaining*child.grow/weight,skin,form.values)
            end
            if n.kind=='overlay' then arrange(child,inner,skin,form)
            else
                local main=horizontal and cw or ch
                if child.grow and child.grow>0 then main=remaining*child.grow/weight end
                main=math.max(0,math.min(main, (horizontal and inner.x+inner.w or inner.y+inner.h)-cursor))
                local cross=(n.align or 'stretch')=='stretch' and (horizontal and inner.h or inner.w) or math.min(horizontal and ch or cw,horizontal and inner.h or inner.w)
                local explicit=horizontal and child.height or child.width
                if explicit then cross=math.min(cross,explicit) end
                local free=(horizontal and inner.h or inner.w)-cross
                local offset=n.align=='center' and free/2 or n.align=='end' and free or 0
                local cb=horizontal and rect(cursor,inner.y+offset,main,cross) or rect(inner.x+offset,cursor,cross,main)
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
        if im and im.tex then gfx.image(im, n.cover and box or box:fit(texture.size(im)),color.WHITE) end
    elseif n.kind=='progress' then
        ui.progress(box,tonumber(form.values[n.id]) or n.value or 0,n.text)
    elseif n.kind=='custom' then
        if n.paint then n.paint(box,form.values[n.id],options) end
    elseif n.kind=='button' or n.kind=='toggle' then
        local enabled=options.interactive~=false and n.enabled~=false and (not n.enabled_field or form.values[n.enabled_field])
        local selected=n.kind=='toggle' and not not form.values[n.id]
        local flags=(enabled and 0 or ui.DISABLED)|(n.accent and ui.ACCENT or 0)|(selected and ui.ACTIVE or 0)|(n.flat and ui.FLAT or 0)
        local hitbox=options.hit_offset and box:offset(options.hit_offset) or box
        local st=ui.hit(hitbox,flags)
        if not skin.button and not skin.button_states then ui.button_paint(box,flags,st) end
        st.disabled,st.selected,st.focused=not enabled,selected,form.focus==n.id
        if skin.button then skin.button(box,st,n)
        elseif skin.button_states then
            local state=not enabled and 'disabled' or st.held and 'pressed' or selected and 'selected' or st.hot and 'hover' or 'normal'
            local im=skin.button_states[state] or skin.button_states.normal
            if im then gfx.image(im,box,color.WHITE) end
        end
        if skin.button_text then skin.button_text(box,caption(n,form.values),n,st)
        else text.inside(style_for(n,skin),box:inflate(-8),vec2(.5,.5),caption(n,form.values)) end
        if st.focused and options.interactive~=false then
            if skin.focus then skin.focus(box,n) else gfx.round_rect_line(box:inflate(3),theme.radius or 8,2,theme.active) end
        end
        local keyboard=options.interactive~=false and form.focus==n.id and (options.input.key==input.KEY_RETURN or options.input.key==input.KEY_SPACE)
        if enabled and (st.clicked or keyboard) and not event then
            form.focus=n.id
            if n.kind=='toggle' then form.values[n.id]=not selected end
            event={id=n.action or n.local_id or n.id,kind=n.kind=='toggle' and 'change' or 'click',value=form.values[n.id],source=n.source_id,key=n.item_key}
        end
    end
    for _,child in ipairs(n.children) do event=paint(child,skin,form,options,event) end
    return event
end
function Form:draw(box,skin,options)
    skin,options=skin or {},options or {}; options.input=options.input or input.get()
    if not skin.theme then skin=setmetatable({theme=ui.theme()},{__index=skin}) end
    self:layout(box,skin)
    local focusable={}
    local function collect(n)
        if not visible(n,self.values) then return end
        if (n.kind=='button' or n.kind=='toggle') and n.enabled~=false and (not n.enabled_field or self.values[n.enabled_field]) then focusable[#focusable+1]=n.id end
        for _,child in ipairs(n.children) do collect(child) end
    end
    collect(self.root)
    if options.interactive~=false and options.input.key==input.KEY_TAB then
        local current=0; for i,id in ipairs(focusable) do if id==self.focus then current=i end end
        self.focus=focusable[current%math.max(1,#focusable)+1]
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
function Stack:active() return #self.layers>0 end
function Stack:begin()
    ui.set_enabled(not self:active())
    if self:active() then ui.block(app.bleed()) end
    return not self:active()
end
function Stack:open(id,form,model,options)
    for _,layer in ipairs(self.layers) do if layer.id==id then fail('modal already open: '..id) end end
    local ok,message=form:push(model or {});if not ok then return false,message end
    self.layers[#self.layers+1]={id=id,form=form,model=model or {},options=options or {},clock=0}
    ui.block(app.bleed());return true
end
function Stack:close(id)
    local top=self.layers[#self.layers]
    if not top or (id and id~=top.id) then return false end
    self.layers[#self.layers]=nil;return true
end
function Stack:draw(dt,options)
    options=options or {};local event
    ui.set_enabled(true)
    for i,layer in ipairs(self.layers) do
        layer.clock=layer.clock+dt
        local config=layer.options;local fade=options.reduced_motion and 1 or math.min(1,layer.clock/.2)
        local theme=self.skin.theme or ui.theme()
        ui.modal_layer((config.blur or theme.backdrop_blur or 0)*fade,color.alpha(config.dim or theme.dim,fade))
        local bounds=config.bounds
        if not bounds then
            local screen=app.screen();local width=math.min(config.width or 400,screen.w-32)
            local _,height=layer.form:measure(width,self.skin)
            bounds=rect.centered(screen:center(),size2(width,math.min(config.height or height,screen.h-32)))
        end
        local result=layer.form:draw(bounds,self.skin,{interactive=i==#self.layers,input=options.input or input.get()})
        if result then event={modal=layer.id,id=result.id,kind=result.kind,value=result.value} end
    end
    local top=self.layers[#self.layers]
    if top and (options.input or input.get()).back then event={modal=top.id,id=top.options.cancel or 'cancel',kind='cancel'} end
    return event
end
