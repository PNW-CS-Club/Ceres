class_name Item extends Resource

enum Type {
	BUFF_SEED, DEF_SEED, HP_SEED,
	BUFF_BUFF_SEED, DEF_DEF_SEED, HP_HP_SEED,
	BUFF_DEF_SEED, BUFF_HP_SEED, DEF_HP_SEED,
	ULTIMATE_SEED,
	SHOVEL, WATER
}

@export var type: Type
@export var name: String
@export var texture: Texture2D
@export_multiline var desc: String
