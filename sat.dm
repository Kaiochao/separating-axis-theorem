#include "..\math\math.dme"
#include "..\mouse\mouse.dme"
#include <kaiochao\shapes\shapes.dme>

world
	maxx = 5
	maxy = 5
	fps = 60

mob/Login()
	..()

	var shape_a_angle = rand(360)
	var shape_b_angle = rand(360)

	var shape/shape_a = new
	shape_a.SetCenter(0, 0)
	shape_a.AddVertex(-16, -16)
	shape_a.AddVertex(-16, 16)
	shape_a.AddVertex(16, 16)
	shape_a.AddVertex(16, -16)
	shape_a.Rotate(-shape_a_angle)

	var shape/shape_b = new
	shape_b.SetCenter(8, 16)
	shape_b.AddVertex(-16, -16)
	shape_b.AddVertex(-16, 16)
	shape_b.AddVertex(16, 16)
	shape_b.AddVertex(16, -16)
	shape_b.Rotate(-shape_b_angle)

	var turf/t = locate(3, 3, 1)
	var obj/box_a = new (t)
	var obj/box_b = new (t)
	var obj/box_a_resolved = new
	var matrix/box_size = matrix() * (32/32)

	spawn for()
		winset(src, ":window", "title=\"[world.name] ([world.cpu]%)\"")
		sleep world.tick_lag

		// control shape_a's position with the mouse
		shape_a.SetCenter(client.mouse_x - 32*(t.x-0.5), client.mouse_y - 32*(t.y-0.5))

		// get all unique axes
		var raw_axes[] = shape_a.GetAxes() + shape_b.GetAxes()
		var axis_tags[0]
		for(var/i in 1 to raw_axes.len)
			var axis[] = raw_axes[i]
			var axis_tag = "[axis[1]],[axis[2]]"
			axis_tags[axis_tag] = axis

		var axes[axis_tags.len]
		for(var/i in 1 to axes.len)
			axes[i] = axis_tags[axis_tags[i]]

		var smallest_separation = 1#INF
		var mtv[]

		for(var/a in 1 to axes.len)
			var axis[] = axes[a]
			var ap[] = shape_a.GetProjection(axis)
			var bp[] = shape_b.GetProjection(axis)

			var apc = shape_a.GetProjectedCenter(axis)
			var bpc = shape_b.GetProjectedCenter(axis)
			var apg[] = list(ap[1] + apc, ap[2] + apc)
			var bpg[] = list(bp[1] + bpc, bp[2] + bpc)
			if(apg[2] > bpg[1] && apg[1] <= bpg[2])
				var separation
				if(abs(apg[2] - bpg[1]) < abs(apg[1] - bpg[2]))
					separation = bpg[1] - apg[2]
				else
					separation = bpg[2] - apg[1]
				if(abs(separation) < smallest_separation)
					smallest_separation = abs(separation)
					mtv = vec2_scale(axis, separation)

			else
				mtv = null
				break

		// draw boxes

		box_a.name = "mover"
		box_a.icon_state = "rect"
		box_a.color = "blue"

		box_a.transform = box_size \
			* matrix(shape_a_angle, MATRIX_ROTATE) \
			* matrix(shape_a.center[1], shape_a.center[2], MATRIX_TRANSLATE)

		box_b.name = "obstacle"
		box_b.icon_state = "rect"
		box_b.color = "red"
		box_b.transform = box_size \
			* matrix(shape_b_angle, MATRIX_ROTATE) \
			* matrix(shape_b.center[1], shape_b.center[2], MATRIX_TRANSLATE)

		// display resolved box when collision occurs
		if(mtv)
			box_a_resolved.loc = t
			box_a_resolved.name = "resolved mover"
			box_a_resolved.icon_state = "rect"
			box_a_resolved.color = rgb(0, 255, 0, 128)
			box_a_resolved.transform *= 4/32
			box_a_resolved.transform = box_a.transform \
				* matrix(mtv[1], mtv[2], MATRIX_TRANSLATE)
		else
			box_a_resolved.loc = null

proc/vec2_scale(v[], s)
	return list(v[1]*s, v[2]*s)

proc/vec2_add(a[], b[])
	return list(a[1]+b[1], a[2]+b[2])

proc/vec2_rotate(v[], angle)
	var c = cos(angle), s = sin(angle)
	return list(v[1]*c-v[2]*s, v[1]*s+v[2]*c)

proc/vec2_dot(a[], b[])
	return a[1]*b[1] + a[2]*b[2]

shape
	var
		vertices[]
		center[]

	proc
		SetCenter(X, Y)
			center = list(X, Y)

		// vertices should be added clockwise
		AddVertex(X, Y)
			vertices = vertices || new
			vertices[++vertices.len] = list(X, Y)

		Rotate(Angle) if(clamp_angle(Angle))
			var c = cos(Angle), s = sin(Angle)
			for(var/i in 1 to vertices.len)
				var vertex[] = vertices[i]
				var new_vertex[] = list(
					vertex[1]*c - vertex[2]*s,
					vertex[1]*s + vertex[2]*c)
				vertices[i] = new_vertex

		// returns list(min, max) along unit vector Axis[]
		GetProjection(Axis[])
			var min = 1#INF, max = -1#INF
			for(var/i in 1 to vertices.len)
				var vertex[] = vertices[i]
				var projection = vec2_dot(vertex, Axis)
				min = min(min, projection)
				max = max(max, projection)
			return list(min, max)

		GetProjectedCenter(Axis[])
			return vec2_dot(center, Axis)

		// returns a list of unit vectors from one vertex to the next
		GetAxes()
			var axes[0]
			for(var/i in 1 to vertices.len - 1)
				var a[] = vertices[i]
				var b[] = vertices[i+1]
				var d[] = list(b[1] - a[1], b[2] - a[2])
				var idist = 1/sqrt(d[1]*d[1] + d[2]*d[2])
				d[1] *= idist
				d[2] *= idist
				axes[++axes.len] = list(-d[2], d[1])
			return axes
