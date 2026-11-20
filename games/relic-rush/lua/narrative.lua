-- The cast, with its authored portraits. The engine (match3.game) delivers
-- the keyed scenes.
local R=require('state')
R.cast={
    {id='elena',name='Elena Voss',role='Archaeologist, expedition lead',portrait_path='story/characters/elena.png',color=color(44,108,84),mouth=vec2(.46,.51)},
    {id='mara',name='Mara Bell',role='Pilot of the Marigold',portrait_path='story/characters/mara.png',color=color(150,74,40),right=true,mouth=vec2(.60,.49)},
    {id='tomas',name='Tomas Reed',role='Harbour keeper',portrait_path='story/characters/tomas.png',color=color(92,112,58),right=true,mouth=vec2(.44,.52)},
    {id='adrian',name='Adrian Vale',role='Expedition financier',portrait_path='story/characters/adrian.png',color=color(104,48,92),right=true,mouth=vec2(.54,.52)},
    -- Heard, never seen: the radio or a loudhailer. No bust, so the engine captions his lines.
    {id='kessler',name='Kessler',role='Meridian Society',color=color(60,62,70)},
    {id='ines',name='Ines Reed',role='Keeper of the tide warning',color=color(51,93,84)},
    {id='keeper',name='Ancient keeper',role='Keeper of the first harbor',portrait_path='story/characters/keeper.png',color=color(94,72,46),mouth=vec2(.54,.51)},
    -- The citizens, one per building (docs/CAMPAIGN_DESIGN.md#citizens). No bust yet: the engine
    -- shows each with a name plate; Marisol also speaks in the main story.
    {id='lupe',name='Lupe',role="Water-carrier, Spring well",color=color(46,110,140)},
    {id='bastian',name='Old Bastian',role="Trapper, Trapper's cabin",color=color(110,78,48)},
    {id='joaquin',name='Joaquín',role="Carpenter, Carpenter's workshop",color=color(142,92,44)},
    {id='dita',name='Dita',role="Blaster, Expedition camp",color=color(172,64,44)},
    {id='marisol',name='Auntie Marisol',role="Trader, Jungle market",color=color(150,52,98)},
    {id='basile',name='Basile',role="Stonecutter, Stone trading post",color=color(96,98,104)},
    {id='hana',name='Hana',role="Miller, Water mill",color=color(70,120,78)},
    {id='ferro',name='Ferro',role="Clockmender, Tide clock tower",color=color(78,84,140)},
    {id='nilo',name='Nilo',role="Fisher, Harbour plaza",color=color(34,118,126)},
    {id='zaza',name='Zaza',role="Drummer, Stone amphitheatre",color=color(176,98,34)},
    {id='ruth',name='Ruth',role="Cartographer, Cartographer's house",color=color(118,70,124)},
    {id='ulla',name='Captain Ulla',role="Lighthouse keeper",color=color(52,86,134)},
    {id='pike',name='Pike',role="Shipwright, Beached schooner",color=color(122,60,50)},
    {id='amani',name='Dr Amani',role="Astronomer, Star observatory",color=color(58,60,120)},
    {id='sato',name='Mr Sato',role="Curator, Relic museum",color=color(88,100,58)},
    {id='ixchel',name='Ixchel',role="Storyteller, Temple of the Sun",color=color(160,84,76)},
}

return R
