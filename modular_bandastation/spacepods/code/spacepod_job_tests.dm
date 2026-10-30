/// The role must participate in engineering job assignment and keep its translated title.
/datum/unit_test/spacepod_job_engineering/Run()
	var/datum/job/spacepod_technician/job = SSjob.get_job_type(/datum/job/spacepod_technician)
	TEST_ASSERT_NOTNULL(job, "Spacepod Technician was not registered with SSjob.")
	TEST_ASSERT(job in SSjob.joinable_occupations, "Spacepod Technician cannot be selected by players.")
	TEST_ASSERT_EQUAL(job.title, "Spacepod Technician", "Spacepod Technician has an incompatible job title.")
	TEST_ASSERT_EQUAL(initial(job.total_positions), 1, "Spacepod Technician must default to one total position.")
	TEST_ASSERT_EQUAL(initial(job.spawn_positions), 1, "Spacepod Technician must default to one roundstart position.")
	TEST_ASSERT_EQUAL(job_title_ru(job.title), "Челнок-инженер", "Spacepod Technician lost its Russian display title.")
	TEST_ASSERT(/datum/job_department/engineering in job.departments_list, "Spacepod Technician is missing the engineering department.")
	TEST_ASSERT(!(job.departments_bitflags & DEPARTMENT_BITFLAG_SCIENCE), "Spacepod Technician still belongs to science.")
	TEST_ASSERT(job.departments_bitflags & DEPARTMENT_BITFLAG_ENGINEERING, "Spacepod Technician did not receive engineering department flags.")
	TEST_ASSERT_EQUAL(job.supervisors, JOB_CHIEF_ENGINEER_RU, "Spacepod Technician does not report to the Chief Engineer.")
	TEST_ASSERT_EQUAL(job.paycheck_department, ACCOUNT_ENG, "Spacepod Technician is paid from the wrong department account.")

/// Exercise real outfit equipment and the engineering pod fabricator's access check.
/datum/unit_test/spacepod_job_equipment/Run()
	var/datum/job/spacepod_technician/job = SSjob.get_job_type(/datum/job/spacepod_technician)
	TEST_ASSERT_NOTNULL(job, "Spacepod Technician was not registered with SSjob.")
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human/consistent)
	human.mind_initialize()
	human.mind.set_assigned_role(job)
	human.dress_up_as_job(job, consistent = TRUE)
	var/obj/item/card/id/card = human.wear_id
	TEST_ASSERT_NOTNULL(card, "Spacepod Technician did not receive an ID card.")
	TEST_ASSERT_EQUAL(card.assignment, JOB_SPACEPOD_TECHNICIAN_RU, "Spacepod Technician's ID has the wrong assignment.")
	var/list/card_access = card.GetAccess()
	for(var/required_access in list(ACCESS_ENGINEERING, ACCESS_ENGINE_EQUIP, ACCESS_CONSTRUCTION, ACCESS_TECH_STORAGE, ACCESS_EXTERNAL_AIRLOCKS, ACCESS_EVA))
		TEST_ASSERT(required_access in card_access, "Spacepod Technician's ID is missing [required_access].")
	TEST_ASSERT(!(ACCESS_SCIENCE in card_access), "Spacepod Technician unexpectedly received general science access.")
	TEST_ASSERT(!(ACCESS_RESEARCH in card_access), "Spacepod Technician unexpectedly received research access.")
	TEST_ASSERT(!(ACCESS_ROBOTICS in card_access), "Spacepod Technician unexpectedly received robotics access.")
	var/obj/machinery/mecha_part_fabricator/spacepod/fabricator = allocate(__IMPLIED_TYPE__)
	TEST_ASSERT(fabricator.allowed(human), "Spacepod Technician cannot use the engineering pod fabricator.")
	// AI EDIT START - Use the right ear slot for existing equipment
	TEST_ASSERT(istype(human.ear_right, /obj/item/radio/headset/headset_eng), "Spacepod Technician did not receive an engineering headset.")
	// AI EDIT END
	var/obj/item/storage/backpack/backpack = human.back
	TEST_ASSERT(istype(backpack), "Spacepod Technician did not receive a backpack.")
	TEST_ASSERT(locate(/obj/item/pod_paint_bucket) in backpack, "Spacepod Technician's backpack has no pod paint bucket.")
	TEST_ASSERT(locate(/obj/item/spacepod_equipment/key) in backpack, "Spacepod Technician's backpack has no pod key.")

/// Existing maps need a real engineer spawn, while dedicated workshops must take precedence.
/datum/unit_test/spacepod_job_spawn/Run()
	var/datum/job/spacepod_technician/job = SSjob.get_job_type(/datum/job/spacepod_technician)
	TEST_ASSERT_NOTNULL(job, "Spacepod Technician was not registered with SSjob.")
	var/obj/effect/landmark/start/station_engineer/engineering_spawn = allocate(/obj/effect/landmark/start/station_engineer)
	var/obj/effect/landmark/start/spacepod_technician/workshop_spawn = allocate(/obj/effect/landmark/start/spacepod_technician)
	var/list/original_landmarks = GLOB.start_landmarks_list
	// Isolate station landmarks without consuming the actual station's spawn positions.
	GLOB.start_landmarks_list = list(engineering_spawn)
	var/atom/fallback_spawn = job.get_default_roundstart_spawn_point()
	GLOB.start_landmarks_list = list(engineering_spawn, workshop_spawn)
	var/atom/preferred_spawn = job.get_default_roundstart_spawn_point()
	GLOB.start_landmarks_list = original_landmarks
	TEST_ASSERT_EQUAL(fallback_spawn, engineering_spawn, "Spacepod Technician did not use the engineering fallback spawn.")
	TEST_ASSERT(engineering_spawn.used, "Engineering fallback did not reserve its chosen spawn.")
	TEST_ASSERT_EQUAL(preferred_spawn, workshop_spawn, "Spacepod Technician ignored its dedicated workshop spawn.")
	TEST_ASSERT(workshop_spawn.used, "Dedicated workshop spawn was not reserved.")
