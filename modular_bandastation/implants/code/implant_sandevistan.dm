/obj/item/organ/cyberimp/chest/sandevistan
	name = "имплант «Сандевистан»"
	desc = "Нейроускоритель, который на короткое время ускоряет носителя и защищает от атак."
	icon = 'modular_bandastation/implants/icons/implant_sandevistan.dmi'
	icon_state = "sandevistan"
	actions_types = list(
		/datum/action/item_action/hands_free/sandevistan,
		/datum/action/item_action/organ_action/toggle/sandevistan_overload,
	)
	slot = "sandevistan"

	var/active = FALSE
	var/teleport_used = FALSE
	var/overload = FALSE
	var/overload_saved_cooldown = 0
	var/timer_id

/obj/item/organ/cyberimp/chest/sandevistan/proc/activate()
	if(!owner || active)
		return FALSE

	active = TRUE
	teleport_used = FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/sandevistan, update = TRUE)
	RegisterSignal(owner, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(block_attack))
	RegisterSignal(owner, COMSIG_PROJECTILE_PREHIT, PROC_REF(block_projectile))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_item_attack))
	RegisterSignal(owner, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_hand_attack))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(create_afterimage))
	timer_id = addtimer(CALLBACK(src, PROC_REF(deactivate)), 10 SECONDS, TIMER_STOPPABLE)
	to_chat(owner, span_notice("Сандевистан активирован."))
	if(overload)
		owner.adjust_organ_loss(ORGAN_SLOT_BRAIN, 10)
		to_chat(owner, span_warning("Перегрузка Сандевистана повреждает ваш мозг!"))
	return TRUE

/obj/item/organ/cyberimp/chest/sandevistan/proc/deactivate()
	if(!active)
		return

	active = FALSE
	if(owner && !QDELETED(owner))
		UnregisterSignal(owner, list(
			COMSIG_LIVING_CHECK_BLOCK,
			COMSIG_PROJECTILE_PREHIT,
			COMSIG_ATOM_ATTACKBY,
			COMSIG_ATOM_ATTACK_HAND,
			COMSIG_MOVABLE_MOVED,
		))
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/sandevistan, update = TRUE)
		to_chat(owner, span_notice("Сандевистан отключен."))

	if(timer_id)
		deltimer(timer_id)
	timer_id = null

/obj/item/organ/cyberimp/chest/sandevistan/on_mob_remove(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	deactivate()
	return ..()

/obj/item/organ/cyberimp/chest/sandevistan/proc/toggle_overload()
	if(!owner)
		return FALSE

	overload = !overload
	for(var/datum/action/item_action/hands_free/sandevistan/action in owner.actions)
		if(action.target != src)
			continue
		if(overload)
			overload_saved_cooldown = action.next_use_time
			action.ResetCooldown()
		else
			action.next_use_time = max(world.time, overload_saved_cooldown)
			action.build_all_button_icons(UPDATE_BUTTON_STATUS)
			overload_saved_cooldown = 0

	to_chat(owner, span_warning("Перегрузка Сандевистана [overload ? "включена" : "отключена"]."))
	return TRUE

/obj/item/organ/cyberimp/chest/sandevistan/proc/block_attack(
	mob/living/victim,
	atom/hit_by,
	damage,
	attack_text,
	attack_type,
	armour_penetration,
	damage_type,
	attack_flag,
)
	SIGNAL_HANDLER
	if(!active || victim != owner)
		return NONE

	if(attack_type == MELEE_ATTACK || attack_type == UNARMED_ATTACK || attack_type == PROJECTILE_ATTACK || attack_type == THROWN_PROJECTILE_ATTACK)
		return SUCCESSFUL_BLOCK

	return NONE

/obj/item/organ/cyberimp/chest/sandevistan/proc/on_item_attack(mob/living/victim, obj/item/weapon, mob/living/attacker, list/modifiers, list/attack_modifiers)
	SIGNAL_HANDLER
	if(!active || victim != owner || !attacker || attacker == victim)
		return
	if((weapon.item_flags & NOBLUDGEON) || CALCULATE_FORCE(weapon, attack_modifiers) <= 0)
		return

	trigger_counter_teleport(attacker)

/obj/item/organ/cyberimp/chest/sandevistan/proc/on_hand_attack(mob/living/victim, mob/living/attacker, list/modifiers)
	SIGNAL_HANDLER
	if(!active || victim != owner || !attacker || attacker == victim || !attacker.combat_mode)
		return

	trigger_counter_teleport(attacker)

/obj/item/organ/cyberimp/chest/sandevistan/proc/block_projectile(mob/living/victim, obj/projectile/projectile)
	SIGNAL_HANDLER
	if(!active || victim != owner)
		return NONE

	if(owner.throw_mode == THROW_MODE_HOLD && isliving(projectile.firer))
		var/mob/living/attacker = projectile.firer
		trigger_counter_teleport(attacker)

	return PROJECTILE_INTERRUPT_HIT

/obj/item/organ/cyberimp/chest/sandevistan/proc/trigger_counter_teleport(mob/living/attacker)
	if(!active || teleport_used || owner.throw_mode != THROW_MODE_HOLD || !attacker || QDELETED(attacker) || attacker == owner || attacker.stat == DEAD)
		return FALSE

	var/turf/start_turf = get_turf(owner)
	var/turf/attacker_turf = get_turf(attacker)
	if(!start_turf || !attacker_turf || start_turf.z != attacker_turf.z)
		return FALSE

	var/behind_direction = turn(get_dir(attacker, owner), 180)
	for(var/direction in list(behind_direction, turn(behind_direction, -45), turn(behind_direction, 45)))
		var/turf/destination = get_step(attacker, direction)
		if(!destination || destination.is_blocked_turf_ignore_climbable())
			continue
		if(!do_teleport(owner, destination, no_effects = TRUE, channel = TELEPORT_CHANNEL_FREE))
			continue

		teleport_used = TRUE
		owner.setDir(get_dir(owner, attacker))
		create_teleport_afterimages(start_turf, destination)
		return TRUE

	return FALSE

/obj/item/organ/cyberimp/chest/sandevistan/proc/create_teleport_afterimages(turf/start_turf, turf/destination)
	var/list/turf/path = get_line(start_turf, destination)
	if(length(path) <= 2)
		return

	var/step_size = max(1, CEILING((length(path) - 1) / 8, 1))
	for(var/index in 2 to (length(path) - 1))
		if((index - 2) % step_size)
			continue
		spawn_afterimage(path[index])

/obj/item/organ/cyberimp/chest/sandevistan/proc/create_afterimage(mob/living/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!active || source != owner)
		return

	var/turf/old_turf = get_turf(old_loc)
	if(!old_turf)
		return

	spawn_afterimage(old_turf)

/obj/item/organ/cyberimp/chest/sandevistan/proc/spawn_afterimage(turf/location)
	var/obj/effect/temp_visual/decoy/fading/sandevistan/afterimage = new(location, owner, 180)
	afterimage.color = pick("#00ffff", "#ff00ff", "#ffff00")

/datum/movespeed_modifier/sandevistan
	multiplicative_slowdown = -0.75

/obj/effect/temp_visual/decoy/fading/sandevistan
	duration = 4
	randomdir = FALSE

/datum/action/item_action/hands_free/sandevistan
	parent_type = /datum/action/cooldown
	name = "Активировать Сандевистан"
	desc = "На 10 секунд ускоряет вас и блокирует атаки. Удерживайте режим броска, чтобы телепортироваться за спину первого нападающего. Обычная перезарядка — 20 секунд."
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 20 SECONDS
	button_icon = 'modular_bandastation/implants/icons/implant_sandevistan.dmi'
	button_icon_state = "sandevistan"

/datum/action/item_action/hands_free/sandevistan/Activate(atom/target)
	var/obj/item/organ/cyberimp/chest/sandevistan/implant = src.target
	if(!implant || !implant.activate())
		return FALSE

	if(!implant.overload)
		StartCooldown()
	return TRUE

/datum/action/item_action/organ_action/toggle/sandevistan_overload
	desc = "Позволяет активировать Сандевистан без перезарядки, но наносит урон мозгу при каждом включении."
	button_icon = 'modular_bandastation/implants/icons/implant_sandevistan.dmi'
	button_icon_state = "sandevistan"

/datum/action/item_action/organ_action/toggle/sandevistan_overload/New(Target)
	. = ..()
	name = "Переключить перегрузку Сандевистана"

/datum/action/item_action/organ_action/toggle/sandevistan_overload/do_effect(trigger_flags)
	var/obj/item/organ/cyberimp/chest/sandevistan/implant = target
	return implant.toggle_overload()
