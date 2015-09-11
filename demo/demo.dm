#include <kaiochao\shapes\shapes.dme>
#include "..\..\keyboard\keyboard.dme"
#include "..\..\position\position.dme"
#include "..\..\math\math.dme"
#include "..\code\polygon.dm"

world
	maxx = 21
	maxy = 21
	fps = 30

	New()
		..()
		for(var/n in 1 to 50)
			var mob/m = new
			m.SetCenter(rand(32, (maxx-1)*32), rand(32, (maxy-1)*32), 1)
			m.color = "black"
			m.polygon = new
			var sides = rand(3, 8)
			var radius = rand(16, 32)
			var angle = rand(360)
			var dangle = 360 / sides
			for(var/s in 1 to sides)
				m.polygon.AddVertex(new /vector2 (radius*cos(angle), radius*sin(angle)))
				angle += dangle
			m.polygon.SetCenter(new /vector2 (m.Cx(), m.Cy()))
			m.overlays += m.polygon.GetLines()

turf
	icon_state = "rect"
	color = "white"

area
	invisibility = 101

client
	Move()

mob
	var
		polygon/polygon
		lines
		move_speed = 2
		turn_speed = 5

	Login()
		..()

		SetCenter(world.maxx*16, world.maxy*16, 1)

		polygon = new (
			new /vector2 (-16,  16),
			new /vector2 ( 16,  16),
			new /vector2 ( 16, -16),
			new /vector2 (-16, -16))
		polygon.SetCenter(new /vector2 (Cx(), Cy()))
		lines = polygon.GetLines()
		overlays += lines

		spawn while(client)
			polygon.Rotate(-client.GetAxis("east", "west") * turn_speed)
			polygon.Move(new /vector2 (
				client.GetAxis("d", "a") * move_speed,
				client.GetAxis("w", "s") * move_speed))

			polygon.SetCenter(new /vector2 (
				clamp(polygon.center.x, 32, (world.maxx-1)*32), 
				clamp(polygon.center.y, 32, (world.maxy-1)*32)))

			SetCenter(polygon.center.x, polygon.center.y, z)

			if(polygon.dirty)
			//	world.log << "dirty ([world.time])"
				overlays -= lines
				lines = polygon.GetLines()
				overlays += lines

			winset(src, ":window", "title=\"[world.name] ([world.cpu]%)\"")
			sleep world.tick_lag

