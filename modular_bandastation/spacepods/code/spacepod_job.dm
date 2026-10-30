/datum/job/spacepod_technician
	title = JOB_SPACEPOD_TECHNICIAN
	alternate_titles = list(JOB_SPACEPOD_TECHNICIAN_RU)
	description = "Собирайте, ремонтируйте и оснащайте космические поды. Обслуживайте их двигатели, броню и оборудование."
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = JOB_CHIEF_ENGINEER_RU
	exp_requirements = 60
	exp_required_type = EXP_TYPE_CREW
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "SPACEPOD_TECHNICIAN"
	departments_list = list(/datum/job_department/engineering)
	outfit = /datum/outfit/job/spacepod_technician
	plasmaman_outfit = /datum/outfit/plasmaman/engineering
	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_ENG
	display_order = JOB_DISPLAY_ORDER_SPACEPOD_TECHNICIAN
	job_flags = STATION_JOB_FLAGS
	tgui_icon = FA_ICON_GEARS
	rpg_title = "Shipwright"
	family_heirlooms = list(/obj/item/wrench)

// shortcut: reuse engineering spawns until station maps include dedicated pod workshop landmarks.
/datum/job/spacepod_technician/get_default_roundstart_spawn_point()
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.name == title)
			return ..()

	var/datum/job/station_engineer/fallback_job = SSjob.get_job_type(/datum/job/station_engineer)
	if(fallback_job)
		return fallback_job.get_default_roundstart_spawn_point()
	return ..()

/datum/outfit/job/spacepod_technician
	name = JOB_SPACEPOD_TECHNICIAN
	jobtype = /datum/job/spacepod_technician
	id_trim = /datum/id_trim/job/spacepod_technician
	uniform = /obj/item/clothing/under/rank/engineering/engineer
	belt = /obj/item/storage/belt/utility/full
	shoes = /obj/item/clothing/shoes/workboots
	head = /obj/item/clothing/head/utility/hardhat
	// AI EDIT START - Use the right ear slot for existing equipment
	ear_right = /obj/item/radio/headset/headset_eng
	// AI EDIT END
	l_pocket = /obj/item/modular_computer/pda/crew/engineering
	r_pocket = /obj/item/t_scanner
	glasses = /obj/item/clothing/glasses/meson
	backpack = /obj/item/storage/backpack/industrial
	satchel = /obj/item/storage/backpack/satchel/eng
	duffelbag = /obj/item/storage/backpack/duffelbag/engineering
	messenger = /obj/item/storage/backpack/messenger/eng
	box = /obj/item/storage/box/survival/engineer
	backpack_contents = list(
		/obj/item/pod_paint_bucket = 1,
		/obj/item/spacepod_equipment/key = 1,
	)
	pda_slot = ITEM_SLOT_LPOCKET
	wintercoat = /obj/item/clothing/suit/hooded/wintercoat/engineering

/datum/id_trim/job/spacepod_technician
	assignment = JOB_SPACEPOD_TECHNICIAN_RU
	trim_state = "trim_stationengineer"
	department_color = COLOR_ENGINEERING_ORANGE
	subdepartment_color = COLOR_ENGINEERING_ORANGE
	sechud_icon_state = SECHUD_STATION_ENGINEER
	minimal_access = list(
		ACCESS_ENGINEERING,
		ACCESS_ENGINE_EQUIP,
		ACCESS_CONSTRUCTION,
		ACCESS_TECH_STORAGE,
		ACCESS_MINERAL_STOREROOM,
		ACCESS_EXTERNAL_AIRLOCKS,
		ACCESS_EVA,
	)
	template_access = list(
		ACCESS_CAPTAIN,
		ACCESS_CHANGE_IDS,
		ACCESS_CE,
	)
	job = /datum/job/spacepod_technician

/obj/effect/landmark/start/spacepod_technician
	name = JOB_SPACEPOD_TECHNICIAN
	icon_state = JOB_STATION_ENGINEER
