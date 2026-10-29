extends RefCounted
## Lower Watch has its own environment/props and retains floor-two fixtures.
static func for_floor(number: int) -> Dictionary:
 # The Winding wears B's dark Deep slate; the Deep keeps the Lower Watch until
 # families are chosen per block (the owner: "some rooms in that style - just not all").
 if number>=5: return {"walls":4,"fixtures":2,"props":3,"planes":"calm_v3_f4","weights":2}
 if number==4: return {"walls":3,"fixtures":2,"props":3,"planes":"calm_v3_f3","weights":2}
 if number==3: return {"walls":3,"fixtures":2,"props":3,"planes":"calm_v3_f3","weights":2}
 var base: int=clampi(number,1,2)
 return {"walls":base,"fixtures":base,"props":base,"planes":"calm_v3","weights":base}
