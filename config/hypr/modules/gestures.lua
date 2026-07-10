hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- 4-finger swipe left = move focus right
hl.gesture({
	fingers = 4,
	direction = "left",
	action = function()
		hl.dsp.focus({ direction = "r" })
	end,
})

-- 4-finger swipe right = move focus left
hl.gesture({
	fingers = 4,
	direction = "right",
	action = function()
		hl.dsp.focus({ direction = "l" })
	end,
})

-- 4-finger swipe up = resize column to 1.0 (full width)
hl.gesture({
	fingers = 4,
	direction = "up",
	action = function()
		hl.notification.create({ text = "I just swiped on my trackpad!", timeout = 5000, icon = "ok" })
	end,
})

-- 4-finger swipe down = resize column to 0.5 (half width)
hl.gesture({
	fingers = 4,
	direction = "down",
	action = function()
		hl.notification.create({ text = "I just swiped on my trackpad!", timeout = 5000, icon = "ok" })
	end,
})
