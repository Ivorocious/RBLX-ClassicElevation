from pathlib import Path
p=Path('assets/city_run/v3/render_gallery.py');s=p.read_text();s=s.replace("for theme in ('market','courtyard','construction','terminal'):","for theme in ('market','courtyard','construction','terminal','service_corner'):")
s=s.replace(" else:\n  for side in (-1,1):instance('V3_Terminal_Wing'", " elif theme=='service_corner':\n  instance('V3_CornerCafe',(-16,22,0));instance('V3_GableRoof_Wide',(-16,22,36));instance('V3_ServiceRear',(19,30,0));instance('V3_UnevenShopRow',(13,15,0));instance('V3_MarketStall',(-23,6,0));instance('V3_Crate',(-18,7,0));instance('V3_Planter',(0,9,0));instance('V3_Lamp',(-2,12,0))\n  cameraPos=(39,-48,11);target=(0,20,18)\n else:\n  for side in (-1,1):instance('V3_Terminal_Wing'")
p.write_text(s)
