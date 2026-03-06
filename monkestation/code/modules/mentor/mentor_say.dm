/*
/client/proc/cmd_mentor_say(msg as text) //TODO convert to AVD or merge with admins system
	set category = "Mentor"
	set name = "Mentorsay"

	if(!is_mentor())
		to_chat(src, span_danger("Error: Only mentors and administrators may use this command."), confidential = TRUE)
		return

	var/prefix = "MENTOR"
	var/prefix_color = "#E236D8"
	if(check_rights_for(user, R_ADMIN, 0))
		prefix = "STAFF"
		prefix_color = "#8A2BE2"
	else if(user.mentor_datum.is_contributor)
		prefix = "CONTRIB"
		prefix_color = "#16ABF9"

	SSplexora.relay_mentor_say(user, html_decode(message), prefix)
	message = emoji_parse(message)

	var/list/pinged_mentor_clients = check_mentor_pings(message)
	if(length(pinged_mentor_clients) && pinged_mentor_clients[ASAY_LINK_PINGED_ADMINS_INDEX])
		message = pinged_mentor_clients[ASAY_LINK_PINGED_ADMINS_INDEX]
		pinged_mentor_clients -= ASAY_LINK_PINGED_ADMINS_INDEX

	for(var/iter_ckey in pinged_mentor_clients)
		var/client/iter_mentor_client = pinged_mentor_clients[iter_ckey]
		if(iter_mentor_client?.mentor_datum.dementored)
			continue
		window_flash(iter_mentor_client)
		SEND_SOUND(iter_mentor_client.mob, sound('sound/misc/bloop.ogg'))

	log_mentor("MSAY: [key_name(user)] : [message]")
	message = keywords_lookup(message)
	message = "<b><font color = '[prefix_color]'><span class='prefix'>[prefix]:</span> <EM>[key_name(user, 0, 0)]</EM>: <span class='message linkify'>[message]</span></font></b>"

	for(var/client/mentor as anything in GLOB.admins | GLOB.mentors)
		to_chat(
			mentor,
			type = MESSAGE_TYPE_MODCHAT,
			html = message,
			avoid_highlighting = (mentor == user),
			confidential = TRUE,
		)

	BLACKBOX_LOG_MENTOR_VERB("Msay")

// Checks a given message to see if any of the words contain an active mentor's ckey with an @ before it
/proc/check_mentor_pings(message)
	var/list/msglist = splittext(message, " ")
	var/list/mentors_to_ping = list()

	var/i = 0
	for(var/word in msglist)
		i++
		if(!length(word))
			continue
		if(word[1] != "@")
			continue
		var/ckey_check = ckey(copytext(word, 2))
		var/client/client_check = GLOB.directory[ckey_check]
		if(client_check?.mentor_datum?.check_for_rights(R_MENTOR))
			msglist[i] = "<u>[word]</u>"
			mentors_to_ping[ckey_check] = client_check

	if(length(mentors_to_ping))
		mentors_to_ping[ASAY_LINK_PINGED_ADMINS_INDEX] = jointext(msglist, " ")
		return mentors_to_ping

///Gives both Mentors & Admins all Mentor verb
/client/proc/add_mentor_verbs()
	if(mentor_datum || holder)
		add_verb(src, GLOB.mentor_verbs)

/client/proc/remove_mentor_verbs()
	remove_verb(src, GLOB.mentor_verbs)

/// Verb for opening the requests manager panel
/client/proc/toggle_mentor_states()
	set name = "Toggle Mentor State"
	set desc = "Swaps between mentor pings and no mentor pings."
	set category = "Mentor"
	if(mentor_datum)
		if(mentor_datum.not_active)
			mentor_datum.not_active = FALSE
			to_chat(src, span_notice("You will now recieve mentor helps again!"))
		else
			mentor_datum.not_active = TRUE
			to_chat(src, span_notice("You will no longer recieve mentor helps!"))
*/
