extends SimpleClickCommands

func click_clickable() -> void:
	if PopochiuUtils.e.clicked:
		await PopochiuUtils.g.show_system_text("Corvin has not worked out how to use %s yet." % PopochiuUtils.e.clicked.description)
	else:
		await super()

func right_click_clickable() -> void:
	if PopochiuUtils.e.clicked:
		await PopochiuUtils.g.show_system_text("It is wet, accusing, and probably evidence: %s." % PopochiuUtils.e.clicked.description)
	else:
		await super()

