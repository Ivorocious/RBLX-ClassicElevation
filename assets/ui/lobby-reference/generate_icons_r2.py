"""Bounded reference-art refinements, preserving first-version PNG and blend receipts."""
from pathlib import Path

folder=Path(__file__).resolve().parent
source=(folder/'generate_icons.py').read_text()
source=source.replace("('White','FFFFFF',0,.23,.15)","('White','FFFFFF',0,.55,.58)")
source=source.replace("tube('White handle',[(x,y-.08,z) for x,y,z in arc],m['White'],.053)","tube('White handle',[(x,y-.08,z) for x,y,z in arc],m['White'],.080)")
source=source.replace("[(x,-.41,.53),(x,-.41,.31)],m['White'],.053)","[(x,-.41,.53),(x,-.41,.31)],m['White'],.080)")
source=source.replace("shaft=[(-.18,.18),(.20,.18),(.20,-.98),(-.18,-.98),(-.18,-.77),(-.46,-.77),(-.46,-.49),(-.18,-.49),(-.18,-.25),(-.46,-.25)]", "shaft=[(-.12,.18),(.14,.18),(.14,-.98),(-.12,-.98),(-.12,-.79),(-.34,-.79),(-.34,-.57),(-.12,-.57),(-.12,-.35),(-.34,-.35),(-.34,-.14),(-.12,-.14)]")
source=source.replace("outside=[(-.48,1.06),(.48,1.06),(.68,.82),(.68,.23),(.47,.03),(-.48,.03),(-.68,.23),(-.68,.82)]", "outside=[(-.05,1.18),(.05,1.18),(.60,.60),(.60,.50),(.05,-.08),(-.05,-.08),(-.60,.50),(-.60,.60)]")
source=source.replace("inside=[(-.22,.81),(.22,.81),(.37,.67),(.37,.43),(.22,.28),(-.22,.28),(-.37,.43),(-.37,.67)]", "inside=[(-.02,.89),(.02,.89),(.31,.57),(.31,.53),(.02,.21),(-.02,.21),(-.31,.53),(-.31,.57)]")
source=source.replace("root.rotation_euler.y=.40", "root.rotation_euler.y=.30")
source=source.replace("[(-.39,-.27,.87),(-.25,-.27,.95),(.15,-.27,.95)]", "[(-.42,-.31,.64),(-.25,-.31,.84),(-.08,-.31,1.01)]")
source=source.replace("[('coin',coin),('racer',racer),('trophy',trophy),('shop-bag',bag),('key',key),('settings-gear',gear)]", "[('shop-bag-r2',bag),('racer-r2',racer),('key-r2',key)]")
exec(compile(source,str(folder/'generate_icons.py'),'exec'),{'__file__':str(folder/'generate_icons.py'),'__name__':'__main__'})
