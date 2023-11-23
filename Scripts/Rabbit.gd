extends MeshInstance3D

const s = Data.States

var velocity := Vector3()
var State := []
var g = Data.Genes
var genes = {
	g.DETECTION_RADIUS: 30,
	g.SPEED: 10,
	#Radius cannot be less than 3
	g.WALK_RADIUS: 12,
	g.TURN_FREQ: 12,
}

var adjacent = [Vector2(0,1),Vector2(1,0),Vector2(0,-1),Vector2(-1,0)]

var jumpCD = 0
var apothemjumpCD = 0.5
var init_rot = 0

var local_speed = Data.TILEX*2

var location : Vector2
var chunk : Vector2

var target 
var rrot = randi()%4*90

var hunger = 0.0
var thirst = 0.0
var will_consume = false

var myAStar
var PointstoAStarIDs = {}

var path 



func _ready():
	
	State.append(s.TurnL)
	
	$HP.texture = $HP/SubViewport.get_texture()
	
	
	#waits for sometime before letting bunnies go
	await get_tree().create_timer(2.5).timeout
	
	myAStar = Data.myAStar
	PointstoAStarIDs = Data.PointstoAStarIDs
	
	createRTarget()
	updatePath()

func _process(delta):
	
	if not path:
		return
	
	velocity.z = -sign(round(global_transform.basis.z.z))*local_speed
	velocity.x = -sign(round(global_transform.basis.z.x))*local_speed
	
	match(State[0]):
		s.Walk:
			jumpCD += delta
			
			if jumpCD <= 1: #jump
				pass
				velocity.y = 10*sin(2*jumpCD*PI)
			elif jumpCD <= 1 + delta*10+randi()%20: #pause before next jump
				velocity = Vector3()
			else: #
				jumpCD = 0
				location += Vector2(-sign(round(global_transform.basis.z.x)), -sign(round(global_transform.basis.z.z)))
				if int(location.x) % Data.CHUNKL == 0 or int(location.y) % Data.CHUNKL == 0:
					chunk = Vector2(int(location.x/Data.CHUNKL), int(location.y/Data.CHUNKL))
				
				stateComplete(delta)
		s.TurnL:
			rotation_degrees.y += 90
			if int(abs(rotation_degrees.y)) == 360:
				rotation_degrees.y = 0
			
			stateComplete(delta)
		s.TurnR:
			rotation_degrees.y -= 90
			if int(abs(rotation_degrees.y)) == 360:
				rotation_degrees.y = 0
			
			stateComplete(delta)
		s.Idle:
			if will_consume:
				wait()
			will_consume = null
			stateComplete(delta)
	
	position += velocity*delta

func stateComplete(delta:float):
	#updates velocity since it didn't have oppurtunity to before
	
	hunger += 1.0
	thirst += 1.2
	
	$HP/SubViewport/ProgressBar.updateHealth(hunger, thirst)
	
	
	position = Vector3(((location.x*2*Data.TILEX)-2*Data.TILEX)+0.1, -0.5, ((location.y*2*Data.TILEZ)-2*Data.TILEZ)-0.5)
	velocity = Vector3()
	
	if will_consume == null:
		createRTarget()
		updatePath()
		will_consume = false
	
	if will_consume != true:
		if typeof(target) == 5:
			if setBushTarget(neededTarget()):
				updatePath()
		
		if path.size() <= 2:
			if not typeof(target) == 5 and not will_consume:
				if target.get_groups().has("Grass"):
					hunger = 0.0
				elif target.get_groups().has("Water"):
					thirst = 0.0
				will_consume = true
			else:
				createRTarget()
				updatePath()
	
	State.remove_at(0)
	
	if State.size() == 0:
		
		#gets current rotation
		var rot := int(round(rotation_degrees.y))
		
		#makes sure it's not negative
		if rot < 0:
			# warning-ignore:narrowing_conversion
			rot = 360 - abs(rot)
		
		#bunny's rotation is actually negative since rotation_degrees is inversed
		rot = 360-rot
		
		#creates desired rotation
		var desired_rot := int(round(rad_to_deg((path[1]-path[0]).angle()))) + 90
		
		#makes sure desired rotation isn't negative
		if desired_rot < 0:
			# warning-ignore:narrowing_conversion
			desired_rot = 360 - abs(rot)
		
		#creates absolute rotation
		var erot = desired_rot-rot
		
		#removes this step in path
		path.remove_at(0)
		
		match(erot):
			0,360,-360:
				pass
			90,-270:
				State.append(s.TurnR)
			180,-180:
				State.append(s.TurnR)
				State.append(s.TurnR)
			270,-90:
				State.append(s.TurnL)
		if not will_consume:
			State.append(s.Walk)
		elif will_consume:
			State.append(s.Idle)

func setBushTarget(focus):
	if not max(hunger, thirst) >= 15.0:
		return false
	
	var targets = []
	for x in range(3):
		for y in range(3):
			
			if focus == "Grass":
				if Data.ChunkGrasses.has(chunk+Vector2(x-1,y-1)):
					for grass in Data.ChunkGrasses[chunk+Vector2(x-1,y-1)]:
						targets.append(grass)
			
			elif focus == "Water":
				if Data.ChunkWaters.has(chunk+Vector2(x-1,y-1)):
					for water in Data.ChunkWaters[chunk+Vector2(x-1,y-1)]:
						targets.append(water)
	
	if targets.size() == 0:
		return false
	
	var check
	for tar in targets:
		#REPLACE LOCATION WITH RELATIVE LOCATION
		if not check or (tar.location-location).length_squared()<(check.location-location).length_squared():
			check = tar
	
	var s = StandardMaterial3D.new()
	s.albedo_color = Color(1,1,1)
	check.get_node("MeshInstance3D").material_override = s
	
	target = check
	return true


func updatePath(): 
	var mtar
	if typeof(target)!=5:
		if target.get_groups().has("Grass"):
			mtar = PointstoAStarIDs[Data.ChunkGrasses[Data.GrassestoChunk[target]][target]]
		elif target.get_groups().has("Water"):
			mtar = PointstoAStarIDs[Data.WaterTileAdjacent[Data.ChunkWaters[Data.WaterstoChunk[target]][target]]]
	elif typeof(target)==5:
		mtar = PointstoAStarIDs[target]
	path = myAStar.get_point_path(PointstoAStarIDs[location], mtar)

#finds random path as a result of having no bushes or no suitable bushes
#Bush conditions are mtarget above

func createRTarget():
	var rtarget
	var skeys = Data.TileLocations.keys()
	var m = (randi()%2*2)-1
	
	if randi()%genes[g.WALK_RADIUS]==1:
		rrot += (2*randi()%2-1)*90
	
	while not rtarget: 
		var rlocation = (location + Vector2(0,-1).rotated(deg_to_rad(rrot)))
		rlocation.x = int(round(rlocation.x))
		rlocation.y = int(round(rlocation.y))
		
		if skeys.has(rlocation):
			rtarget = rlocation
			target = rtarget
			return
		else:
			if rrot == 360:
				rrot = 0
			rrot += 90*m
			if rrot == 360:
				rrot = 0
			if rrot == -90:
				rrot = 270

func neededTarget():
	if int(max(hunger, thirst)) == int(hunger):
		return "Grass"
	else:
		return "Water"

func minFood():
	return min(hunger, thirst)

func wait():
	set_process(false)
	await get_tree().create_timer(2).timeout
	set_process(true)
