class_name MachineBallPayload
extends RefCounted

static func clean(chain_id: String = "", source_pass: int = 0) -> Dictionary:
	return {
		"kind": "clean",
		"value": 1,
		"tags": [],
		"tuning_mark": "",
		"source_pass": source_pass,
		"chain_id": chain_id,
		"source": "machine",
	}

static func junk(chain_id: String = "", source: String = "Pool Polluter") -> Dictionary:
	var payload: Dictionary = clean(chain_id)
	payload["kind"] = "junk"
	payload["value"] = 0
	payload["tags"] = ["junk"]
	payload["source"] = source
	return payload

static func normalize(payload: Dictionary) -> Dictionary:
	var normalized: Dictionary = clean(String(payload.get("chain_id", "")), int(payload.get("source_pass", 0)))
	normalized["kind"] = String(payload.get("kind", normalized["kind"]))
	normalized["value"] = int(payload.get("value", normalized["value"]))
	var tags_variant: Variant = payload.get("tags", [])
	normalized["tags"] = (tags_variant as Array).duplicate() if tags_variant is Array else []
	normalized["tuning_mark"] = String(payload.get("tuning_mark", ""))
	normalized["source"] = String(payload.get("source", normalized["source"]))
	return normalized
