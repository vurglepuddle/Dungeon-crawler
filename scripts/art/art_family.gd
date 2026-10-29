extends RefCounted
## Lower Watch has its own environment/props and retains floor-two fixtures.
static func for_floor(number: int) -> Dictionary:
 if number>=3: return {"walls":3,"fixtures":2,"props":3,"planes":"calm_v3_f3","weights":2}
 var base: int=clampi(number,1,2)
 return {"walls":base,"fixtures":base,"props":base,"planes":"calm_v3","weights":base}
