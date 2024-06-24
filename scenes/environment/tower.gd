extends Node3D

@onready var main_crystal = $Main_Cristal
@onready var tower_base = $Tower
@onready var banners = $Banners

enum colors {
	BASE,
	RED,
	BLUE
}

@export var color: colors = colors.BASE

const banner_albedo_base := Color(0.3, 0.3, 0.3, 1)
const crystal_albedo_base := Color(0.3, 0.3, 0.3, 1)
const crystal_emission_base := Color(0.3, 0.3, 0.3, 1)

const banner_albedo_red := Color(0.937255, 0, 0, 1)
const crystal_albedo_red := Color(0.890196, 0, 0, 1)
const crystal_emission_red := Color(0.679015, 0, 0, 1)

const banner_albedo_blue := Color(0.280465, 0.364858, 1, 1)
const crystal_albedo_blue := Color(0.32549, 0.270588, 1, 1)
const crystal_emission_blue := Color(0.0958602, 0.119587, 1, 1)


func _ready():
	set_color(color)


func set_color(new_color: colors):
	self.color = new_color
	match color:
		colors.BASE:
			main_crystal.albedo_color = crystal_albedo_base
			main_crystal.emission = crystal_emission_base
			tower_base.surface_material_override[0].albedo_color = banner_albedo_base
			banners.surface_material_override[0].albedo_color = banner_albedo_base
		colors.RED:
			main_crystal.albedo_color = crystal_albedo_red
			main_crystal.emission = crystal_emission_red
			tower_base.surface_material_override[0].albedo_color = banner_albedo_red
			banners.surface_material_override[0].albedo_color = banner_albedo_red
		colors.BLUE:
			main_crystal.albedo_color = crystal_albedo_blue
			main_crystal.emission = crystal_emission_blue
			tower_base.surface_material_override[0].albedo_color = banner_albedo_blue
			banners.surface_material_override[0].albedo_color = banner_albedo_blue 
