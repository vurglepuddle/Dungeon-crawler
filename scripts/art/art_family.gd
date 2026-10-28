extends RefCounted
## One mapping for the independent painted families. Lower Watch can later
## change its environment while retaining the two-floor fixtures and props.
static func for_floor(number: int) -> Dictionary:
 var base: int=clampi(number,1,2)
 return {"walls":base,"fixtures":base,"props":base,"planes":"calm_v3","weights":base}
