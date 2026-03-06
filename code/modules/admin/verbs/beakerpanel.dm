/proc/reagentsforbeakers()
	//Basic list pulled from random.dm /obj/item/seeds/random/lesser
	var/static/list/reagent_blacklist = typecacheof(list(
		/datum/reagent/aslimetoxin,
		/datum/reagent/drug/blastoff,
		/datum/reagent/drug/demoneye,
		/datum/reagent/drug/twitch,
		/datum/reagent/magillitis,
		/datum/reagent/medicine/antipathogenic/changeling,
		/datum/reagent/medicine/changelinghaste,
		/datum/reagent/medicine/coagulant,
		/datum/reagent/medicine/regen_jelly,
		/datum/reagent/medicine/stimulants,
		/datum/reagent/medicine/syndicate_nanites,
		/datum/reagent/metalgen,
		/datum/reagent/mulligan,
		/datum/reagent/mutationtoxin,
		/datum/reagent/prefactor_a,
		/datum/reagent/prefactor_b,
		/datum/reagent/reaction_agent,
		/datum/reagent/spider_extract,
	))

	var/list/reagent_list = list()
	for(var/reagent_type in subtypesof(/datum/reagent))
		var/datum/reagent/R = reagent_type
		var/reagent_name = initial(R.name)
		// Skip reagents without names or abstract base types
		if(!reagent_name || findtext(reagent_name, "base") || findtext(reagent_name, "template"))
			continue
		// Hard skip admin-only or dangerous reagents if needed, otherwise it's filtered in UI.
		// if(initial(R.admin_only))
		//     continue
		reagent_list += list(list(
			"id" = "[reagent_type]",
			"name" = reagent_name,
			"dangerous" = ((R in reagent_blacklist) || !(R.chemical_flags & REAGENT_CAN_BE_SYNTHESIZED)) ? "TRUE" : "FALSE",
		))
	return reagent_list

/proc/beakersforbeakers()
	var/emptycontainers = list(/obj/item/reagent_containers/cup/beaker,
		/obj/item/reagent_containers/cup/beaker/large,
		/obj/item/reagent_containers/cup/beaker/plastic,
		/obj/item/reagent_containers/cup/beaker/meta,
		/obj/item/reagent_containers/cup/beaker/noreact,
		/obj/item/reagent_containers/cup/beaker/bluespace,
		/obj/item/reagent_containers/cup/glass/drinkingglass)

	var/list/container_list = list()
	for(var/container_type in emptycontainers)
		var/obj/item/reagent_containers/C = container_type
		var/container_name = initial(C.name)
		var/container_volume = initial(C.volume)
		// Skip containers with no name or volume, abstract base types, or any container already filled.
		if(!container_name || !container_volume || findtext(container_name, "base"))
			continue
		// Skip containers that are likely abstract or not meant for spawning
		// You can add specific exclusions here if needed, for example:
		// if(findtext(container_name, "abstract") || findtext(container_name, "template"))
		//     continue
		container_list += list(list(
			"id" = "[container_type]",
			"name" = container_name,
			"volume" = container_volume
		))
	return container_list

ADMIN_VERB(beaker_panel, R_SPAWN, FALSE, "Spawn Reagent Container", "Spawn a reagent container.", ADMIN_CATEGORY_EVENTS)
	var/datum/beaker_panel/tgui = new(user.mob)
	tgui.ui_interact(user.mob)

/datum/beaker_panel
	var/chemstring
	var/mob/user

/datum/beaker_panel/New(mob/target_user)
	user = target_user

/datum/beaker_panel/proc/beaker_panel_create_container(list/containerdata, list/reagent_data, location)
	var/containertype = text2path(containerdata["id"])
	if(isnull(containertype))
		return null
	var/obj/item/reagent_containers/container = new containertype(location)
	var/datum/reagents/reagents = container.reagents
	for(var/datum/reagent/R in reagents.reagent_list) // clear the container of reagents
		reagents.remove_reagent(R.type,R.volume)
	for(var/list/item in reagent_data)
		var/datum/reagent/reagenttype = text2path(item["id"])
		var/amount = text2num(item["amount"])
		if ((reagents.total_volume + amount) > reagents.maximum_volume)
			reagents.maximum_volume = reagents.total_volume + amount
		reagents.add_reagent(reagenttype, amount)
	return container

ADMIN_VERB(beaker_panel, R_SPAWN, "Spawn Reagent Container", "Spawn a reagent container.", ADMIN_CATEGORY_EVENTS)
	var/datum/asset/asset_datum = get_asset_datum(/datum/asset/simple/namespaced/common)
	asset_datum.send(user)
	//Could somebody tell me why this isn't using the browser datum, given that it copypastes all of browser datum's html
	// fuck if I know, but im not touching it TODO check a fix for this.
	var/dat = {"
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
		<html>
			<head>
				<meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
				<meta http-equiv='X-UA-Compatible' content='IE=edge'>
				<link rel='stylesheet' type='text/css' href='[SSassets.transport.get_asset_url("common.css")]'>
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.js"></script>
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.7/js/select2.full.min.js"></script>
				<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.7/css/select2.min.css">
				<script type="text/javascript" src="https://kit.fontawesome.com/8d67455b41.js"></script>
				<style>
					.select2-search { color: #40628a; background-color: #272727; }
					.select2-results { color: #40628a; background-color: #272727; }
					.select2-selection { border-radius: 0px !important; }

			//TODO check if returned gredadetype is a valide type then process chems
			var/reagent_string
			var/list/obj/item/reagent_containers/beakers = list()
			for(var/item in containers_data)
				var/list/container_data = containers_data[item]
				var/list/reagent_data = reagentmatrix_data[item]

				var/obj/item/reagent_containers/new_beaker = beaker_panel_create_container(container_data, reagent_data, null)
				if(!istype(new_beaker))
					continue
				beakers += new_beaker
				reagent_string += " ([new_beaker.name] [text2num(item)] : " + pretty_string_from_reagent_list(new_beaker.reagents.reagent_list) + ");"

			if(!length(beakers))
				return

					.container-control {
					  width: 48%;
					  float: left;
					  padding-right: 10px;
					}
					.reagent > div, .reagent-div {
						float: right;
						width: 200px;
					}
					input.reagent {
					  width: 50%;
					}
					.grenade-data {
					  display: inline-block;
					}
				</style>
				<script>
				window.onload=function(){

					var reagents = [reagentsforbeakers()];

					var containers = [beakersforbeakers()];

					$('select\[name="containertype"\]').select2({
						data: containers,
						escapeMarkup: noEscape,
						templateResult: formatContainer,
						templateSelection: textSelection,
						width: "300px"
						});
					$('.select-new-reagent').select2({
					data: reagents,
					escapeMarkup: noEscape,
					templateResult: formatReagent,
					templateSelection: textSelection
					});

					$('.remove-reagent').click(function() { $(this).parents('li').remove(); });

					$('#spawn-grenade').click(function() {
						var containers = $('div.container-control').map(function() {
					  	  var type = $(this).children('select\[name=containertype\]').select2("data")\[0\].id;
					      var reagents = $(this).find("li.reagent").map(function() {
					        return { "reagent": $(this).data("type"), "volume": $(this).find('input').val()};
					        }).get();
					     return {"container": type, "reagents": reagents };
					  }).get();
						var grenadeType = $('#grenade-type').val()
						var grenadeData = {};
						$('.grenade-data.'+grenadeType).find(':input').each(function() {
							var ret = {};
							grenadeData\[$(this).attr('name')\] = $(this).val();
						});
					  $.ajax({
					      url: '',
					      data: {
									"_src_": "holder",
									"admin_token": "[RawHrefToken()]",
									"beakerpanel": "spawngrenade",
									"containers": JSON.stringify(containers),
									"grenadetype": grenadeType,
									"grenadedata": JSON.stringify(grenadeData)
								}
					    });
					});

					$('.spawn-container').click(function() {
						var container = $(this).parents('div.container-control')\[0\];
					  var type = $(container).children('select\[name=containertype\]').select2("data")\[0\].id;
					  var reagents = $(container).find("li.reagent").map(function() {
					  	return { "reagent": $(this).data("type"), "volume": $(this).find('input').val()};
					    }).get();
					  $.ajax({
					  	url: '',
					    data: {
								"_src_": "holder",
								"admin_token": "[RawHrefToken()]",
								"beakerpanel": "spawncontainer",
								"container": JSON.stringify({"container": type, "reagents": reagents }),

							}
						});
					});

					$('.add-reagent').click(function() {
						var select = $(this).parents('li').children('select').select2("data")\[0\];
					  var amount = $(this).parent().children('input').val();
					  addReagent($(this).parents('ul'), select.id, select.text, amount)
					})

					$('.export-reagents').click(function() {
						var container = $(this).parents('div.container-control')\[0\];
					  var ret = \[\];
					  var reagents = $(container).find("li.reagent").each(function() {
					  	var reagentname = $(this).contents().filter(function(){ return this.nodeType == 3; })\[0\].nodeValue.toLowerCase().replace(/\\W/g, '');
					    ret.push(reagentname+"="+$(this).find('input').val());
					    });
					  prompt("Copy this value", ret.join(';'));

					});

					$('.import-reagents').click(function() {
						var macro = prompt("Enter a chemistry macro", "");
					  var parts = macro.split(';');
					  var container = $(this).parents('div.container-control')\[0\];
					  var ul = $(container).find("ul");

					  $(parts).each(function() {
					  	var reagentArr = this.split('=');
					    var thisReagent = $(reagents).filter(function() { return this.text.toLowerCase().replace(/\\W/g, '') == reagentArr\[0\] })\[0\];
					    addReagent(ul, thisReagent.id, thisReagent.text, reagentArr\[1\]);
					  });

					});

					$('#grenade-type').change(function() {
						$('.grenade-data').hide();
					  $('.grenade-data.'+$(this).val()).show();
					})

					function addReagent(ul, reagentType, reagentName, amount)
					{
						$('<li class="reagent" data-type="'+reagentType+'">'+reagentName+'<div><input class="reagent" value="'+amount+'" />&nbsp;&nbsp;<button class="remove-reagent"><i class="far fa-trash-alt"></i>&nbsp;Remove</button></div></li>').insertBefore($(ul).children('li').last());
					  $(ul).children('li').last().prev().find('button').click(function() { $(this).parents('li').remove(); });
					}

					function textSelection(selection)
					{
					return selection.text;
					}

					function noEscape(markup)
					{
					return markup;
					}

					function formatReagent(result)
					{
					return '<span>'+result.text+'</span><br/><span><small>'+result.id+'</small></span>';
					}

					function formatContainer(result)
					{
					return '<span>'+result.text+" ("+result.volume+'u)</span><br/><span><small>'+result.id+'</small></span>';
					}


			}
			</script>
			</head>
			<body scroll=auto>
				<div class='uiWrapper'>
					<div class='uiTitleWrapper'><div class='uiTitle'><tt>Beaker panel</tt></div></div>
					<div class='uiContent'>

		<div class="width: 100%">
		<button id="spawn-grenade">
		<i class="fas fa-bomb"></i>&nbsp;Spawn grenade
		</button>
			<label for="grenade-type">Grenade type: </label>
		<select id="grenade-type">
			<option value="normal">Normal</option>
		</select>
		<div class="grenade-data normal">
		</div>
			<br />
<small>note: beakers recommended, other containers may have issues</small>
		</div>

	"}
	for (var/i in 1 to 2 )
		dat += {"
			<div class="container-control">
			<h4>
			Container [i]:
			</h4>
			<br />
			<label for="beaker[i]type">Container type</label>
			<select name="containertype" id="beaker[i]type"></select>
			<br />
			<br />
			<div>
			<button class="spawn-container">
			<i class="fas fa-cog"></i>&nbsp;Spawn
				</button>
				&nbsp;&nbsp;&nbsp;
				<button class="import-reagents">
			<i class="fas fa-file-import"></i>&nbsp;Import
				</button>
				&nbsp;&nbsp;&nbsp;
				<button class="export-reagents">
			<i class="fas fa-file-export"></i>&nbsp;Export
				</button>

			</div>
				<ul>
				<li>

					<select class="select-new-reagent"></select><div class="reagent-div"><input style="width: 50%" type="text" name="newreagent" value="40" />&nbsp;&nbsp;<button class="add-reagent">
				<i class="fas fa-plus"></i>&nbsp;Add
				</button>

				</div>
			</li>
			</ul>
			</div>
		"}

	dat += {"
					</div>
				</div>
			</body>
		</html>
	"}

	user << browse(dat, "window=beakerpanel;size=1100x720")
