/client/proc/reload_mentors() //TODO convert to AVD or merge with admins system
	set name = "Reload Mentors"
	set category = "Admin"

	if(!src.holder)
		return

	var/confirm = tgui_alert(usr, "Are you sure you want to reload all mentors?", "Confirm", list("Yes", "No"))
	if(confirm != "Yes")
		return

	load_mentors()
	MentorizeAdmins()
	BLACKBOX_LOG_ADMIN_VERB("Reload All Mentors")
	message_admins("[key_name_admin(usr)] manually reloaded mentors")

//Mentor verb for reloading mentors
MENTOR_VERB(mreload_mentors, R_HEADMENTOR, FALSE, "Reload Mentors(M)", "Reloads all mentors from the database.", MENTOR_CATEGORY_MAIN)
	var/confirm = tgui_alert(user, "Are you sure you want to reload all mentors?", "Confirm", list("Yes", "No"))
	if(confirm != "Yes")
		return

	load_mentors()
	MentorizeAdmins()
	BLACKBOX_LOG_MENTOR_VERB("Reload All Mentors")
	message_admins("[key_name_mentor(user)] manually reloaded admins")
