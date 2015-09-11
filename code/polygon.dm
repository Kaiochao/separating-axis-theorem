#include "vector2.dm"
#include "aabb.dm"

polygon
	var
		vector2/vertices[]
		vector2/center

		axes[]
		aabb/aabb

		obj/lines

		dirty = ~0

	New()
		for(var/vector2/vertex in args)
			AddVertex(vertex)

	proc
		SetCenter(vector2/C)
			if(center && center.Equals(C)) return
			center = C
			dirty |= 1

		GetLines()
			if(!lines)
				lines = new
				for(var/i in 1 to vertices.len)
					var vector2/a = vertices[i]
					var vector2/b = vertices[i % vertices.len + 1]
					var vector2/d = b.Subtract(a)
					var obj/o = new
					var matrix/m = new
					m.Translate(16)
					m.Scale(2/32, d.Magnitude()/32)
					m.Turn(90 - d.Angle())
					m.Translate(a.x, a.y)
					o.transform = m
					o.icon_state = "rect"
					lines.overlays += o
			return lines.appearance

		AddVertex(vector2/V)
			vertices = vertices ? vertices + V : list(V)
			dirty = ~0

		Translate(vector2/V) if(!V.IsZero())
			SetCenter(center.Add(V))

		Move(vector2/V) if(!V.IsZero())
			Translate(V)
			ResolveCollisions()

		Rotate(Angle) if(Angle)
			for(var/i in 1 to vertices.len)
				var vector2/vertex = vertices[i]
				vertices[i] = vertex.Rotate(Angle)
			lines.transform = turn(lines.transform, -Angle)
			ResolveCollisions()
			dirty |= 2

		ResolveCollisions()
			lines.color = "blue"
			for(var/polygon/p)
				if(p == src) continue
				var vector2/overlap = GetShortestOverlap(p)
				if(overlap)
					lines.color = "aqua"
					Translate(overlap)

		GetShortestOverlap(polygon/Other)
			var aabb/aabb = GetAABB()
			if(!aabb.IsIntersecting(Other.GetAABB())) return
			var axes[] = GetAxes() | Other.GetAxes()
			var smallest_overlap = 1#INF
			var vector2/smallest_vector
			for(var/vector2/axis in axes)
				var projection/p1 = GetProjection(axis)
				var projection/p2 = Other.GetProjection(axis)
				if(!p1.IsIntersecting(p2)) return FALSE
				var overlap = p1.GetSmallestOverlap(p2)
				if(abs(overlap) < smallest_overlap)
					smallest_overlap = abs(overlap)
					smallest_vector = axis.Scale(overlap)
			return smallest_overlap && smallest_vector

		GetAABB()
			if(dirty & 1)
				dirty &= ~1
				var min_x = 1#INF, max_x = -1#INF
				var min_y = 1#INF, max_y = -1#INF
				for(var/vector2/vertex in vertices)
					min_x = min(min_x, vertex.x)
					min_y = min(min_y, vertex.y)
					max_x = max(max_x, vertex.x)
					max_y = max(max_y, vertex.y)
				aabb = new /aabb (
					min_x + center.x, min_y + center.y,
					max_x + center.x, max_y + center.y)
			return aabb

		GetAxes()
			if(dirty & 2)
				dirty &= ~2
				axes = new (vertices.len)
				for(var/i in 1 to vertices.len)
					var vector2/a = vertices[i]
					var vector2/b = vertices[i % vertices.len + 1]
					var vector2/d = b.Subtract(a)
					d = d.Unit()
					axes[i] = new /vector2 (-d.y, d.x)
			return axes

		GetProjection(vector2/Axis)
			var minimum =  1#INF
			var maximum = -1#INF
			var center_projection = center.Dot(Axis)
			for(var/vector2/vertex in vertices)
				var scalar_projection = vertex.Dot(Axis)
				minimum = min(minimum, scalar_projection)
				maximum = max(maximum, scalar_projection)
			return new /projection (
				minimum + center_projection, 
				maximum + center_projection)

projection
	var
		minimum
		maximum

	New(Minimum, Maximum)
		minimum = Minimum
		maximum = Maximum

	proc
		IsIntersecting(projection/Other)
			return !(maximum < Other.minimum || minimum > Other.maximum)

		GetSmallestOverlap(projection/Other)
			var a = Other.minimum - maximum
			var b = Other.maximum - minimum
			return abs(a) < abs(b) ? a : b
