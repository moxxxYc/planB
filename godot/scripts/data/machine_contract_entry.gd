class_name MachineContractEntry
extends Resource

@export var source: String = ""
@export var warehouse: String = ""
@export var target_component: String = ""
@export var operation: String = ""
@export var scope: String = ""
@export_multiline var player_read: String = ""
@export_multiline var failure_risk: String = ""
@export_multiline var guardrail: String = ""

func is_complete() -> bool:
	return (
		not source.is_empty()
		and not warehouse.is_empty()
		and not target_component.is_empty()
		and not operation.is_empty()
		and not scope.is_empty()
		and not player_read.is_empty()
		and not failure_risk.is_empty()
		and not guardrail.is_empty()
	)
