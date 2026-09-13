extends SceneTree

# 从实际使用的引擎提取许可原文，避免手抄遗漏。
func _init() -> void:
	var engine_license := Engine.get_license_text()
	assert(not engine_license.is_empty())
	write_notice("res://GODOT_LICENSE.txt", engine_license + "\n")
	var notice := "Godot Engine " + str(Engine.get_version_info().string) + "\n"
	notice += "Third-party copyright notices and license texts\n"
	notice += "Generated from Engine.get_copyright_info() and Engine.get_license_info().\n\n"
	var components := Engine.get_copyright_info()
	assert(not components.is_empty())
	for component in components:
		notice += "Component: " + str(component.name) + "\n"
		for part in component.parts:
			notice += "Files:\n" + "\n".join(part.files) + "\n"
			notice += "Copyright:\n" + "\n".join(part.copyright) + "\n"
			notice += "License: " + str(part.license) + "\n\n"
	var licenses := Engine.get_license_info()
	assert(not licenses.is_empty())
	for name in licenses:
		notice += "\n========================================\nLicense: " + str(name) + "\n\n" + str(licenses[name]) + "\n"
	write_notice("res://GODOT_THIRD_PARTY_NOTICES.txt", notice)
	print("Exported engine license, %d components and %d license texts." % [components.size(), licenses.size()])
	quit()

func write_notice(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null, "Cannot write license notice: " + path)
	file.store_string(content)
	file.close()
