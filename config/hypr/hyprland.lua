local modules = {
	"env",
	"config",
	"devices",
	"animations",
	"gestures",
	"binds",
	"rules",
	"start",
	"colors",
}

for _, mod in ipairs(modules) do
	pcall(require, string.format("modules.%s", mod))
end
