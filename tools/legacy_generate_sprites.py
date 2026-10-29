from PIL import Image,ImageDraw
a=Image.new('RGB',(768,224),(255,0,255));d=ImageDraw.Draw(a)
# Eight deliberately drawn period objects, legible silhouettes, no emoji
for i in range(8):
 x=i*96;gold='#d7ac50';dark='#62452e';blue='#287c88'
 if i==0: # ankh
  d.ellipse((x+34,12,x+62,44),outline=gold,width=8);d.line((x+48,40,x+48,83),fill=gold,width=8);d.line((x+23,52,x+73,52),fill=gold,width=8)
 if i==1:
  d.ellipse((x+24,15,x+72,83),fill='#bf7143',outline=dark,width=3);d.rectangle((x+35,8,x+61,29),fill='#d99958');d.arc((x+9,26,x+43,62),70,290,fill=gold,width=6);d.line((x+28,52,x+68,52),fill=blue,width=8)
 if i==2:
  d.rounded_rectangle((x+13,29,x+82,67),8,fill='#ead5a4',outline=dark,width=3);d.ellipse((x+10,23,x+25,73),fill='#c6a774');d.ellipse((x+72,23,x+87,73),fill='#f7e4b4');d.line((x+34,44,x+65,44),fill=dark,width=2);d.line((x+34,53,x+62,53),fill=dark,width=2)
 if i==3:
  for j in range(5):d.ellipse((x+15+j*10,22+abs(j-2)*7,x+36+j*10,69),fill=['#76ad9d','#dba9a2','#ead0b3'][j%3],outline=blue,width=2)
  d.line((x+48,56,x+44,87),fill='#718554',width=5)
 if i==4:
  d.ellipse((x+27,25,x+70,74),fill=blue,outline=gold,width=5);d.line((x+48,29,x+48,69),fill=gold,width=2)
  for yy in [32,49,66]:d.line((x+19,yy,x+76,yy+9),fill=gold,width=3)
 if i==5:
  d.arc((x+16,15,x+81,80),0,180,fill=gold,width=9);d.ellipse((x+11,16,x+25,30),fill=blue);d.ellipse((x+73,16,x+87,30),fill=blue)
 if i==6:
  d.polygon([(x+18,69),(x+23,30),(x+48,14),(x+76,30),(x+80,69)],fill='#b8793f',outline=dark);d.rectangle((x+29,35,x+68,66),fill=blue);d.line((x+22,76,x+78,76),fill=gold,width=7)
 if i==7:
  d.ellipse((x+31,28,x+69,78),fill='#a77a49',outline=dark,width=3);d.polygon([(x+31,33),(x+34,10),(x+46,29),(x+61,10),(x+67,35)],fill='#a77a49');d.ellipse((x+39,40,x+43,45),fill='#ead4a1');d.ellipse((x+56,40,x+60,45),fill='#ead4a1');d.arc((x+52,55,x+87,86),0,260,fill=dark,width=6)
for i in range(5):
 x=i*128;y=96
 d.ellipse((x+5,y+87,x+124,y+120),fill='#999162')
 if i==3:
  d.ellipse((x+12,y+51,x+115,y+105),fill='#dcbd80',outline='#805d3f',width=3);d.ellipse((x+23,y+57,x+105,y+94),fill='#4d9c9e');d.rectangle((x+59,y+22,x+68,y+76),fill='#d5b984');d.ellipse((x+43,y+18,x+83,y+34),fill='#edce8e')
 else:
  d.polygon([(x+19,y+55),(x+63,y+32),(x+111,y+54),(x+111,y+98),(x+63,y+121),(x+19,y+97)],fill='#cda86c',outline='#725e42')
  d.polygon([(x+19,y+55),(x+63,y+32),(x+111,y+54),(x+64,y+78)],fill='#f1d79c')
  d.polygon([(x+64,y+78),(x+111,y+54),(x+111,y+98),(x+64,y+121)],fill='#b18c53')
  d.rectangle((x+37,y+73,x+52,y+102),fill='#356e70')
  if i in [1,4]:
   for xx in [29,53,77,99]:d.rectangle((x+xx,y+36,x+xx+9,y+88),fill='#eed8a6')
   d.polygon([(x+12,y+36),(x+64,y+6),(x+120,y+36)],fill=['#a95f41','#ba7048'][i==4])
  if i==2:
   d.rectangle((x+50,y+7,x+83,y+49),fill='#d7b67b');d.polygon([(x+45,y+9),(x+66,y),(x+89,y+9)],fill='#2d7b80')
a.save('atlas.bmp')
