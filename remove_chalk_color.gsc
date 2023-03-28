#include maps\_anim; 
#include maps\_utility; 
#include common_scripts\utility;
#include maps\_music; 
#include maps\_zombiemode_utility; 
#include maps\_busing;
//#include maps\_zombiemode;

main()
{
	replaceFunc( maps\_zombiemode::round_start, ::round_start_replace );
	replaceFunc( maps\_zombiemode::create_chalk_hud, ::create_chalk_hud_replace );
	replaceFunc( maps\_zombiemode::chalk_one_up, ::chalk_one_up_replace );
	replaceFunc( maps\_zombiemode::chalk_round_over, ::chalk_round_over_replace );
	
	//level thread main_replace()
}


round_start_replace()
{
	if ( IsDefined(level.round_prestart_func) )
	{
		[[ level.round_prestart_func ]]();
	}
	else
	{
		wait( 2 );
	}

	level.zombie_health = level.zombie_vars["zombie_health_start"]; 

	// so players get init'ed with grenades
	players = get_players();
	for (i = 0; i < players.size; i++)
	{
		players[i] giveweapon( players[i] get_player_lethal_grenade() );	
		players[i] setweaponammoclip( players[i] get_player_lethal_grenade(), 0);
		players[i] SetClientDvars( "ammoCounterHide", "0",
				"miniscoreboardhide", "0" );
		//players[i] thread maps\_zombiemode_ability::give_round1_abilities();
	}

	if( getDvarInt( #"scr_writeconfigstrings" ) == 1 )
	{
		wait(5);
		ExitLevel();
		return;
	}
//	if( isDefined(level.chests) && isDefined(level.chest_index) )
//	{
//		Objective_Add( 0, "active", "Mystery Box", level.chests[level.chest_index].chest_lid.origin, "minimap_icon_mystery_box" );
//	}

	if ( level.zombie_vars["game_start_delay"] > 0 )
	{
		maps\_zombiemode::round_pause( level.zombie_vars["game_start_delay"] );
	}

	flag_set( "begin_spawning" );
	
	//maps\_zombiemode_solo::init();

	level.chalk_hud1 = create_chalk_hud_replace();
// 	if( level.round_number >= 1 && level.round_number <= 5 )
// 	{
// 		level.chalk_hud1 SetShader( "hud_chalk_" + level.round_number, 64, 64 );
// 	}
// 	else if ( level.round_number >= 5 && level.round_number <= 10 )
// 	{
// 		level.chalk_hud1 SetShader( "hud_chalk_5", 64, 64 );
// 	}
	level.chalk_hud2 = create_chalk_hud_replace( 64 );

	//	level waittill( "introscreen_done" );

	if( !isDefined(level.round_spawn_func) )
	{
		level.round_spawn_func = maps\_zombiemode::round_spawning;
	}
/#
	if (GetDvarInt( #"zombie_rise_test") )
	{
		level.round_spawn_func = maps\_zombiemode::round_spawning_test;		// FOR TESTING, one zombie at a time, no round advancement
	}
#/

	if ( !isDefined(level.round_wait_func) )
	{
		level.round_wait_func = maps\_zombiemode::round_wait;
	}

	if ( !IsDefined(level.round_think_func) )
	{
		level.round_think_func = maps\_zombiemode::round_think;
	}

	if( level.mutators["mutator_fogMatch"] )
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			players[i] thread set_fog( 729.34, 971.99, 338.336, 398.623, 0.58, 0.60, 0.56, 3 );
		}
	}

	level thread [[ level.round_think_func ]]();
}


create_chalk_hud_replace( x )
{
	if( !IsDefined( x ) )
	{
		x = 0;
	}

	hud = create_simple_hud();
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	//hud.color = ( 0.21, 0, 0 );
	hud.x = x; 
	hud.y = -4; 
	hud.alpha = 0;
	hud.fontscale = 32.0;

	hud SetShader( "hud_chalk_1", 64, 64 );

	return hud;
}

chalk_one_up_replace()
{
	huds = [];
	huds[0] = level.chalk_hud1;
	huds[1] = level.chalk_hud2;

	// Hud1 shader
	if( level.round_number >= 1 && level.round_number <= 5 )
	{
		huds[0] SetShader( "hud_chalk_" + level.round_number, 64, 64 );
	}
	else if ( level.round_number >= 5 && level.round_number <= 10 )
	{
		huds[0] SetShader( "hud_chalk_5", 64, 64 );
	}

	// Hud2 shader
	if( level.round_number > 5 && level.round_number <= 10 )
	{
		huds[1] SetShader( "hud_chalk_" + ( level.round_number - 5 ), 64, 64 );
	}

	// Display value
	if ( IsDefined( level.chalk_override ) )
	{
		huds[0] SetText( level.chalk_override );
		huds[1] SetText( " " );
	}
	else if( level.round_number <= 5 )
	{
		huds[1] SetText( " " );
	}
	else if( level.round_number > 10 )
	{
		huds[0].fontscale = 32;
		huds[0] SetValue( level.round_number );
		huds[1] SetText( " " );
	}

	if(!IsDefined(level.doground_nomusic))
	{
		level.doground_nomusic = 0;
	}
	if( level.first_round )
	{
		intro = true;
		level thread maps\_zombiemode::play_level_start_vox_delayed();
	}
	else
	{
		intro = false;
	}

	round = undefined;	
	if( intro )
	{
		// Create "ROUND" hud text
		round = create_simple_hud();
		round.alignX = "center"; 
		round.alignY = "bottom";
		round.horzAlign = "user_center"; 
		round.vertAlign = "user_bottom";
		round.fontscale = 16;
		//round.color = ( 1, 1, 1 );
		round.x = 0;
		round.y = -265;
		round.alpha = 0;
		round SetText( &"ZOMBIE_ROUND" );

//		huds[0] FadeOverTime( 0.05 );
		//huds[0].color = ( 1, 1, 1 );
		huds[0].alpha = 0;
		huds[0].horzAlign = "user_center";
		huds[0].x = -5;
		huds[0].y = -200;

		huds[1] SetText( " " );

		// Fade in white
		round FadeOverTime( 1 );
		round.alpha = 1;

		huds[0] FadeOverTime( 1 );
		huds[0].alpha = 1;

		wait( 1 );

		// Fade to red
		round FadeOverTime( 2 );
		//round.color = ( 0.21, 0, 0 );

		huds[0] FadeOverTime( 2 );
		//huds[0].color = ( 0.21, 0, 0 );
		wait(2);
	}
	else
	{
		for ( i=0; i<huds.size; i++ )
		{
			huds[i] FadeOverTime( 0.5 );
			huds[i].alpha = 0;
		}
		wait( 0.5 );
	}

// 	if( (level.round_number <= 5 || level.round_number >= 11) && IsDefined( level.chalk_hud2 ) )
// 	{
// 		huds[1] = undefined;
// 	}
// 	
	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 2 );
		huds[i].alpha = 1;
	}

	if( intro )
	{
		wait( 3 );

		if( IsDefined( round ) )
		{
			round FadeOverTime( 1 );
			round.alpha = 0;
		}

		wait( 0.25 );

		level notify( "intro_hud_done" );
		huds[0] MoveOverTime( 1.75 );
		huds[0].horzAlign = "user_left";
		//		huds[0].x = 0;
		huds[0].y = -4;
		wait( 2 );

		round destroy_hud();
	}
	else
	{
		for ( i=0; i<huds.size; i++ )
		{
			//huds[i].color = ( 1, 1, 1 );
		}
	}

	// Okay now wait just a bit to let the number set in
	if ( !intro )
	{
		wait( 2 ); 

		for ( i=0; i<huds.size; i++ )
		{
			huds[i] FadeOverTime( 1 );
			//huds[i].color = ( 0.21, 0, 0 );
		}
	}
	
	ReportMTU(level.round_number);	// In network debug instrumented builds, causes network spike report to generate.

	// Remove any override set since we're done with it
	if ( IsDefined( level.chalk_override ) )
	{
		level.chalk_override = undefined;
	}
}

chalk_round_over_replace()
{
	huds = [];
	huds[huds.size] = level.chalk_hud1;
	huds[huds.size] = level.chalk_hud2;

	if( level.round_number <= 5 || level.round_number > 10 )
	{
		level.chalk_hud2 SetText( " " );
	}

	time = level.zombie_vars["zombie_between_round_time"];
	if ( time > 3 )
	{
		time = time - 2;	// add this deduction back in at the bottom
	}

	for( i = 0; i < huds.size; i++ )
	{
		if( IsDefined( huds[i] ) )
		{
			huds[i] FadeOverTime( time * 0.25 );
			//huds[i].color = ( 1, 1, 1 );
		}
	}

	// Pulse
	fade_time = 0.5;
	steps =  ( time * 0.5 ) / fade_time;
	for( q = 0; q < steps; q++ )
	{
		for( i = 0; i < huds.size; i++ )
		{
			if( !IsDefined( huds[i] ) )
			{
				continue;
			}

			huds[i] FadeOverTime( fade_time );
			huds[i].alpha = 0;
		}

		wait( fade_time );

		for( i = 0; i < huds.size; i++ )
		{
			if( !IsDefined( huds[i] ) )
			{
				continue;
			}

			huds[i] FadeOverTime( fade_time );
			huds[i].alpha = 1;		
		}

		wait( fade_time );
	}

	for( i = 0; i < huds.size; i++ )
	{
		if( !IsDefined( huds[i] ) )
		{
			continue;
		}

		huds[i] FadeOverTime( time * 0.25 );
		//		huds[i].color = ( 0.8, 0, 0 );
		//huds[i].color = ( 0.21, 0, 0 );
		huds[i].alpha = 0;
	}

	wait ( 2.0 );
}