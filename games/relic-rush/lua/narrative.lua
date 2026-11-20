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
    -- Marisol also speaks in the main story; no bust yet, so the engine shows a name plate.
    {id='marisol',name='Auntie Marisol',role="Trader, Jungle market",color=color(150,52,98)},
}

return R
