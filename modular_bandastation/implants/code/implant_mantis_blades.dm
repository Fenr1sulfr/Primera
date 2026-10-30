/obj/item/mantis_blades
	parent_type = /obj/item/melee
	name = "mantis blade"
	desc = "A retractable blade built into a cybernetic wrist housing."
	icon = 'modular_bandastation/implants/icons/mantis_blade.dmi'
	icon_state = "syndie_mantis"
	inhand_icon_state = "syndie_mantis"
	lefthand_file = 'modular_bandastation/implants/icons/mantis_blade_lefthand.dmi'
	righthand_file = 'modular_bandastation/implants/icons/mantis_blade_righthand.dmi'
	force = 25
	throwforce = 20
	armour_penetration = 40
	sharpness = SHARP_EDGED
	item_flags = NEEDS_PERMIT
	attack_verb_continuous = list("slashes", "stabs", "cuts")
	attack_verb_simple = list("slash", "stab", "cut")
	hitsound = 'sound/items/weapons/bladeslice.ogg'

	var/attack_in_progress = FALSE
	var/pending_dual_attack = FALSE
	var/is_cleaving = FALSE
	var/next_lunge_time = 0

/obj/item/mantis_blades/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, HAND_REPLACEMENT_TRAIT)

/obj/item/mantis_blades/equipped(mob/living/user, slot, initial = FALSE)
	. = ..()
	var/held_index = user.get_held_index_of_item(src)
	if(held_index && IS_RIGHT_INDEX(held_index))
		transform = matrix(-1, 0, 0, 0, 1, 0)
	else
		transform = null

/obj/item/mantis_blades/attack(mob/living/target, mob/living/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(. || attack_in_progress || !user.combat_mode || HAS_TRAIT(user, TRAIT_PACIFISM))
		return .

	var/obj/item/mantis_blades/offhand_blade = user.get_inactive_held_item()
	if(!istype(offhand_blade) || offhand_blade.pending_dual_attack)
		return .

	offhand_blade.pending_dual_attack = TRUE
	addtimer(CALLBACK(offhand_blade, PROC_REF(perform_followup_attack), user, target, modifiers, TRUE), 0.2 SECONDS)

/obj/item/mantis_blades/proc/perform_followup_attack(mob/living/user, atom/target, list/modifiers, required_combat_mode)
	if(QDELETED(src))
		return
	pending_dual_attack = FALSE
	if(QDELETED(user) || QDELETED(target) || !user.is_holding(src) || !user.Adjacent(target) || user.combat_mode != required_combat_mode || user.incapacitated || HAS_TRAIT(user, TRAIT_PACIFISM))
		return

	attack_in_progress = TRUE
	melee_attack_chain(user, target, modifiers)
	attack_in_progress = FALSE

/obj/item/mantis_blades/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(prob(25))
		do_sparks(rand(1, 6), TRUE, loc)

	var/mob/living/living_user = user
	if(!living_user || is_cleaving || !living_user.combat_mode || HAS_TRAIT(living_user, TRAIT_PACIFISM) || !living_user.Adjacent(target))
		return

	var/obj/item/mantis_blades/offhand_blade = living_user.get_inactive_held_item()
	if(!istype(offhand_blade))
		return

	var/turf/user_turf = get_turf(user)
	var/turf/center_turf = get_turf_in_angle(get_angle(user, target), user_turf, 1)
	if(!center_turf)
		return

	var/facing_dir = get_dir(user, center_turf)
	var/held_index = user.get_held_index_of_item(src)
	var/swing_direction = IS_RIGHT_INDEX(held_index) ? 1 : -1
	var/list/swing_turfs = list()
	for(var/offset in -2 to 2)
		var/turf/swing_turf = get_step(user_turf, turn(facing_dir, offset * 45 * swing_direction))
		if(swing_turf && !(swing_turf in swing_turfs))
			swing_turfs += swing_turf

	is_cleaving = TRUE
	playsound(src, 'sound/items/weapons/bladeslice.ogg', 40, FALSE)
	for(var/turf/swing_turf as anything in swing_turfs)
		for(var/atom/movable/hit_atom as anything in swing_turf)
			if(hit_atom == user || hit_atom == target || !user.Adjacent(hit_atom) || (hit_atom.pass_flags & LETPASSTHROW))
				continue
			if(isliving(hit_atom) && HAS_TRAIT(hit_atom, TRAIT_DWARF))
				continue
			if(!hit_atom.density)
				continue
			melee_attack_chain(user, hit_atom, modifiers)
	is_cleaving = FALSE
	user.do_attack_animation(center_turf, no_effect = TRUE)
	user.changeNext_move(attack_speed * 1.5)

/obj/item/mantis_blades/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return ITEM_INTERACT_BLOCKING

/obj/item/mantis_blades/ranged_interact_with_atom_secondary(atom/interacting_with, mob/living/user, list/modifiers)
	if(user.incapacitated || !user.is_holding(src) || user.Adjacent(interacting_with) || world.time < next_lunge_time)
		return ITEM_INTERACT_BLOCKING

	var/obj/item/mantis_blades/offhand_blade = user.get_inactive_held_item()
	if(!istype(offhand_blade))
		return ITEM_INTERACT_BLOCKING

	if(!user.throw_at(interacting_with, 4, 1.4, src, spin = FALSE, callback = CALLBACK(src, PROC_REF(finish_lunge), user, interacting_with, modifiers, user.combat_mode)))
		return ITEM_INTERACT_BLOCKING

	next_lunge_time = world.time + 6 SECONDS
	offhand_blade.next_lunge_time = next_lunge_time
	return ITEM_INTERACT_SUCCESS

/obj/item/mantis_blades/proc/finish_lunge(mob/living/user, atom/target, list/modifiers, required_combat_mode)
	if(QDELETED(src) || QDELETED(user) || QDELETED(target) || !user.is_holding(src) || !user.Adjacent(target) || user.combat_mode != required_combat_mode || user.incapacitated || HAS_TRAIT(user, TRAIT_PACIFISM))
		return

	melee_attack_chain(user, target, modifiers)
	var/obj/item/mantis_blades/offhand_blade = user.get_inactive_held_item()
	if(!istype(offhand_blade) || offhand_blade.pending_dual_attack)
		return

	offhand_blade.pending_dual_attack = TRUE
	addtimer(CALLBACK(offhand_blade, PROC_REF(perform_followup_attack), user, target, modifiers, required_combat_mode), 0.2 SECONDS)

/obj/item/organ/cyberimp/arm/mantis_blades
	name = "имплант клинка богомола"
	desc = "Встраиваемый в руку выдвижной клинок."
	icon = 'modular_bandastation/implants/icons/mantis_blade.dmi'
	icon_state = "syndie_mantis"
	actions_types = list(/datum/action/item_action/organ_action/mantis_blades)

	var/obj/item/mantis_blades/blade

/obj/item/organ/cyberimp/arm/mantis_blades/Initialize(mapload)
	. = ..()
	blade = new(src)

/obj/item/organ/cyberimp/arm/mantis_blades/on_mob_insert(mob/living/carbon/arm_owner, special = FALSE, movement_flags)
	. = ..()
	RegisterSignal(arm_owner, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(parry))
	RegisterSignal(arm_owner, COMSIG_KB_MOB_DROPITEM_DOWN, PROC_REF(dropkey))
	update_action_visibility(arm_owner)

/obj/item/organ/cyberimp/arm/mantis_blades/on_mob_remove(mob/living/carbon/arm_owner, special = FALSE, movement_flags)
	if(arm_owner)
		UnregisterSignal(arm_owner, list(COMSIG_LIVING_CHECK_BLOCK, COMSIG_KB_MOB_DROPITEM_DOWN))
		if(blade && blade.loc == arm_owner)
			arm_owner.transferItemToLoc(blade, src, force = TRUE)
	if(blade)
		blade.resistance_flags = blade::resistance_flags
	. = ..()
	if(arm_owner)
		update_action_visibility(arm_owner)

/obj/item/organ/cyberimp/arm/mantis_blades/proc/update_action_visibility(mob/living/carbon/arm_owner)
	if(!arm_owner)
		return

	var/obj/item/organ/cyberimp/arm/mantis_blades/right_blades = arm_owner.get_organ_slot(ORGAN_SLOT_RIGHT_ARM_AUG)
	var/obj/item/organ/cyberimp/arm/mantis_blades/left_blades = arm_owner.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG)
	if(right_blades?.cybernetic_rejection)
		right_blades = null
	if(left_blades?.cybernetic_rejection)
		left_blades = null

	var/obj/item/organ/cyberimp/arm/mantis_blades/preferred_implant = right_blades || left_blades
	for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in list(right_blades, left_blades))
		if(!implant)
			continue
		for(var/datum/action/item_action/organ_action/mantis_blades/action as anything in implant.actions)
			if(implant == preferred_implant)
				action.GiveAction(arm_owner)
			else
				action.HideFrom(arm_owner)

/obj/item/organ/cyberimp/arm/mantis_blades/Destroy()
	if(blade)
		if(blade.loc == src)
			QDEL_NULL(blade)
		else
			blade = null
	return ..()

/obj/item/organ/cyberimp/arm/mantis_blades/proc/toggle_blade()
	if(!owner || QDELETED(blade))
		return FALSE

	if(blade.loc == src)
		var/hand_side = zone == BODY_ZONE_R_ARM ? RIGHT_HANDS : LEFT_HANDS
		var/hand_index = owner.get_empty_held_index_for_side(hand_side)
		if(!hand_index || !owner.put_in_hand(blade, hand_index))
			to_chat(owner, span_warning("Ваша рука занята, чтобы выдвинуть клинок."))
			return FALSE

		blade.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
		to_chat(owner, span_notice("Вы выдвигаете клинок из запястья."))
		return TRUE

	if(blade.loc != owner || !owner.get_held_index_of_item(blade))
		to_chat(owner, span_warning("Вы должны держать клинок, чтобы убрать его."))
		return FALSE

	if(!owner.transferItemToLoc(blade, src, force = TRUE))
		to_chat(owner, span_warning("Не удалось убрать клинок."))
		return FALSE

	blade.resistance_flags = blade::resistance_flags
	to_chat(owner, span_notice("Вы убираете клинок в запястье."))
	return TRUE

/obj/item/organ/cyberimp/arm/mantis_blades/proc/toggle_all_blades()
	if(!owner)
		return FALSE

	var/list/blade_implants = list()
	var/obj/item/organ/cyberimp/arm/mantis_blades/right_blades = owner.get_organ_slot(ORGAN_SLOT_RIGHT_ARM_AUG)
	var/obj/item/organ/cyberimp/arm/mantis_blades/left_blades = owner.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG)
	if(right_blades && !right_blades.cybernetic_rejection)
		blade_implants += right_blades
	if(left_blades && !left_blades.cybernetic_rejection)
		blade_implants += left_blades
	if(!length(blade_implants))
		return FALSE

	var/should_extend = FALSE
	for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in blade_implants)
		if(implant.blade?.loc == implant)
			should_extend = TRUE
			break

	if(should_extend)
		for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in blade_implants)
			if(implant.blade?.loc != implant)
				continue
			var/hand_side = implant.zone == BODY_ZONE_R_ARM ? RIGHT_HANDS : LEFT_HANDS
			var/hand_index = owner.get_empty_held_index_for_side(hand_side)
			if(!hand_index || !owner.can_put_in_hand(implant.blade, hand_index))
				to_chat(owner, span_warning("Ваша рука занята, чтобы выдвинуть оба клинка."))
				return FALSE

		for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in blade_implants)
			if(implant.blade?.loc == implant)
				implant.toggle_blade()
		return TRUE

	var/any_retracted = FALSE
	for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in blade_implants)
		if(implant.blade?.loc == owner && owner.get_held_index_of_item(implant.blade))
			any_retracted = TRUE
			break
	if(!any_retracted)
		return FALSE

	for(var/obj/item/organ/cyberimp/arm/mantis_blades/implant as anything in blade_implants)
		if(implant.blade?.loc == owner && owner.get_held_index_of_item(implant.blade))
			implant.toggle_blade()
	return TRUE

/obj/item/organ/cyberimp/arm/mantis_blades/proc/dropkey(mob/living/carbon/host)
	SIGNAL_HANDLER
	if(!host || hand != host.hand_bodyparts[host.active_hand_index])
		return
	if(toggle_blade())
		return COMSIG_KB_ACTIVATED

/obj/item/organ/cyberimp/arm/mantis_blades/proc/parry(mob/living/victim, atom/movable/hit_by, damage, attack_text, attack_type, ...)
	SIGNAL_HANDLER
	if(victim != owner || attack_type != MELEE_ATTACK || !isitem(hit_by))
		return NONE

	var/obj/item/weapon = hit_by
	if((weapon.item_flags & NOBLUDGEON) || weapon.force <= 0)
		return NONE

	var/obj/item/organ/right_arm_augment = victim.get_organ_slot(ORGAN_SLOT_RIGHT_ARM_AUG)
	var/obj/item/organ/left_arm_augment = victim.get_organ_slot(ORGAN_SLOT_LEFT_ARM_AUG)
	var/obj/item/organ/cyberimp/arm/mantis_blades/right_blades
	var/obj/item/organ/cyberimp/arm/mantis_blades/left_blades
	if(istype(right_arm_augment, /obj/item/organ/cyberimp/arm/mantis_blades))
		right_blades = right_arm_augment
	if(istype(left_arm_augment, /obj/item/organ/cyberimp/arm/mantis_blades))
		left_blades = left_arm_augment
	if(right_blades && !right_blades.cybernetic_rejection)
		if(right_blades != src)
			return NONE
	else if(left_blades != src)
		return NONE

	var/parry_chance = right_blades && left_blades && !right_blades.cybernetic_rejection && !left_blades.cybernetic_rejection ? 75 : 35
	if(prob(parry_chance))
		return SUCCESSFUL_BLOCK

	return NONE

/datum/action/item_action/organ_action/mantis_blades
	name = "Выдвинуть клинок богомола"
	desc = "Выдвинуть или убрать клинок в установленной руке."
	button_icon = 'modular_bandastation/implants/icons/mantis_blade.dmi'
	button_icon_state = "syndie_mantis"

/datum/action/item_action/organ_action/mantis_blades/do_effect(trigger_flags)
	var/obj/item/organ/cyberimp/arm/mantis_blades/implant = target
	return implant.toggle_all_blades()
