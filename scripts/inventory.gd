class_name Inventory
extends RefCounted
## Slot-based item storage. Each slot is {} (empty) or {"id": String, "count": int}.

signal changed

var slots: Array = []


func _init(slot_count := 12) -> void:
	for i in slot_count:
		slots.append({})


## How many more of `id` fit right now.
func room_for(id: String) -> int:
	var room := 0
	var stack := Items.stack_size(id)
	for s in slots:
		if s.is_empty():
			room += stack
		elif s.id == id:
			room += stack - s.count
	return room


func can_add(id: String, amount := 1) -> bool:
	return room_for(id) >= amount


## Adds as much as fits. Returns the amount that did NOT fit.
func add(id: String, amount := 1) -> int:
	var stack := Items.stack_size(id)
	var left := amount
	for s in slots:
		if left > 0 and not s.is_empty() and s.id == id and s.count < stack:
			var put := mini(left, stack - s.count)
			s.count += put
			left -= put
	for i in slots.size():
		if left > 0 and slots[i].is_empty():
			var put := mini(left, stack)
			slots[i] = {"id": id, "count": put}
			left -= put
	if left < amount:
		changed.emit()
	return left


func count(id: String) -> int:
	var total := 0
	for s in slots:
		if not s.is_empty() and s.id == id:
			total += s.count
	return total


func has(cost: Dictionary) -> bool:
	for id in cost:
		if count(id) < cost[id]:
			return false
	return true


func remove(id: String, amount: int) -> bool:
	if count(id) < amount:
		return false
	var left := amount
	for i in range(slots.size() - 1, -1, -1):  # drain the last stacks first
		var s = slots[i]
		if left > 0 and not s.is_empty() and s.id == id:
			var take := mini(left, s.count)
			s.count -= take
			left -= take
			if s.count == 0:
				slots[i] = {}
	changed.emit()
	return true


func pay(cost: Dictionary) -> bool:
	if not has(cost):
		return false
	for id in cost:
		remove(id, cost[id])
	return true


## Moves slot `a` onto slot `b`: merges equal items, otherwise swaps.
func swap(a: int, b: int) -> void:
	if a == b:
		return
	var sa = slots[a]
	var sb = slots[b]
	if not sa.is_empty() and not sb.is_empty() and sa.id == sb.id:
		var put := mini(sa.count, Items.stack_size(sa.id) - sb.count)
		sb.count += put
		sa.count -= put
		if sa.count == 0:
			slots[a] = {}
	else:
		slots[a] = sb
		slots[b] = sa
	changed.emit()


func used_slots() -> int:
	var n := 0
	for s in slots:
		if not s.is_empty():
			n += 1
	return n
