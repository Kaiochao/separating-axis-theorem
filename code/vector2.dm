vector2
	var x, y

	New(X, Y)
		x = X
		y = Y

	proc
		Copy() return new /vector2 (x, y)

		Equals(vector2/V) return x == V.x && y == V.y

		IsParallel(vector2/V) return Equals(V) || x == -V.x && y == -V.y

		Add(vector2/V) return new /vector2 (x + V.x, y + V.y)

		Subtract(vector2/V) return new /vector2 (x - V.x, y - V.y)

		Scale(S) return new /vector2 (x * S, y * S)

		Dot(vector2/V) return x * V.x + y * V.y

		Magnitude() return sqrt(Dot(src))

		Angle() return (x||y)&&(y>=0?arccos(x/sqrt(x*x+y*y)) : -arccos(x/sqrt(x*x+y*y)))

		Unit() return Scale(1/Magnitude())

		ToText() return "([x], [y])"

		Rotate(Angle)
			var c = cos(Angle), s = sin(Angle)
			return new /vector2 (c*x - s*y, s*x + c*y)

		IsZero() return !(x || y)
