extends Node3D;

enum Genes {
	DETECTION_RADIUS,
	SPEED,
	WALK_RADIUS,
	TURN_FREQ
}

enum States {
	Walk,
	TurnR,
	TurnL,
	Idle
}

#must be a multiple of CHUNKL
var mapsize = Vector2(100,100)

var TILEX = 3
var TILEZ = 3

#controls size of each chunk
var CHUNKL = 5

var TileLocations = {}
var PointstoAStarIDs = {}
var GrassLocations = {}

var ChunkGrasses = {}
var GrassestoChunk = {}
var ChunkWaters = {}
var WaterstoChunk = {}
var WaterTileAdjacent = {}

var myAStar = AStar2D.new()

func _enter_tree():
	for i in range(int(mapsize.x/CHUNKL)+1):
		for j in range(int(mapsize.y/CHUNKL)+1):
			ChunkGrasses[Vector2(i,j)]={}
			ChunkWaters[Vector2(i,j)]={}


func genNav():
	PointstoAStarIDs = addAStarPoints()
	connectAStarPoints(PointstoAStarIDs);

func addAStarPoints():
	var i = 0
	var points_to_ids = {}
	for point in Data.TileLocations:
		i += 1
		myAStar.add_point(i, point)
		points_to_ids[point] = i
	return points_to_ids

func connectAStarPoints(points_to_ids):
	for point in Data.TileLocations:
		for x in range(3):
			var tile = point
			var target = tile + Vector2(x-1,0)
			
			if tile == target or not points_to_ids.has(target):
				continue
			
			if Vector2(point.x+x,point.y) in Data.TileLocations:
				myAStar.connect_points(points_to_ids[tile], points_to_ids[target], true)
			
		for y in range(3):
			
			var tile = point
			var target = tile + Vector2(0,y-1)
			
			if tile == target or not points_to_ids.has(target):
				continue
			
			if Vector2(point.x,point.y+y) in Data.TileLocations:
				myAStar.connect_points(points_to_ids[tile], points_to_ids[target], true)

#simplifies water to only waters that border land tiles
func genWater():
	var adjacents = [Vector2(0,1), Vector2(1,0), Vector2(0,-1), Vector2(-1,0)]
	var _keys = TileLocations.keys()
	var keys = []
	
	for key in _keys:
		keys.append([int(key.x), int(key.y)])
	
	var dqueue = {}
	for chunk in ChunkWaters:
		dqueue[chunk] = []
		for water in ChunkWaters[chunk]:
			var is_adjacent = false
			for adjacency in adjacents:
				if [int((ChunkWaters[chunk][water]+adjacency).x), int((ChunkWaters[chunk][water]+adjacency).y)] in keys:
					WaterTileAdjacent[ChunkWaters[chunk][water]] = ChunkWaters[chunk][water]+adjacency
					#var s = SpatialMaterial.new()
					#s.albedo_color = Color(1,1,1)
					#TileLocations[Vector2(int((ChunkWaters[chunk][water]+adjacency).x), int((ChunkWaters[chunk][water]+adjacency).y))].get_node("MeshInstance").material_override = s
					is_adjacent = true
			if not is_adjacent:
				dqueue[chunk].append(water)
	
	for chunk in dqueue:
		for water in dqueue[chunk]:
			ChunkWaters[chunk].erase(water)
