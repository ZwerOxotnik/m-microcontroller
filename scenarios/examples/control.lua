if script.active_mods["brush-tools"] then
	local event_handler = require("event_handler")
	event_handler.add_lib(require("__brush-tools__/drawing-control"))
end
