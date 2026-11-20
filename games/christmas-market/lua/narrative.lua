-- The cast. The engine (match3.game) delivers the keyed scenes. Portrait
-- sources and crops are recorded in docs/asset-catalogue.md#story-cast.
local R=require('state')
R.cast={
    {id='noelle',name='Noelle',role='Christmas market keeper',portrait_path='story/characters/noelle.png',color=color(136,42,43),mouth=vec2(.51,.42)},
    {id='theo',name='Theo Marsh',role='Tree seller',portrait_path='story/characters/theo.png',color=color(58,96,62),right=true,mouth=vec2(.62,.52)},
    {id='agnes',name='Agnes Holt',role='Baker',portrait_path='story/characters/agnes.png',color=color(150,92,48),right=true,mouth=vec2(.51,.45)},
    {id='henrik',name='Henrik Strand',role='Toymaker',portrait_path='story/characters/henrik.png',color=color(96,70,52),right=true,mouth=vec2(.53,.52)},
    {id='pip',name='Pip Larkin',role='Post runner',portrait_path='story/characters/pip.png',color=color(46,86,128),right=true,mouth=vec2(.65,.50)},
    {id='wren',name='Mr Wren',role='The man with the broom',portrait_path='story/characters/wren.png',color=color(92,92,104),right=true,mouth=vec2(.53,.46)},
    -- Mary and Rosa speak in the main story; the rest are the citizens, one per stall
    -- (docs/CAMPAIGN_DESIGN.md#citizens). No bust yet: the engine shows each with a name plate.
    {id='mary',name='Mary Larkin',role="Pip's mum",color=color(144,66,84)},
    {id='rosa',name='Rosa',role="Noelle's gran",color=color(120,48,60)},
    {id='clem',name='Clem',role="Lamplighter, Welcome arch",color=color(176,126,40)},
    {id='ned',name='Ned',role="Farrier, Reindeer stable",color=color(104,72,50)},
    {id='ivar',name='Big Ivar',role="Woodcutter, Lumber workshop",color=color(86,100,52)},
    {id='dot',name='Dot',role="Firework maker, Firework stall",color=color(170,60,52)},
    {id='hettie',name='Hettie',role="Icer, Gingerbread bakery",color=color(176,100,120)},
    {id='mags',name='Old Mags',role="Stonemason, Snowy chapel",color=color(96,100,108)},
    {id='alder',name='Mrs Alder',role="Hot cocoa kiosk",color=color(128,66,48)},
    {id='olaf',name='Olaf',role="Ice cutter, Ice house",color=color(52,110,150)},
    {id='finch',name='Mr Finch',role="Fisherman, Lakeside smokehouse",color=color(52,92,104)},
    {id='lotte',name='Lotte',role="Toymaker's apprentice",color=color(190,86,52)},
    {id='lucia',name='Lucia',role="Candle girl, Candlelight shop",color=color(192,150,48)},
    {id='penny',name='Mr Penny',role="Postmaster, North Pole post office",color=color(150,44,52)},
    {id='gianna',name='Gianna',role="Glassblower, Glassblower's stall",color=color(40,120,128)},
    {id='sid',name='Sid',role="Organ-grinder, Reindeer carousel",color=color(112,72,120)},
    {id='rolf',name='Rolf',role="Woodcarver, Woodcarvers' hall",color=color(122,86,44)},
    {id='bellamy',name='Mr Bellamy',role="Fenwick choirmaster, Christmas tree",color=color(46,92,66)},
}

return R
