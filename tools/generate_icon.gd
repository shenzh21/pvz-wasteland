extends SceneTree

const SOURCE := "res://assets/icon.svg"
const PNG_OUTPUT := "res://assets/icon.png"
const ICO_OUTPUT := "res://assets/icon.ico"
const ICON_SIZES := [16,24,32,48,64,128,256]

func _init() -> void:
	var source := Image.new()
	var error := source.load_svg_from_string(FileAccess.get_file_as_string(SOURCE),1.0)
	if error!=OK:
		push_error("无法读取应用图标 SVG：%s" % error_string(error))
		quit(1)
		return
	source.save_png(PNG_OUTPUT)
	var png_images: Array[PackedByteArray] = []
	for icon_size in ICON_SIZES:
		var image := source.duplicate()
		image.resize(icon_size,icon_size,Image.INTERPOLATE_LANCZOS)
		png_images.append(image.save_png_to_buffer())
	var directory_size := 6+16*png_images.size()
	var ico := PackedByteArray()
	ico.resize(directory_size)
	ico.encode_u16(0,0)
	ico.encode_u16(2,1)
	ico.encode_u16(4,png_images.size())
	var image_offset := directory_size
	for index in png_images.size():
		var entry_offset := 6+index*16
		var icon_size: int = ICON_SIZES[index]
		ico[entry_offset] = 0 if icon_size==256 else icon_size
		ico[entry_offset+1] = 0 if icon_size==256 else icon_size
		ico[entry_offset+2] = 0
		ico[entry_offset+3] = 0
		ico.encode_u16(entry_offset+4,1)
		ico.encode_u16(entry_offset+6,32)
		ico.encode_u32(entry_offset+8,png_images[index].size())
		ico.encode_u32(entry_offset+12,image_offset)
		image_offset += png_images[index].size()
	for png in png_images:
		ico.append_array(png)
	var file := FileAccess.open(ICO_OUTPUT,FileAccess.WRITE)
	if file==null:
		push_error("无法写入 Windows 图标")
		quit(1)
		return
	file.store_buffer(ico)
	file.close()
	print("已生成 %s 和 %s" % [PNG_OUTPUT,ICO_OUTPUT])
	quit()
