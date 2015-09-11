aabb
	var
		min_x
		min_y
		max_x
		max_y

	New(Left, Bottom, Right, Top)
		min_x = Left
		min_y = Bottom
		max_x = Right
		max_y = Top

	proc
		IsIntersecting(aabb/Other)
			return !(\
				   max_x < Other.min_x \
				|| min_x > Other.max_x \
				|| max_y < Other.min_y \
				|| min_y > Other.max_y)
