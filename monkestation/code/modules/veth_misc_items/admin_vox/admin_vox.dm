ADMIN_VERB(AdminVOX, R_ADMIN, "VOX", "Allows unrestricted use of the AI VOX announcement system.", ADMIN_CATEGORY_MAIN)
	// Prompt message via TGUI
	var/message = tgui_input_text(user, "Enter your VOX announcement message:", "AdminVOX", encode = FALSE)

	BLACKBOX_LOG_ADMIN_VERB("Show VOX Announcement")

/datum/vox_holder/admin
	cooldown = 5 SECONDS
	var/datum/admins/parent

/datum/vox_holder/admin/New(datum/admins/parent)
	. = ..()
	src.parent = parent

/datum/vox_holder/admin/Destroy(force)
	parent = null
	return ..()

	if(LAZYLEN(incorrect_words))
		to_chat(user, span_notice("These words are not available on the announcement system: [english_list(incorrect_words)]."))
		return

	// Announce to players on the same Z-level
	var/list/players = list()
	var/turf/ai_turf = get_turf(user.mob)
	for(var/mob/player_mob in GLOB.player_list)
		var/turf/player_turf = get_turf(player_mob)
		if(is_valid_z_level(ai_turf, player_turf))
			players += player_mob

	minor_announce(capitalize(message), "[user.mob] announces:", players = players, should_play_sound = FALSE)

	// Play each VOX word for the announcement
	for(var/word in words)
		play_vox_word(word, ai_turf, null)

	// Log the successful announcement
	message_admins("[key_name(user)] made a VOX announcement: \"[message]\".")
	log_admin("[key_name(user)] made a VOX announcement: \"[message]\".")
	BLACKBOX_LOG_ADMIN_VERB("Show VOX Announcement")
