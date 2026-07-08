hl.config({
	general = {
		border_size = 1,
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
		gaps_in = 4,
		gaps_out = 4,
	},

	decoration = {
		rounding = 10,
		active_opacity = 0.95,
		inactive_opacity = 0.95,
		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		new_status = "slave",
	},

	scrolling = {
		direction = "right",
		column_width = 1.0,
		fullscreen_on_one_column = true,
		focus_fit_method = 1,
		explicit_column_widths = "0.5, 1.0",
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		middle_click_paste = false,
		force_default_wallpaper = -1,
		allow_session_lock_restore = true,
	},
	xwayland = {
		force_zero_scaling = true,
	},

	input = {
		-- kb_options = caps:swapescape
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_rules = "",
		numlock_by_default = true,
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			tap_to_click = true,
			scroll_factor = 0.5,
		},
	},

	gestures = {
		workspace_swipe_distance = 500,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_forever = true,
		workspace_swipe_use_r = true,
	},
})
