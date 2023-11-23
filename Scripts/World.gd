extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var CAMERA_SPEED = 1

var mapsize = Data.mapsize

const RABBIT = preload("res://Scenes/Ribbit.tscn")
const TILE = preload("res://Scenes/FloorTile.tscn")
const GRASS = preload("res://Scenes/Grass.tscn")
enum TILE_COLOR {
	Water,
	Grass,
	Sand
}
const TILE_COLORS = {
	TILE_COLOR.Water : [Color("#70b9f9"),Color("#529bf7")],
	TILE_COLOR.Grass : [Color("#a8c135"),Color("#509033")],
	TILE_COLOR.Sand : [Color("#fffc74"),Color("#e6c14e")]
}

var CHUNKL = Data.CHUNKL
var TILEX = Data.TILEX
var TILEZ = Data.TILEZ
const Y_PLANE = 2

var noise:  FastNoiseLite

var mouse_sens = 0.3
var pivot_point = false

var delta

func _input(event):         
	if event is InputEventMouseMotion:
		if pivot_point:
			$Camera3D.rotation_degrees.x+=event.relative.y*mouse_sens
			$Camera3D.rotation_degrees.y+=event.relative.x*mouse_sens
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				$Camera3D.position -= $Camera3D.global_transform.basis.z * 90 * delta
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				$Camera3D.position += $Camera3D.global_transform.basis.z * 90 * delta

# Called when the node enters the scene tree for the first time.
func _ready():
	var chunk = null
	
	genNoise()
	
	#Gen World
	for x in range(mapsize.x):
		for z in range(mapsize.y):
			chunk = Vector2(int(x/CHUNKL),int(z/CHUNKL))
			#instances tile for world and correctly scales it
			var t = TILE.instantiate()
			t.scale.x = TILEX
			t.scale.z = TILEZ
			add_child(t)
			t.position = Vector3(x*TILEX*2, 0, z*TILEZ*2)
			#creates type of tile
			var m = StandardMaterial3D.new()
			var n = noise.get_noise_2d(float(x), float(z))
			#if random noise is a certain threshold, change its type
			var color
			if n < -0.1:
				color = TILE_COLORS[TILE_COLOR.Water][0].blend(Color(TILE_COLORS[TILE_COLOR.Water][1].r,TILE_COLORS[TILE_COLOR.Water][1].g,TILE_COLORS[TILE_COLOR.Water][1].b,pow(-(n+0.1),0.3)))
				t.position.y -= 1.5
				if n > -0.175:
					Data.WaterstoChunk[t] = chunk
					Data.ChunkWaters[chunk][t] = Vector2(x,z)
				t.add_to_group("Water")
			elif n < 0.05:
				color = TILE_COLORS[TILE_COLOR.Sand][1].blend(Color(TILE_COLORS[TILE_COLOR.Sand][0].r,TILE_COLORS[TILE_COLOR.Sand][0].g,TILE_COLORS[TILE_COLOR.Sand][0].b,pow((-n+0.05),0.23)))
				Data.TileLocations[Vector2(x,z)] = t
			else:
				n=snapped(n, 0.01)
				color = TILE_COLORS[TILE_COLOR.Grass][0].blend(Color(TILE_COLORS[TILE_COLOR.Grass][1].r,TILE_COLORS[TILE_COLOR.Grass][1].g,TILE_COLORS[TILE_COLOR.Grass][1].b,pow(n-0.05,0.5)))
				#Rabbit will only spawn on grass
				#genRabbit(x, z)
				genGrass(x, z, chunk)
				Data.TileLocations[Vector2(x,z)] = t
				#if randi()%200==1:
				#	genRabbit(x,z)
			t.add_to_group("Tile")
			t.location = Vector2(x,z)
			m.albedo_color = color
			#assigns color 
			t.get_node("MeshInstance3D").material_override = m
	Data.genNav()
	Data.genWater()
	
	var ty = true
	var randx
	var randy
	while ty:
		randx = randi()%100
		randy = randi()%100
		if Vector2(randx, randy) in Data.TileLocations:
			genRabbit(1, 1)
			ty = false

func _process(_delta):
	handle_camera(_delta)


func handle_camera(_delta):
	delta = _delta
	var translate = Vector3()
	var r = $Camera3D.global_transform.basis.z.normalized() * CAMERA_SPEED
	if Input.is_action_pressed("ui_up"):
		translate.z -= r.z
		translate.x -= r.x
	if Input.is_action_pressed("ui_down"):
		translate.z += r.z
		translate.x += r.x
	if Input.is_action_pressed("ui_left"):
		r = r.rotated(Vector3(0,1,0), PI/2)
		translate.z -= r.z
		translate.x -= r.x
	if Input.is_action_pressed("ui_right"):
		r = r.rotated(Vector3(0,1,0), -PI/2)
		translate.z -= r.z
		translate.x -= r.x
	$Camera3D.position = lerp($Camera3D.position, $Camera3D.position+translate*delta*600, 0.1)
	if Input.is_action_pressed("ui_right_click"):
		pivot_point = true
	else:
		pivot_point = false

func genNoise():
	randomize()
	noise = FastNoiseLite.new()
	noise.seed = randi()
	
	noise.fractal_octaves = 1
	#noise. = 25
	noise.fractal_lacunarity = 1.5
	#noise. = 0.5

func genRabbit(x, z):
	var r = RABBIT.instantiate()
	r.get_node("Rabbit").location = Vector2(x,z)
	r.get_node("Rabbit").scale *= 1.5
	r.position = Vector3(x*TILEX*2+0.1, Y_PLANE+1, z*TILEZ*2+0.5)
	r.get_node("Rabbit").chunk = Vector2(int(x/CHUNKL),int(z/CHUNKL))
	add_child(r)

func genGrass(x, z, _chunk):
	if randi() % 50 == 1:
		var b = GRASS.instantiate()
		add_child(b)
		b.add_to_group("Grass")
		b.scale *= 2
		b.position = Vector3(x*TILEX*2, Y_PLANE-1, z*TILEZ*2)
		b.location = Vector2(x,z)
		Data.GrassestoChunk[b] = _chunk
		Data.ChunkGrasses[_chunk][b] = Vector2(x, z)
