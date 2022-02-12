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
	replacefunc(maps/mp/zombies/_zm::ai_calculate_health, ::ai_calculate_health);
	replacefunc(maps/mp/zombies/_zm_perks::use_solo_revive, ::use_solo_revive);
	replacefunc(maps/mp/zombies/_zm_spawner::should_attack_player_thru_boards, ::should_attack_player_thru_boards);
	replacefunc(maps/mp/zombies/_zm_utility::init_zombie_run_cycle, ::init_zombie_run_cycle);
}

ai_calculate_health( round_number )
{
	level.zombie_health = level.zombie_vars[ "zombie_health_start" ];
	i = 2;
	while ( i <= round_number )
	{
		if ( i >= 10 )
		{
			level.zombie_health += int( level.zombie_health * level.zombie_vars[ "zombie_health_increase_multiplier" ] );
			i++;
			continue;
		}
		level.zombie_health = int( level.zombie_health + level.zombie_vars[ "zombie_health_increase" ] );
		i++;
	}
	if ( level.zombie_health < 0 )
	{
		level.zombie_health = level.zombie_vars[ "zombie_health_start" ];
	}
	if(level.zombie_health > ai_zombie_health(155))
	{
		level.zombie_health = ai_zombie_health(155);
	}
}

use_solo_revive()
{
	return 0;
}

should_attack_player_thru_boards()
{
	return 0;
}

init_zombie_run_cycle()
{
	self set_zombie_run_cycle();
}

init()
{
	setDvar("perk_weapRateEnhanced", 0);
	setDvar("sv_patch_zm_weapons", 0);
	
	if ( level.script == "zm_prison" )
	{
		level.is_forever_solo_game = undefined;
	}
	level.pers_upgrades = [];
	level.pers_upgrades_keys = [];
	level.zombie_vars["slipgun_reslip_rate"] = 0;
	level.zombie_vars["slipgun_max_kill_round"] = undefined;
	level.zombie_vars[ "zombie_perk_juggernaut_health" ] = 160;
	
	level.round_think_func = ::round_think;
	level thread round_hud();
	level thread zombie_total();
	level thread check_for_jugg_perk();
	level thread onPlayerConnect();
}

round_think( restart )
{
	if ( !isDefined( restart ) )
	{
		restart = 0;
	}
	level endon( "end_round_think" );
	if ( !is_true( restart ) )
	{
		if ( isDefined( level.initial_round_wait_func ) )
		{
			[[ level.initial_round_wait_func ]]();
		}
		players = get_players();
		foreach ( player in players )
		{
			if ( is_true( player.hostmigrationcontrolsfrozen ) ) 
			{
				player freezecontrols( 0 );
			}
			player maps/mp/zombies/_zm_stats::set_global_stat( "rounds", level.round_number );
		}
	}
	for ( ;; )
	{
		maxreward = 50 * level.round_number;
		if ( maxreward > 500 )
		{
			maxreward = 500;
		}
		level.zombie_vars[ "rebuild_barrier_cap_per_round" ] = maxreward;
		level.pro_tips_start_time = getTime();
		level.zombie_last_run_time = getTime();
		if ( isDefined( level.zombie_round_change_custom ) )
		{
			[[ level.zombie_round_change_custom ]]();
		}
		else
		{
			level thread maps/mp/zombies/_zm_audio::change_zombie_music( "round_start" );
			round_one_up();
		}
		maps/mp/zombies/_zm_powerups::powerup_round_start();
		players = get_players();
		array_thread( players, ::rebuild_barrier_reward_reset );
		if ( !is_true( level.headshots_only ) && !restart )
		{
			level thread award_grenades_for_survivors();
		}
		level.round_start_time = getTime();
		while ( level.zombie_spawn_locations.size <= 0 )
		{
			wait 0.1;
		}
		level thread [[ level.round_spawn_func ]]();
		level notify( "start_of_round" );
		recordzombieroundstart();
		players = getplayers();
		for ( index = 0; index < players.size; index++  )
		{
			zonename = players[ index ] get_current_zone();
			if ( isDefined( zonename ) )
			{
				players[ index ] recordzombiezone( "startingZone", zonename );
			}
		}
		if ( isDefined( level.round_start_custom_func ) )
		{
			[[ level.round_start_custom_func ]]();
		}
		[[ level.round_wait_func ]]();
		level.first_round = 0;
		level notify( "end_of_round" );
		level thread maps/mp/zombies/_zm_audio::change_zombie_music( "round_end" );
		uploadstats();
		if ( isDefined( level.round_end_custom_logic ) )
		{
			[[ level.round_end_custom_logic ]]();
		}
		players = get_players();
		if ( is_true( level.no_end_game_check ) )
		{
			level thread last_stand_revive();
			level thread spectators_respawn();
		}
		else if ( players.size != 1 )
		{
			level thread spectators_respawn();
		}
		players = get_players();
		array_thread( players, ::round_end );
		timer = level.zombie_vars[ "zombie_spawn_delay" ];
		if ( timer > 0.08 )
		{
			level.zombie_vars[ "zombie_spawn_delay" ] = timer * 0.95;
		}
		else if ( timer < 0.08 )
		{
			level.zombie_vars[ "zombie_spawn_delay" ] = 0.08;
		}
		if ( level.gamedifficulty == 0 )
		{
			level.zombie_move_speed = level.round_number * level.zombie_vars[ "zombie_move_speed_multiplier_easy" ];
		}
		else
		{
			level.zombie_move_speed = level.round_number * level.zombie_vars[ "zombie_move_speed_multiplier" ];
		}
		level.round_number++;
		matchutctime = getutc();
		players = get_players();
		foreach ( player in players )
		{
			if ( level.curr_gametype_affects_rank && level.round_number > 3 + level.start_round )
			{
				player maps/mp/zombies/_zm_stats::add_client_stat( "weighted_rounds_played", level.round_number );
			}
			player maps/mp/zombies/_zm_stats::set_global_stat( "rounds", level.round_number );
			player maps/mp/zombies/_zm_stats::update_playing_utc_time( matchutctime );
		}
		check_quickrevive_for_hotjoin();
		level round_over();
		level notify( "between_round_over" );
		restart = 0;
	}
}

round_hud()
{
	flag_wait( "initial_blackscreen_passed" );
	
	level.round_hud = create_simple_hud();
	level.round_hud.alignx = "left";
	level.round_hud.aligny = "bottom";
	level.round_hud.horzalign = "user_left";
	level.round_hud.vertalign = "user_bottom";
	level.round_hud.x += 5;
	level.round_hud.alpha = 0;
	level.round_hud.color = ( 0.21, 0, 0 );
	level.round_hud.fontscale = 5;
	level.round_hud.foreground = 1;
	level.round_hud.hidewheninmenu = 1;
	
	x = level.round_number;
	level.round_hud setvalue(x);
	level.round_hud fadeovertime( 3 );
	level.round_hud.alpha = 1;
	for (;;)
	{
		level waittill("end_of_round");
		x += 1;
		level.round_hud setvalue(x);
		level.round_hud.color = ( 1, 1, 1 );
		level.round_hud fadeovertime( 3 );
		level.round_hud.color = ( 0.21, 0, 0 );
	}
}

zombie_total()
{
	for (;;)
	{
		level waittill("start_of_round");
		if(level.round_number > 5 && getplayers().size == 1)
		{
			level.zombie_total = 23;
		}
	}
}

check_for_jugg_perk()
{
	for(;;)
	{
		players = getplayers();
		for(i = 0; i < players.size; i++)
		{
			if(players[i] hasperk("specialty_armorvest") && !isdefined(players[i].is_burning))
			{
				players[i].health += 40;
				if(players[i].health > 160)
				{
					players[i].health = 160;
				}
			}
		}
		wait 0.5;
	}
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
	self.legacy_spawn = 1;
	for(;;)
	{
		self waittill("spawned_player");
		if (self.legacy_spawn == 1)
		{
			self.legacy_spawn = 0;
			self thread movement();
			self thread reset_bank_locker();
		}
	}
}

movement()
{
	self setclientdvar("player_backSpeedScale", 1);
	self setclientdvar("player_strafeSpeedScale", 1);
	self setclientdvar("player_sprintStrafeSpeedScale", 1);
}

reset_bank_locker()
{
	flag_wait("initial_blackscreen_passed");
	self.account_value = 0;
	self setdstat( "PlayerStatsByMap", "zm_transit", "weaponLocker", "name", "" );
}