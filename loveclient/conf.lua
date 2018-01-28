
function love.conf(t)
    t.version = '0.10.2'
    t.window.display = 1
    t.window.centered = true
    t.window.title = "T-Line"
    t.window.resizable = false
    t.window.width = 1280
    t.window.height = 720

	t.modules.thread = false
	t.modules.touch = false
	t.modules.joystick = false
	t.modules.sound = false
	t.modules.audio = false
	t.modules.video = false
	t.modules.math = false
	t.modules.physics = false
	t.modules.system = false
end