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

init()
{
	level.player_starting_points = 25000;
	level thread sq_give_player_rewards();
	level thread onPlayerConnect();
}

sq_give_player_rewards()
{
	flag_wait("initial_blackscreen_passed");
	players = get_players();
	foreach ( player in players )
	{
		player thread sq_give_player_all_perks();
	}
}

sq_give_player_all_perks()
{
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
	self thread watch_for_respawn();
}

watch_for_respawn()
{
	self endon( "disconnect" );
	self waittill_either( "spawned_player", "player_revived" );
	wait_network_frame();
	self sq_give_player_all_perks();
	self setmaxhealth( level.zombie_vars[ "zombie_perk_juggernaut_health" ] );
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
		if (self.director_spawn == 1)
		{
			self.director_spawn = 0;
			self thread upgrade_box();
			self thread end_solo_game();
		}
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

end_solo_game()
{
	self endon("disconnect");
    for(;;)
    {
        self waittill("player_downed");
        if ( (getPlayers().size == 1) && (level.solo_lives_given > 3) )
        {
            level notify("end_game");
        }
    }
}