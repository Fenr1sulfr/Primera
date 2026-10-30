/obj/machinery/storage_pod
	name = "storage pod"
	desc = "A sealed pod that can hold a person safely inside until the door is opened or the pod is destroyed."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "pod_0"
	base_icon_state = "pod"
	density = TRUE
	occupant_typecache = list(/mob/living)
	interaction_flags_mouse_drop = NEED_DEXTERITY

/obj/machinery/storage_pod/Initialize(mapload)
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/machinery/storage_pod/Destroy(force)
	if (occupant)
		occupant.forceMove(drop_location())
		occupant = null
	return ..()

/obj/machinery/storage_pod/update_icon_state()
	icon_state = "[base_icon_state]_[occupant ? 1 : 0]"
	return ..()

/obj/machinery/storage_pod/proc/toggle_open(mob/user)
	if (state_open)
		close_machine()
		return
	open_machine()

/obj/machinery/storage_pod/interact(mob/user)
	toggle_open(user)

/obj/machinery/storage_pod/mouse_drop_receive(atom/target, mob/user, params)
	if (!iscarbon(target))
		return
	close_machine(target)
