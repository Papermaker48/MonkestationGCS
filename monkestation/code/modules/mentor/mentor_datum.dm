GLOBAL_LIST_EMPTY(mentor_datums) // Active mentor datums
GLOBAL_PROTECT(mentor_datums)
GLOBAL_LIST_EMPTY(protected_mentors) // These appear to be anyone loaded from the config files
GLOBAL_PROTECT(protected_mentors)

GLOBAL_VAR_INIT(mentor_href_token, GenerateToken())
GLOBAL_PROTECT(mentor_href_token)

/datum/mentors
	var/list/datum/mentor_rank/ranks

	var/target // The Mentor's Ckey
	var/name = "nobody's mentor datum (no rank)" //Makes for better runtimes
	var/client/owner = null // The Mentor's Client

	/// href token for Mentor commands, uses the same token generator used by Admins.
	var/href_token

	var/dementored

	/// Are we a Contributor?
	var/is_contributor = FALSE

/datum/mentors/New(list/datum/mentor_rank/ranks, ckey, force_active = FALSE, protected) // Set this back to false after testing
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		if (!target) //only del if this is a true creation (and not just a New() proc call), other wise trialmins/coders could abuse this to deadmin other admins
			QDEL_IN(src, 0)
			CRASH("Admin proc call creation of mentor datum")
		return
	if(!ckey)
		QDEL_IN(src, 0)
		CRASH("Admin datum created without a ckey")
	if(!istype(ranks))
		QDEL_IN(src, 0)
		CRASH("Mentor datum created with invalid ranks: [ranks] ([json_encode(ranks)])")
	target = ckey
	name = "[ckey]'s mentor datum ([join_mentor_ranks(ranks)])"
	src.ranks = isnull(ranks) ? NONE : ranks
	href_token = GenerateToken()
	if(protected)
		GLOB.protected_mentors[target] = src
	if(force_active || (rank_flags() & R_AUTOMENTOR))
		activate()
	else
		deactivate()

/datum/mentors/Destroy()
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		return QDEL_HINT_LETMELIVE
	. = ..()

/datum/mentors/proc/activate()
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		return
	GLOB.dementors -= target
	GLOB.mentor_datums[target] = src
	dementored = FALSE
	if (GLOB.directory[target])
		associate(GLOB.directory[target]) //find the client for a ckey if they are connected and associate them with us

/datum/mentors/proc/deactivate()
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		return
	GLOB.dementors[target] = src
	GLOB.mentor_datums -= target

	dementored = TRUE

	var/client/client = owner || GLOB.directory[target]

	if (!isnull(client))
		disassociate()
		add_verb(client, /client/proc/rementor)
		client.update_special_keybinds()

/datum/mentors/proc/associate(client/client)
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		return

	if(!istype(client))
		return

	if(client?.ckey != target)
		var/msg = " has attempted to associate with [target]'s mentor datum"
		message_admins("[key_name_mentor(client)][msg]")
		log_admin("[key_name(client)][msg]")
		return

	if (dementored)
		activate()

//	remove_verb(client, /client/proc/admin_2fa_verify) // Mentors dont 2fa I think

	owner = client
	owner.mentor_datum = src
	owner.add_mentor_verbs()
	remove_verb(owner, /client/proc/rementor)
	owner.init_verbs() //re-initialize the verb list
	owner.update_special_keybinds()
	GLOB.mentors |= client

/datum/mentors/proc/disassociate()
	if(IsAdminAdvancedProcCall())
		var/msg = " has tried to elevate permissions!"
		message_admins("[key_name_admin(usr)][msg]")
		log_admin("[key_name(usr)][msg]")
		return
	if(owner)
		owner.mentor_datum = src
		//owner.add_mentor_verbs()
		GLOB.mentors += owner

/datum/mentors/proc/CheckMentorHREF(href, href_list)
	var/auth = href_list["mentor_token"]
	. = auth && (auth == href_token || auth == GLOB.mentor_href_token)
	if(.)
		return
	var/msg = !auth ? "no" : "a bad"
	message_admins("[key_name_admin(usr)] clicked an href with [msg] authorization key!")
	if(CONFIG_GET(flag/debug_admin_hrefs))
		message_admins("Debug mode enabled, call not blocked. Please ask your coders to review this round's logs.")
		log_world("UAH: [href]")
		return TRUE
	log_admin_private("[key_name(usr)] clicked an href with [msg] authorization key! [href]")

/proc/RawMentorHrefToken(forceGlobal = FALSE)
	var/tok = GLOB.mentor_href_token
	if(!forceGlobal && usr)
		var/client/client = usr.client
		if(!client)
			CRASH("No client for MentorHrefToken()!")
		var/datum/mentors/holder = client.mentor_datum
		if(holder)
			tok = holder.href_token
	return tok

/proc/MentorHrefToken(forceGlobal = FALSE)
	return "mentor_token=[RawMentorHrefToken(forceGlobal)]"

/proc/load_mentors()
	GLOB.mentor_datums.Cut()
	for(var/client/mentor_clients in GLOB.mentors)
		//mentor_clients.remove_mentor_verbs()
		mentor_clients.mentor_datum = null
	GLOB.mentors.Cut()
	var/list/lines = world.file2list("[global.config.directory]/mentors.txt")
	for(var/line in lines)
		if(!length(line))
			continue
		if(findtextEx(line, "#", 1, 2))
			continue
		new /datum/mentors(line)
