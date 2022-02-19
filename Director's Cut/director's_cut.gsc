#include common_scripts/utility;
#include maps/mp/_demo;
#include maps/mp/_utility;
#include maps/mp/_visionset_mgr;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/gametypes_zm/_zm_gametype;
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_ai_basic;
#include maps/mp/zombies/_zm_ai_dogs;
#include maps/mp/zombies/_zm_audio;
#include maps/mp/zombies/_zm_audio_announcer;
#include maps/mp/zombies/_zm_blockers;
#include maps/mp/zombies/_zm_bot;
#include maps/mp/zombies/_zm_buildables;
#include maps/mp/zombies/_zm_clone;
#include maps/mp/zombies/_zm_devgui;
#include maps/mp/zombies/_zm_equipment;
#include maps/mp/zombies/_zm_ffotd;
#include maps/mp/zombies/_zm_game_module;
#include maps/mp/zombies/_zm_gump;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/zombies/_zm_magicbox;
#include maps/mp/zombies/_zm_melee_weapon;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_pers_upgrades;
#include maps/mp/zombies/_zm_pers_upgrades_system;
#include maps/mp/zombies/_zm_pers_upgrades_functions;
#include maps/mp/zombies/_zm_playerhealth;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_power;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zombies/_zm_spawner;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_timer;
#include maps/mp/zombies/_zm_tombstone;
#include maps/mp/zombies/_zm_traps;
#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_zonemgr;

main()
{
	replacefunc(maps/mp/zombies/_zm_perks::solo_revive_buy_trigger_move_trigger, ::solo_revive_buy_trigger_move_trigger);
	replacefunc(maps/mp/zombies/_zm_perks::give_perk, ::give_perk);
}

solo_revive_buy_trigger_move_trigger( revive_perk_trigger )
{
	self endon( "death" );
	revive_perk_trigger setinvisibletoplayer( self );
	if ( level.solo_lives_given >= 6 )
	{
		revive_perk_trigger trigger_off();
		if ( isDefined( level._solo_revive_machine_expire_func ) )
		{
			revive_perk_trigger [[ level._solo_revive_machine_expire_func ]]();
		}
		return;
	}
	while ( self.lives > 0 )
	{
		wait 0.1;
	}
	revive_perk_trigger setvisibletoplayer( self );
}

give_perk( perk, bought )
{
	self setperk( perk );
	self.num_perks++;
	if ( is_true( bought ) )
	{
		self maps/mp/zombies/_zm_audio::playerexert( "burp" );
		if ( is_true( level.remove_perk_vo_delay ) )
		{
			self maps/mp/zombies/_zm_audio::perk_vox( perk );
		}
		else
		{
			self delay_thread( 1.5, ::perk_vox, perk );
		}
		self setblur( 4, 0.1 );
		wait 0.1;
		self setblur( 0, 0.1 );
		self notify( "perk_bought", perk );
	}
	self perk_set_max_health_if_jugg( perk, 1, 0 );
	if ( !is_true( level.disable_deadshot_clientfield ) )
	{
		if ( perk == "specialty_deadshot" )
		{
			self setclientfieldtoplayer( "deadshot_perk", 1 );
		}
		else if ( perk == "specialty_deadshot_upgrade" )
		{
			self setclientfieldtoplayer( "deadshot_perk", 1 );
		}
	}
	if ( perk == "specialty_scavenger" )
	{
		self.hasperkspecialtytombstone = 1;
	}
	players = get_players();
	if ( use_solo_revive() && perk == "specialty_quickrevive" )
	{
		self.lives = 1;
		if ( !isDefined( level.solo_lives_given ) )
		{
			level.solo_lives_given = 0;
		}
		if ( isDefined( level.solo_game_free_player_quickrevive ) )
		{
			level.solo_game_free_player_quickrevive = undefined;
		}
		else
		{
			level.solo_lives_given++;
		}
		if ( level.solo_lives_given >= 6 )
		{
			flag_set( "solo_revive" );
		}
		self thread solo_revive_buy_trigger_move( perk );
	}
	if ( perk == "specialty_finalstand" )
	{
		self.lives = 1;
		self.hasperkspecialtychugabud = 1;
		self notify( "perk_chugabud_activated" );
	}
	if ( isDefined( level._custom_perks[ perk ] ) && isDefined( level._custom_perks[ perk ].player_thread_give ) )
	{
		self thread [[ level._custom_perks[ perk ].player_thread_give ]]();
	}
	self set_perk_clientfield( perk, 1 );
	maps/mp/_demo::bookmark( "zm_player_perk", getTime(), self );
	self maps/mp/zombies/_zm_stats::increment_client_stat( "perks_drank" );
	self maps/mp/zombies/_zm_stats::increment_client_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( perk + "_drank" );
	self maps/mp/zombies/_zm_stats::increment_player_stat( "perks_drank" );
	if ( !isDefined( self.perk_history ) )
	{
		self.perk_history = [];
	}
	self.perk_history = add_to_array( self.perk_history, perk, 0 );
	if ( !isDefined( self.perks_active ) )
	{
		self.perks_active = [];
	}
	self.perks_active[ self.perks_active.size ] = perk;
	self notify( "perk_acquired" );
	self thread perk_think( perk );
}

init()
{
	add_zombie_weapon( "slipgun_zm", "slipgun_upgraded_zm", &"ZOMBIE_WEAPON_SLIPGUN", 10, "slip", "", undefined );
	level.limited_weapons = [];
	level._limited_equipment = [];
	if ( is_classic() )
	{
		level.zombie_include_weapons[ "jetgun_zm" ] = 1;
		level.zombie_weapons[ "jetgun_zm" ].is_in_box = 1;
	}
	level.zombie_include_weapons[ "slipgun_zm" ] = 1;
	level.zombie_include_weapons[ "staff_air_zm" ] = 1;
	level.zombie_include_weapons[ "staff_fire_zm" ] = 1;
	level.zombie_include_weapons[ "staff_lightning_zm" ] = 1;
	level.zombie_include_weapons[ "staff_water_zm" ] = 1;
	level.zombie_weapons[ "slipgun_zm" ].is_in_box = 1;
	level.zombie_weapons[ "staff_air_zm" ].is_in_box = 1;
	level.zombie_weapons[ "staff_fire_zm" ].is_in_box = 1;
	level.zombie_weapons[ "staff_lightning_zm" ].is_in_box = 1;
	level.zombie_weapons[ "staff_water_zm" ].is_in_box = 1;
	level.perk_purchase_limit = 9;
	level.player_starting_points = 25000;
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");
	self.director_spawn = 1;
	for(;;)
	{
		self waittill("spawned_player");
		wait_network_frame();
		self dc_give_player_all_perks();
		if (self.director_spawn == 1)
		{
			self.director_spawn = 0;
			self thread watch_for_respawn();
			self thread upgrade_box();
		}
	}
}

dc_give_player_all_perks()
{
	flag_wait( "initial_blackscreen_passed" );
	wait_network_frame();
	machines = getentarray( "zombie_vending", "targetname" );
	perks = [];
	i = 0;
	while ( i < machines.size )
	{
		if ( machines[ i ].script_noteworthy == "specialty_weapupgrade" )
		{
			i++;
			continue;
		}
		perks[ perks.size ] = machines[ i ].script_noteworthy;
		i++;
	}
	foreach ( perk in perks )
	{
		if ( isDefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
		}
		else
		{
			if ( self hasperk( perk ) || self maps/mp/zombies/_zm_perks::has_perk_paused( perk ) )
			{
			}
			else
			{
				self maps/mp/zombies/_zm_perks::give_perk( perk, 0 );
				wait 0.25;
			}
		}
	}
	if ( level.script == "zm_tomb" )
	{
		self maps/mp/zombies/_zm_perks::give_perk( "specialty_rof", 0 );
		wait 0.25;
		self maps/mp/zombies/_zm_perks::give_perk( "specialty_deadshot", 0 );
		wait 0.25;
		self maps/mp/zombies/_zm_perks::give_perk( "specialty_flakjacket", 0 );
		wait 0.25;
		self maps/mp/zombies/_zm_perks::give_perk( "specialty_grenadepulldeath", 0 );
	}
	self._retain_perks = 1;
}

watch_for_respawn()
{
	self endon( "disconnect" );
	for(;;)
	{
		self waittill_either( "spawned_player", "player_revived" );
		wait_network_frame();
		if ( level.script == "zm_prison" )
		{
			self dc_give_player_all_perks();
		}
		self setmaxhealth( level.zombie_vars[ "zombie_perk_juggernaut_health" ] );
	}
}

upgrade_box()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill("user_grabbed_weapon");
		wait 0.05;
		self waittill ("weapon_change");
		wait 0.05;
		weap = maps/mp/zombies/_zm_weapons::get_base_name(self getcurrentweapon());
		weapon = get_upgrade(weap);
		if(isdefined(weapon))
		{
			self takeweapon(weap);
			self giveweapon(weapon, 0, self maps/mp/zombies/_zm_weapons::get_pack_a_punch_weapon_options(weapon));
			self givestartammo(weapon);
			self switchtoweapon(weapon);
		}
	}
}

get_upgrade(weaponname)
{
	if(isdefined(level.zombie_weapons[weaponname]) && isdefined(level.zombie_weapons[weaponname].upgrade_name))
	{
		return maps/mp/zombies/_zm_weapons::get_upgrade_weapon(weaponname, 0);
	}
	else
	{
		return maps/mp/zombies/_zm_weapons::get_upgrade_weapon(weaponname, 1);
	}
}
