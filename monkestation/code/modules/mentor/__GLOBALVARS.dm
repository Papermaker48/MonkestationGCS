GLOBAL_LIST_EMPTY(mentorlog)
GLOBAL_PROTECT(mentorlog)
GLOBAL_LIST_EMPTY(mentors) // All ckeys who have an active mentor datum and had at one point an active client
GLOBAL_PROTECT(mentors)

GLOBAL_LIST_INIT(mentor_verbs, list(
	//client/proc/cmd_mentor_say,
	//client/proc/mentor_requests,
	//client/proc/toggle_mentor_states,
	//client/proc/imaginary_friend,
	//client/proc/end_imaginary_friendship
))
