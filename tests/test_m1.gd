extends "res://tests/test_m2.gd"
## M1 findings migrated to current M2 rules. The old 13,469-check result is historical.
func _initialize() -> void:
	_rules()
	print("M1 regressions under M2 rules: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)