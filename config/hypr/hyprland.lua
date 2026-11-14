pcall(require, "colors")
local modules = {
	"env",
	"config",
	"devices",
	"animations",
	"gestures",
	"binds",
	"rules",
	"start",
}

for _, mod in ipairs(modules) do
	pcall(require, string.format("modules.%s", mod))
end
