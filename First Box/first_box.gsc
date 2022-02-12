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
	level thread first_box();
}

first_box()
{
	flag_wait("initial_blackscreen_passed");
	foreach(weapon in level.zombie_weapons)
	{
		if(is_true(weapon.is_in_box))
		{
			weapon.save_for_later = 1;
			weapon.is_in_box = 0;
		}
	}
	level.special_weapon_magicbox_check = undefined;
	if ( level.script == "zm_transit" )
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
		level.zombie_weapons["cymbal_monkey_zm"].is_in_box = 1;
	}
	else if ( level.script == "zm_nuked" )
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
		level.zombie_weapons["cymbal_monkey_zm"].is_in_box = 1;
	}
	else if ( level.script == "zm_highrise" )
	{
		level.zombie_weapons["cymbal_monkey_zm"].is_in_box = 1;
	}
	else if ( level.script == "zm_prison" )
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
		level.zombie_weapons["blundergat_zm"].is_in_box = 1;
	}
	else if ( level.script == "zm_buried" )
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
		level.zombie_weapons["slowgun_zm"].is_in_box = 1;
		level.zombie_weapons["cymbal_monkey_zm"].is_in_box = 1;
	}
	else if ( level.script == "zm_tomb" )
	{
		level.zombie_weapons["raygun_mark2_zm"].is_in_box = 1;
		level.zombie_weapons["cymbal_monkey_zm"].is_in_box = 1;
	}
	for(;;)
	{
		player_has_all = 0;
		i=0;
		while(i<get_players().size)
		{
			available_weapons = 0;
			foreach(weapon in level.zombie_weapons)
			{
				if(is_true(weapon.is_in_box) && !get_players()[i] has_weapon_or_upgrade(weapon.weapon_name))
				available_weapons++;
			}
			if(available_weapons > 0)
			{
				i++;
				continue;
			}
			player_has_all = 1;
			break;
		}
		if(!is_true(player_has_all))
		{
			wait 1;
			continue;
		}
		foreach(weapon in level.zombie_weapons)
		{
			if(is_true(weapon.save_for_later))
			{
				if ( level.script == "zm_transit" )
				{
					level.special_weapon_magicbox_check = ::transit_special_weapon_magicbox_check;
				}
				else if ( level.script == "zm_nuked" )
				{
					level.special_weapon_magicbox_check = ::nuked_special_weapon_magicbox_check;
				}
				else if ( level.script == "zm_highrise" )
				{
					level.special_weapon_magicbox_check = ::highrise_special_weapon_magicbox_check;
				}
				else if ( level.script == "zm_prison" )
				{
					level.special_weapon_magicbox_check = ::check_for_special_weapon_limit_exist;
				}
				else if ( level.script == "zm_buried" )
				{
					level.special_weapon_magicbox_check = ::buried_special_weapon_magicbox_check;
				}
				else if ( level.script == "zm_tomb" )
				{
					level.special_weapon_magicbox_check = ::tomb_special_weapon_magicbox_check;
				}
				weapon.is_in_box = 1;
			}
		}
		break;
	}
}

transit_special_weapon_magicbox_check( weapon )
{
	if ( is_true( level.raygun2_included ) )
	{
		if ( weapon == "ray_gun_zm" )
		{
			if ( self has_weapon_or_upgrade( "raygun_mark2_zm" ) || maps/mp/zombies/_zm_tombstone::is_weapon_available_in_tombstone( "raygun_mark2_zm", self ) )
			{
				return 0;
			}
		}
		if ( weapon == "raygun_mark2_zm" )
		{
			if ( self has_weapon_or_upgrade( "ray_gun_zm" ) || maps/mp/zombies/_zm_tombstone::is_weapon_available_in_tombstone( "ray_gun_zm", self ) )
			{
				return 0;
			}
			if ( randomint( 100 ) >= 33 )
			{
				return 0;
			}
		}
	}
	return 1;
}

nuked_special_weapon_magicbox_check( weapon )
{
	if ( isDefined( level.raygun2_included ) && level.raygun2_included )
	{
		if ( weapon == "ray_gun_zm" )
		{
			if ( self has_weapon_or_upgrade( "raygun_mark2_zm" ) )
			{
				return 0;
			}
		}
		if ( weapon == "raygun_mark2_zm" )
		{
			if ( self has_weapon_or_upgrade( "ray_gun_zm" ) )
			{
				return 0;
			}
			if ( randomint( 100 ) >= 33 )
			{
				return 0;
			}
		}
	}
	return 1;
}

highrise_special_weapon_magicbox_check(weapon)
{
	if ( is_true( level.raygun2_included ) )
	{
		if ( weapon == "ray_gun_zm" )
		{
			if(self has_weapon_or_upgrade( "raygun_mark2_zm" ) || maps/mp/zombies/_zm_chugabud::is_weapon_available_in_chugabud_corpse( "raygun_mark2_zm", self ) )
			{
				return 0;
			}
		}
		if ( weapon == "raygun_mark2_zm" )
		{
			if ( self has_weapon_or_upgrade( "ray_gun_zm" ) || maps/mp/zombies/_zm_chugabud::is_weapon_available_in_chugabud_corpse( "ray_gun_zm", self ) )
			{
				return 0;
			}
			if ( randomint( 100 ) >= 33 )
			{
				return 0;
			}
		}
	}
	return 1;
}

check_for_special_weapon_limit_exist( weapon )
{
	if ( weapon != "blundergat_zm" && weapon != "minigun_alcatraz_zm" )
	{
		return 1;
	}
	players = get_players();
	count = 0;
	if ( weapon == "blundergat_zm" )
	{
		if ( self maps/mp/zombies/_zm_weapons::has_weapon_or_upgrade( "blundersplat_zm" ) )
		{
			return 0;
		}
		if ( self afterlife_weapon_limit_check( "blundergat_zm" ) )
		{
			return 0;
		}
		limit = level.limited_weapons[ "blundergat_zm" ];
	}
	else
	{
		if ( self afterlife_weapon_limit_check( "minigun_alcatraz_zm" ) )
		{
			return 0;
		}
		limit = level.limited_weapons[ "minigun_alcatraz_zm" ];
	}
	i = 0;
	while ( i < players.size )
	{
		if ( weapon == "blundergat_zm" )
		{
			if ( players[ i ] has_weapon_or_upgrade( "blundersplat_zm" ) || isDefined( players[ i ].is_pack_splatting ) && players[ i ].is_pack_splatting )
			{
				count++;
				i++;
				continue;
			}
		}
		else
		{
			if ( players[ i ] afterlife_weapon_limit_check( weapon ) )
			{
				count++;
			}
		}
		i++;
	}
	if ( count >= limit )
	{
		return 0;
	}
	return 1;
}

afterlife_weapon_limit_check( limited_weapon )
{
	while ( isDefined( self.afterlife ) && self.afterlife )
	{
		if ( limited_weapon == "blundergat_zm" )
		{
			_a1577 = self.loadout;
			_k1577 = getFirstArrayKey( _a1577 );
			while ( isDefined( _k1577 ) )
			{
				weapon = _a1577[ _k1577 ];
				if ( weapon != "blundergat_zm" && weapon != "blundergat_upgraded_zm" || weapon == "blundersplat_zm" && weapon == "blundersplat_upgraded_zm" )
				{
					return 1;
				}
				_k1577 = getNextArrayKey( _a1577, _k1577 );
			}
		}
		else while ( limited_weapon == "minigun_alcatraz_zm" )
		{
			_a1587 = self.loadout;
			_k1587 = getFirstArrayKey( _a1587 );
			while ( isDefined( _k1587 ) )
			{
				weapon = _a1587[ _k1587 ];
				if ( weapon == "minigun_alcatraz_zm" || weapon == "minigun_alcatraz_upgraded_zm" )
				{
					return 1;
				}
				_k1587 = getNextArrayKey( _a1587, _k1587 );
			}
		}
	}
	return 0;
}

buried_special_weapon_magicbox_check( weapon )
{
	if ( weapon == "ray_gun_zm" )
	{
		if ( self has_weapon_or_upgrade( "raygun_mark2_zm" ) )
		{
			return 0;
		}
	}
	if ( weapon == "raygun_mark2_zm" )
	{
		if ( self has_weapon_or_upgrade( "ray_gun_zm" ) )
		{
			return 0;
		}
	}
	while ( weapon == "time_bomb_zm" )
	{
		players = get_players();
		i = 0;
		while ( i < players.size )
		{
			if ( is_player_valid( players[ i ], undefined, 1 ) && players[ i ] is_player_tactical_grenade( weapon ) )
			{
				return 0;
			}
			i++;
		}
	}
	return 1;
}

tomb_special_weapon_magicbox_check( weapon )
{
	if ( isDefined( level.raygun2_included ) && level.raygun2_included )
	{
		if ( weapon == "ray_gun_zm" )
		{
			if ( self has_weapon_or_upgrade( "raygun_mark2_zm" ) )
			{
				return 0;
			}
		}
		if ( weapon == "raygun_mark2_zm" )
		{
			if ( self has_weapon_or_upgrade( "ray_gun_zm" ) )
			{
				return 0;
			}
			if ( randomint( 100 ) >= 33 )
			{
				return 0;
			}
		}
	}
	if ( weapon == "beacon_zm" )
	{
		if ( isDefined( self.beacon_ready ) && self.beacon_ready )
		{
			return 1;
		}
		else
		{
			return 0;
		}
	}
	if ( isDefined( level.zombie_weapons[ weapon ].shared_ammo_weapon ) )
	{
		if ( self has_weapon_or_upgrade( level.zombie_weapons[ weapon ].shared_ammo_weapon ) )
		{
			return 0;
		}
	}
	return 1;
}