[! ------------------------------------------------------------------------------
!  Advent 060321        A classic and one of the standard Inform 6 example games
!
!
!                                  Adapted to Inform 5: 17.05.1994 to 24.05.1994
!                 Modernised to Inform 5.5 and library 5/12 or later: 20.12.1995
!                    Modernised to Inform 6 and library 6/1 or later: 11.11.1996
!                    A few bugs removed and companion text rewritten: 09.12.1996
!                                Some very minor bugs indeed removed: 24.02.1997
!                                                    And another two: 04.09.1997
!                 [RF] Source reformatted and very minor bug removed: 02.09.2004
!                     [RF] Added teleportation, also minor bug fixes: 21.03.2006
! ------------------------------------------------------------------------------

! Constant TEST_VERSION;
]
Constant Story "ADVENTURE";
Constant Headline
    "^The Interactive Original^
      By Will Crowther (1976) and Don Woods (1977)^
      Reconstructed in three steps by:^
      Donald Ekman, David M. Baggett (1993) and Graham Nelson (1994)^
      [In memoriam Stephen Bishop (1820?-1857): GN]^^";
Serial "060321";
Release 9;

! Adventure's IFID -- see 
Array UUID_ARRAY string "UUID://E9FD3D87-DD2F-4005-B332-23557780B64E//"; #Ifdef UUID_ARRAY; #Endif;

Constant AMUSING_PROVIDED;
Constant MAX_CARRIED   = 7;
Constant MAX_SCORE     = 350;
Constant MAX_TREASURES = 15;

Include "Parser";
Include "VerbLib";

Attribute nodwarf;                      ! Room is no-go area for dwarves
Attribute treasure_found;               ! Treasure object has been found
Attribute multitude;                    ! Used only by COUNT

Global caves_closed;                    ! true when cave is closing
Global canyon_from;                     ! Which canyon to return to
Global treasures_found;                 ! Count of treasures found
Global deaths;                          ! Counts of deaths/resurrections
Global dark_warning;                    ! true after warning about dark pits
Global feefie_count;                    ! fee/fie/foe/foo sequencer

! ------------------------------------------------------------------------------
!   Rules for treasures, which will be scattered all over the game
! ------------------------------------------------------------------------------

Class   Treasure
  with  after [;
          Take:
            if (location == Inside_Building)
                score = score - self.depositpoints;
            score = score + 5;
            if (noun hasnt treasure_found) {
                give noun treasure_found;
                treasures_found++;
                score = score + 2;
            }
            "Taken!";
          Insert:
            score = score - 5;  ! (in case put inside the wicker cage)
          Drop:
            score = score - 5;
            if (location == Inside_Building) {
                score = score + self.depositpoints;
                "Safely deposited.";
            }
        ],
        depositpoints 10;

! ------------------------------------------------------------------------------
!   The outside world
! ------------------------------------------------------------------------------

Class   Room;

Class   Aboveground
  class Room
  has   light nodwarf;

Class   Scenic
  has   scenery;

Aboveground At_End_Of_Road "At End Of Road"
  with  name 'end' 'of' 'road' 'street' 'path' 'gully',
        description
            "You are standing at the end of a road before a small brick building.
             Around you is a forest.
             A small stream flows out of the building and down a gully.",
        w_to At_Hill_In_Road,
        u_to At_Hill_In_Road,
        e_to Inside_Building,
        d_to In_A_Valley,
        s_to In_A_Valley,
        n_to In_Forest_1,
        in_to Inside_Building;

Scenic  "well house"
  with  name 'well' 'house' 'brick' 'building' 'small' 'wellhouse',
        description "It's a small brick building. It seems to be a well house.",
        found_in At_End_Of_Road At_Hill_In_Road Inside_Building,
        before [;
          Enter:
            if (location == At_Hill_In_Road && Inside_Building hasnt visited)
                "It's too far away.";
            <<Teleport Inside_Building>>;
        ];

Scenic  Stream "stream"
  with  name 'stream' 'water' 'brook' 'river' 'lake' 'small' 'tumbling'
             'splashing' 'babbling' 'rushing' 'reservoir',
        found_in At_End_Of_Road In_A_Valley At_Slit_In_Streambed In_Pit
                 In_Cavern_With_Waterfall At_Reservoir Inside_Building,
        before [;
          Drink:
            "You have taken a drink from the stream.
             The water tastes strongly of minerals, but is not unpleasant.
             It is extremely cold.";
          Take:
            if (bottle notin player)
                "You have nothing in which to carry the water.";
            <<Fill bottle>>;
          Insert:
            if (second == bottle) <<Fill bottle>>;
            "You have nothing in which to carry the water.";
          Receive:
            if (noun == ming_vase) {
                remove ming_vase;
                move shards to location;
                score = score - 5;
                "The sudden change in temperature has delicately shattered the vase.";
            }
            if (noun == bottle) <<Fill bottle>>;
            remove noun;
            if (noun ofclass Treasure) score = score - 5;
            print_ret (The) noun, " washes away with the stream.";
        ];

Scenic  "road"
  with  name 'road' 'street' 'path' 'dirt',
        description "The road is dirt, not yellow brick.",
        found_in At_End_Of_Road At_Hill_In_Road In_Forest_2;

Scenic  "forest"
  with  name 'forest' 'tree' 'trees' 'oak' 'maple' 'grove' 'pine' 'spruce'
             'birch' 'ash' 'saplings' 'bushes' 'leaves' 'berry' 'berries'
             'hardwood',
        description
            "The trees of the forest are large hardwood oak and maple,
             with an occasional grove of pine or spruce.
             There is quite a bit of undergrowth,
             largely birch and ash saplings plus nondescript bushes of various sorts.
             This time of year visibility is quite restricted by all the leaves,
             but travel is quite easy if you detour around the spruce and berry bushes.",
        found_in At_End_Of_Road At_Hill_In_Road In_A_Valley In_Forest_1 In_Forest_2,
  has   multitude;

! ------------------------------------------------------------------------------

Aboveground At_Hill_In_Road "At Hill In Road"
  with  name 'hill' 'in' 'road',
        description
            "You have walked up a hill, still in the forest.
             The road slopes back down the other side of the hill.
             There is a building in the distance.",
        e_to At_End_Of_Road,
        n_to At_End_Of_Road,
        d_to At_End_Of_Road,
        s_to In_Forest_1;

Scenic  -> "hill"
  with  name 'hill' 'bump' 'incline',
        description "It's just a typical hill.";

Scenic  -> "other side of hill"
  with  name 'side' 'other' 'of',
        article "the",
        description "Why not explore it yourself?";

! ------------------------------------------------------------------------------

Aboveground Inside_Building "Inside Building"
  with  name 'inside' 'building' 'well' 'house' 'wellhouse',
        description
            "You are inside a building, a well house for a large spring.",
        cant_go
            "The stream flows out through a pair of 1 foot diameter sewer pipes.
             The only exit is to the west.",
        before [;
          Enter:
            if (noun == Spring or SewerPipes)
                "The stream flows out through a pair of 1 foot diameter sewer pipes.
                 It would be advisable to use the exit.";
          Xyzzy:
            if (In_Debris_Room hasnt visited) rfalse;
            PlayerTo(In_Debris_Room);
            rtrue;
          Plugh:
            if (At_Y2 hasnt visited) rfalse;
            PlayerTo(At_Y2);
            rtrue;
        ],
        w_to At_End_Of_Road,
        out_to At_End_Of_Road,
        in_to "The pipes are too small.";

Scenic  -> Spring "spring"
  with  name 'spring' 'large',
        description
            "The stream flows out through a pair of 1 foot diameter sewer pipes.";

Scenic  -> SewerPipes "pair of 1 foot diameter sewer pipes"
  with  name 'pipes' 'pipe' 'one' 'foot' 'diameter' 'sewer' 'sewer-pipes',
        description "Too small. The only exit is to the west.";

Object  -> set_of_keys "set of keys"
  with  name 'keys' 'key' 'keyring' 'set' 'of' 'bunch',
        description "It's just a normal-looking set of keys.",
        initial "There are some keys on the ground here.",
        before [;
          Count:
            "A dozen or so keys.";
        ];

Object  -> tasty_food "tasty food"
  with  name 'food' 'ration' 'rations' 'tripe' 'yummy' 'tasty' 'delicious' 'scrumptious',
        article "some",
        description "Sure looks yummy!",
        initial "There is tasty food here.",
        after [;
          Eat:
            "Delicious!";
        ],
  has   edible;

Object  -> brass_lantern "brass lantern"
  with  name 'lamp' 'headlamp' 'headlight' 'lantern' 'light' 'shiny' 'brass',
        when_off "There is a shiny brass lamp nearby.",
        when_on "Your lamp is here, gleaming brightly.",
        daemon [ t;
            if (self hasnt on) {
                StopDaemon(self);
                rtrue;
            }
            t = --(self.power_remaining);
            if (t == 0) give self ~on ~light;
            if (self in player || self in location) {
                if (t == 0) {
                    print "Your lamp has run out of power.";
                    if (fresh_batteries notin player && location hasnt light) {
                        deadflag = 3;
                        " You can't explore the cave without a lamp.
                         So let's just call it a day.";
                    }
                    else
                        self.replace_batteries();
                    new_line;
                    rtrue;
                }
                if (t == 30) {
                    print "Your lamp is getting dim.";
                    if (fresh_batteries.have_been_used)
                        " You're also out of spare batteries.
                         You'd best start wrapping this up.";
                    if (fresh_batteries in VendingMachine && Dead_End_14 has visited)
                        " You'd best start wrapping this up,
                         unless you can find some fresh batteries.
                         I seem to recall there's a vending machine in the maze.
                         Bring some coins with you.";
                    if (fresh_batteries notin VendingMachine or player or location)
                        " You'd best go back for those batteries.";
                    new_line;
                    rtrue;
                }
            }
        ],
        before [;
          Examine:
            print "It is a shiny brass lamp";
            if (self hasnt on) ". It is not currently lit.";
            if (self.power_remaining < 30) ", glowing dimly.";
            ", glowing brightly.";
          Burn:
            <<SwitchOn self>>;
          Rub:
            "Rubbing the electric lamp is not particularly rewarding.
             Anyway, nothing exciting happens.";
          SwitchOn:
            if (self.power_remaining <= 0)
                "Unfortunately, the batteries seem to be dead.";
          Receive:
            if (noun == old_batteries)
                "Those batteries are dead; they won't do any good at all.";
            if (noun == fresh_batteries) {
                self.replace_batteries();
                rtrue;
            }
            "The only thing you might successfully put in the lamp
             is a fresh pair of batteries.";
        ],
        after [;
          SwitchOn:
            give self light;
            StartDaemon(self);
          SwitchOff:
            give self ~light;
        ],
        replace_batteries [;
            if (fresh_batteries in player or location) {
                remove fresh_batteries;
                fresh_batteries.have_been_used = true;
                move old_batteries to location;
                self.power_remaining = 2500;
                "I'm taking the liberty of replacing the batteries.";
            }
        ],
        power_remaining 330,
  has   switchable;

Object  -> bottle "small bottle"
  with  name 'bottle' 'jar' 'flask',
        initial "There is an empty bottle here.",
        before [;
          LetGo:
            if (noun in bottle)
                "You're holding that already (in the bottle).";
          Receive:
            if (noun == stream or Oil)
                <<Fill self>>;
            else
                "The bottle is only supposed to hold liquids.";
          Fill:
            if (child(bottle) ~= nothing)
                "The bottle is full already.";
            if (stream in location || Spring in location) {
                move water_in_the_bottle to bottle;
                "The bottle is now full of water.";
            }
            if (Oil in location) {
                move oil_in_the_bottle to bottle;
                "The bottle is now full of oil.";
            }
            "There is nothing here with which to fill the bottle.";
          Empty:
            if (child(bottle) == nothing)
                "The bottle is already empty!";
            remove child(bottle);
            "Your bottle is now empty and the ground is now wet.";
        ],
  has   container open;

Object  water_in_the_bottle "bottled water"
  with  name 'bottled' 'water' 'h2o',
        article "some",
        description "It looks like ordinary water to me.",
        before [;
          Drink:
            remove water_in_the_bottle;
            <<Drink Stream>>;
        ];

Object  oil_in_the_bottle "bottled oil"
  with  name 'oil' 'bottled' 'lubricant' 'grease',
        article "some",
        description "It looks like ordinary oil to me.",
        before [;
          Drink:
            <<Drink Oil>>;
        ];

! ------------------------------------------------------------------------------

Aboveground In_Forest_1 "In Forest"
  with  name 'forest',
        description "You are in open forest, with a deep valley to one side.",
        e_to In_A_Valley,
        d_to In_A_Valley,
        n_to In_Forest_1,
        w_to In_Forest_1,
        s_to In_Forest_1,
        initial [;
            if (random(2) == 1) PlayerTo(In_Forest_2, 1);
        ];

Aboveground In_Forest_2 "In Forest"
  with  description "You are in open forest near both a valley and a road.",
        n_to At_End_Of_Road,
        e_to In_A_Valley,
        w_to In_A_Valley,
        d_to In_A_Valley,
        s_to In_Forest_1;

Aboveground In_A_Valley "In A Valley"
  with  description
            "You are in a valley in the forest beside a stream tumbling along a rocky bed.",
        n_to At_End_Of_Road,
        e_to In_Forest_1,
        w_to In_Forest_1,
        u_to In_Forest_1,
        s_to At_Slit_In_Streambed,
        d_to At_Slit_In_Streambed,
        name 'valley';

Scenic  -> "streambed"
  with  name 'bed' 'streambed' 'rock' 'small' 'rocky' 'bare' 'dry';

! ------------------------------------------------------------------------------

Aboveground At_Slit_In_Streambed "At Slit In Streambed"
  with  name 'slit' 'in' 'streambed',
        description
            "At your feet all the water of the stream splashes into a 2-inch slit in the rock.
             Downstream the streambed is bare rock.",
        n_to In_A_Valley,
        e_to In_Forest_1,
        w_to In_Forest_1,
        s_to Outside_Grate,
        d_to "You don't fit through a two-inch slit!",
        in_to "You don't fit through a two-inch slit!";

Scenic  -> "2-inch slit"
  with  name 'slit' 'two' 'inch' '2-inch',
        description
            "It's just a 2-inch slit in the rock, through which the stream is flowing.",
        before [;
          Enter:
            "You don't fit through a two-inch slit!";
        ];

! ------------------------------------------------------------------------------

Aboveground Outside_Grate "Outside Grate"
  with  name 'outside' 'grate',
        description
            "You are in a 20-foot depression floored with bare dirt.
             Set into the dirt is a strong steel grate mounted in concrete.
             A dry streambed leads into the depression.",
        e_to In_Forest_1,
        w_to In_Forest_1,
        s_to In_Forest_1,
        n_to At_Slit_In_Streambed,
        d_to [;
            if (Grate hasnt locked && Grate hasnt open) {
                print "(first opening the grate)^";
                give Grate open;
            }
            return Grate;
        ];

Scenic  -> "20-foot depression"
  with  name 'depression' 'dirt' 'twenty' 'foot' 'bare' '20-foot',
        description "You're standing in it.";

Object  -> Grate "steel grate"
  with  name 'grate' 'lock' 'gate' 'grille' 'metal' 'strong' 'steel' 'grating',
        description "It just looks like an ordinary grate mounted in concrete.",
        with_key set_of_keys,
        door_dir [;
            if (location == Below_The_Grate) return u_to;
            return d_to;
        ],
        door_to [;
            if (location == Below_The_Grate) return Outside_Grate;
            return Below_The_Grate;
        ],
        describe [;
            if (self has open) "^The grate stands open.";
            if (self hasnt locked) "^The grate is unlocked but shut.";
            rtrue;
        ],
        found_in Below_The_Grate Outside_Grate,
  has   static door openable lockable locked;

! ------------------------------------------------------------------------------
!   Facilis descensus Averno...
! ------------------------------------------------------------------------------

Room    Below_The_Grate "Below the Grate"
  with  name 'below' 'grate',
        description
            "You are in a small chamber beneath a 3x3 steel grate to the surface.
             A low crawl over cobbles leads inward to the west.",
        w_to In_Cobble_Crawl,
        u_to Grate,
  has   light;

Scenic  "cobbles"
  with  name 'cobble' 'cobbles' 'cobblestones' 'cobblestone' 'stones' 'stone',
        description "They're just ordinary cobbles.",
        found_in In_Cobble_Crawl In_Debris_Room Below_The_Grate,
  has   multitude;

! ------------------------------------------------------------------------------

Room    In_Cobble_Crawl "In Cobble Crawl"
  with  name 'cobble' 'crawl',
        description
            "You are crawling over cobbles in a low passage.
             There is a dim light at the east end of the passage.",
        e_to Below_The_Grate,
        w_to In_Debris_Room,
  has   light;

Object  -> wicker_cage "wicker cage"
  with  name 'cage' 'small' 'wicker',
        description "It's a small wicker cage.",
        initial "There is a small wicker cage discarded nearby.",
        after [;
          Open:
            if (little_bird notin self) rfalse;
            print "(releasing the little bird)^";
            <<Release little_bird>>;
        ],
  has   container open openable transparent;

! ------------------------------------------------------------------------------

Room    In_Debris_Room "In Debris Room"
  with  name 'debris' 'room',
        description
            "You are in a debris room filled with stuff washed in from the surface.
             A low wide passage with cobbles becomes plugged with mud and debris here,
             but an awkward canyon leads upward and west.
             ^^
             A note on the wall says, ~Magic word XYZZY.~",
        e_to In_Cobble_Crawl,
        u_to In_Awkward_Sloping_E_W_Canyon,
        w_to In_Awkward_Sloping_E_W_Canyon,
        before [;
          Xyzzy:
            PlayerTo(Inside_Building);
            rtrue;
        ],
  has   nodwarf;

Scenic  -> "debris"
  with  name 'debris' 'stuff' 'mud',
        description "Yuck.";

Scenic  -> "note"
  with  name 'note',
        description "The note says ~Magic word XYZZY~.";

Object  -> black_rod "black rod with a rusty star on the end"
  with  name 'rod' 'star' 'black' 'rusty' 'star' 'three' 'foot' 'iron',
        description "It's a three foot black rod with a rusty star on an end.",
        initial
            "A three foot black rod with a rusty star on one end lies nearby.",
        before [;
          Wave:
            if (location == West_Side_Of_Fissure or On_East_Bank_Of_Fissure) {
                if (caves_closed) "Peculiar. Nothing happens.";
                if (CrystalBridge notin nothing) {
                    remove CrystalBridge;
                    give CrystalBridge absent;
                    West_Side_Of_Fissure.e_to = nothing;
                    On_East_Bank_Of_Fissure.w_to = nothing;
                    "The crystal bridge has vanished!";
                }
                else {
                    move CrystalBridge to location;
                    give CrystalBridge ~absent;
                    West_Side_Of_Fissure.e_to = CrystalBridge;
                    On_East_Bank_Of_Fissure.w_to = CrystalBridge;
                    "A crystal bridge now spans the fissure.";
                }
            }
            "Nothing happens.";
        ];

! ------------------------------------------------------------------------------

Room    In_Awkward_Sloping_E_W_Canyon "Sloping E/W Canyon"
  with  name 'sloping' 'e/w' 'canyon',
        description "You are in an awkward sloping east/west canyon.",
        d_to In_Debris_Room,
        e_to In_Debris_Room,
        u_to In_Bird_Chamber,
        w_to In_Bird_Chamber,
  has   nodwarf;

! ------------------------------------------------------------------------------
!   The little bird in its natural habitat
! ------------------------------------------------------------------------------

Room    In_Bird_Chamber "Orange River Chamber"
  with  name 'orange' 'river' 'chamber',
        description
            "You are in a splendid chamber thirty feet high.
             The walls are frozen rivers of orange stone.
             An awkward canyon and a good passage exit from east and west sides of the chamber.",
        e_to In_Awkward_Sloping_E_W_Canyon,
        w_to At_Top_Of_Small_Pit,
  has   nodwarf;

Object  -> little_bird "little bird"
  with  name 'cheerful' 'mournful' 'little' 'bird',
        initial "A cheerful little bird is sitting here singing.",
        before [;
          Examine:
            if (self in wicker_cage)
                "The little bird looks unhappy in the cage.";
            "The cheerful little bird is sitting here singing.";
          Insert:
            if (second == wicker_cage)
                <<Catch self>>;
            else
                "Don't put the poor bird in ", (the) second, "!";
          Drop, Remove:
            if (self in wicker_cage) {
                print "(The bird is released from the cage.)^^";
                <<Release self>>;
            }
          Take, Catch:
            if (self in wicker_cage)
                "You already have the little bird.
                 If you take it out of the cage it will likely fly away from you.";
            if (wicker_cage notin player)
                "You can catch the bird, but you cannot carry it.";
            if (black_rod in player)
                "The bird was unafraid when you entered,
                 but as you approach it becomes disturbed and you cannot catch it.";
            move self to wicker_cage;
            give wicker_cage ~open;
            "You catch the bird in the wicker cage.";
          Release:
            if (self notin wicker_cage)
                "The bird is not caged now.";
            give wicker_cage open;
            move self to location;
            if (Snake in location) {
                remove Snake;
                "The little bird attacks the green snake,
                 and in an astounding flurry drives the snake away.";
            }
            if (Dragon in location) {
                remove self;
                "The little bird attacks the green dragon,
                 and in an astounding flurry gets burnt to a cinder.
                 The ashes blow away.";
            }
            "The little bird flies free.";
        ],
        life [;
          Give:
            "It's not hungry. (It's merely pinin' for the fjords).
             Besides, I suspect it would prefer bird seed.";
          Order, Ask, Answer:
            "Cheep! Chirp!";
          Attack:
            if (self in wicker_cage)
                "Oh, leave the poor unhappy bird alone.";
            remove self;
            "The little bird is now dead. Its body disappears.";
        ],
  has   animate;

! ------------------------------------------------------------------------------

Room    At_Top_Of_Small_Pit "At Top of Small Pit"
  with  name 'top' 'of' 'small' 'pit',
        description
            "At your feet is a small pit breathing traces of white mist.
             A west passage ends here except for a small crack leading on.
             ^^
             Rough stone steps lead down the pit.",
        e_to In_Bird_Chamber,
        w_to "The crack is far too small for you to follow.",
        d_to [;
            if (large_gold_nugget in player) {
                deadflag = 1;
                "You are at the bottom of the pit with a broken neck.";
            }
            return In_Hall_Of_Mists;
        ],
        before [;
          Enter:
            if (noun == PitCrack)
                "The crack is far too small for you to follow.";
        ],
  has   nodwarf;

Scenic  -> "small pit"
  with  name 'pit' 'small',
        description "The pit is breathing traces of white mist.";

Scenic  -> PitCrack "crack"
  with  name 'crack' 'small',
        description "The crack is very small -- far too small for you to follow.";

Scenic  "mist"
  with  name 'mist' 'vapor' 'wisps' 'white',
        description
            "Mist is a white vapor, usually water, seen from time to time in caverns.
             It can be found anywhere but is frequently a sign of a deep pit leading down to water.",
        found_in
            At_Top_Of_Small_Pit In_Hall_Of_Mists On_East_Bank_Of_Fissure
            At_Window_On_Pit_1 At_West_End_Of_Hall_Of_Mists In_Misty_Cavern
            In_Mirror_Canyon At_Reservoir At_Window_On_Pit_2 On_Sw_Side_Of_Chasm;

! ------------------------------------------------------------------------------
!   The caves open up: The Hall of Mists
! ------------------------------------------------------------------------------

Room    In_Hall_Of_Mists "In Hall of Mists"
  with  name 'hall' 'of' 'mists',
        description
            "You are at one end of a vast hall stretching forward out of sight to the west.
             There are openings to either side.
             Nearby, a wide stone staircase leads downward.
             The hall is filled with wisps of white mist swaying to and fro almost as if alive.
             A cold wind blows up the staircase.
             There is a passage at the top of a dome behind you.
             ^^
             Rough stone steps lead up the dome.",
        initial [;
            if (self has visited) rfalse;
            score = score + 25;
        ],
        s_to In_Nugget_Of_Gold_Room,
        w_to On_East_Bank_Of_Fissure,
        d_to In_Hall_Of_Mt_King,
        n_to In_Hall_Of_Mt_King,
        u_to [;
            if (large_gold_nugget in player) "The dome is unclimbable.";
            return At_Top_Of_Small_Pit;
        ];

Scenic  -> "wide stone staircase"
  with  name 'stair' 'stairs' 'staircase' 'wide' 'stone',
        description "The staircase leads down.";

Scenic  -> "rough stone steps"
  with  name 'stair' 'stairs' 'staircase' 'rough' 'stone',
        description "The rough stone steps lead up the dome.",
  has   multitude;

Scenic  -> "dome"
  with  name 'dome',
        before [;
          Examine:
            if (large_gold_nugget in player)
                "I'm not sure you'll be able to get up it with what you're
                 carrying.";
            "It looks like you might be able to climb up it.";
          Climb:
            MovePlayer(u_obj);
            rtrue;
        ];

! ------------------------------------------------------------------------------

Room    In_Nugget_Of_Gold_Room "Low Room"
  with  name 'low' 'room',
        description
            "This is a low room with a crude note on the wall:
             ^^
             ~You won't get it up the steps~.",
        n_to In_Hall_Of_Mists;

Scenic  -> "note"
  with  name 'note' 'crude',
        description "The note says, ~You won't get it up the steps~.";

Treasure -> large_gold_nugget "large gold nugget"
  with  name 'gold' 'nugget' 'large' 'heavy',
        description "It's a large sparkling nugget of gold!",
        initial "There is a large sparkling nugget of gold here!";

! ------------------------------------------------------------------------------

Class   FissureRoom
  class Room
  with  before [;
          Jump:
            if (CrystalBridge hasnt absent)
                "I respectfully suggest you go across the bridge instead of jumping.";
            deadflag = 1;
            "You didn't make it.";
        ],
        d_to "The fissure is too terrifying!";

FissureRoom On_East_Bank_Of_Fissure "On East Bank of Fissure"
  with  name 'east' 'e//' 'bank' 'side' 'of' 'fissure',
        description
            "You are on the east bank of a fissure slicing clear across the hall.
             The mist is quite thick here, and the fissure is too wide to jump.",
        e_to In_Hall_Of_Mists,
        w_to "The fissure is too wide.";

FissureRoom West_Side_Of_Fissure "West Side of Fissure"
  with  name 'west' 'w//' 'bank' 'side' 'of' 'fissure',
        description
            "You are on the west side of the fissure in the hall of mists.",
        w_to At_West_End_Of_Hall_Of_Mists,
        e_to "The fissure is too wide.",
        n_to At_West_End_Of_Hall_Of_Mists,
        before [;
          Go:
            if (location == West_Side_Of_Fissure && noun == n_obj)
                print
                    "You have crawled through a very low wide passage
                     parallel to and north of the hall of mists.^";
        ];

Treasure -> "diamonds"
  with  name 'diamond' 'diamonds' 'several' 'high' 'quality',
        article "some",
        description "They look to be of the highest quality!",
        initial "There are diamonds here!",
  has   multitude;

Object  CrystalBridge "crystal bridge"
  with  name 'crystal' 'bridge',
        description "It spans the fissure, thereby providing you a way across.",
        initial "A crystal bridge now spans the fissure.",
        door_dir [;
            if (location == West_Side_Of_Fissure) return e_to;
            return w_to;
        ],
        door_to [;
            if (location == West_Side_Of_Fissure) return On_East_Bank_Of_Fissure;
            return West_Side_Of_Fissure;
        ],
        found_in On_East_Bank_Of_Fissure West_Side_Of_Fissure,
  has   static door open absent;

Scenic  "fissure"
  with  name 'wide' 'fissure',
        description "The fissure looks far too wide to jump.",
        found_in On_East_Bank_Of_Fissure West_Side_Of_Fissure;

! ------------------------------------------------------------------------------

Room    At_West_End_Of_Hall_Of_Mists "At West End of Hall of Mists"
  with  name 'west' 'w//' 'end' 'of' 'hall' 'mists',
        description
            "You are at the west end of the hall of mists.
             A low wide crawl continues west and another goes north.
             To the south is a little passage 6 feet off the floor.",
        s_to Alike_Maze_1,
        u_to Alike_Maze_1,
        e_to West_Side_Of_Fissure,
        w_to At_East_End_Of_Long_Hall,
        n_to West_Side_Of_Fissure,
        before [;
          Go:
            if (noun == n_obj)
                print
                    "You have crawled through a very low wide passage
                     parallel to and north of the hall of mists.^";
        ];

! ------------------------------------------------------------------------------
!   Long Hall to the west of the Hall of Mists
! ------------------------------------------------------------------------------

Room    At_East_End_Of_Long_Hall "At East End of Long Hall"
  with  name 'east' 'e//' 'end' 'of' 'long' 'hall',
        description
            "You are at the east end of a very long hall apparently without side chambers.
             To the east a low wide crawl slants up.
             To the north a round two foot hole slants down.",
        e_to At_West_End_Of_Hall_Of_Mists,
        u_to At_West_End_Of_Hall_Of_Mists,
        w_to At_West_End_Of_Long_Hall,
        n_to Crossover,
        d_to Crossover;

! ------------------------------------------------------------------------------

Room    At_West_End_Of_Long_Hall "At West End of Long Hall"
  with  name 'west' 'w//' 'end' 'of' 'long' 'hall',
        description
            "You are at the west end of a very long featureless hall.
             The hall joins up with a narrow north/south passage.",
        e_to At_East_End_Of_Long_Hall,
        s_to Different_Maze_1,
        n_to Crossover;

! ------------------------------------------------------------------------------

Room    Crossover "N/S and E/W Crossover"
  with  name 'n/s' 'and' 'e/w' 'crossover',
        description
            "You are at a crossover of a high N/S passage and a low E/W one.",
        w_to At_East_End_Of_Long_Hall,
        n_to Dead_End_7,
        e_to In_West_Side_Chamber,
        s_to At_West_End_Of_Long_Hall;

Scenic  -> "crossover"
  with  name 'crossover' 'over' 'cross',
        description "You know as much as I do at this point.";

! ------------------------------------------------------------------------------
!   Many Dead Ends will be needed for the maze below, so define a class:
! ------------------------------------------------------------------------------

Class   DeadendRoom
  with  short_name "Dead End",
        description "You have reached a dead end.",
        cant_go "You'll have to go back the way you came.";

DeadendRoom Dead_End_7
  with  s_to Crossover,
        out_to Crossover;

! ------------------------------------------------------------------------------
!   The Hall of the Mountain King and side chambers
! ------------------------------------------------------------------------------

Room    In_Hall_Of_Mt_King "Hall of the Mountain King"
  with  name 'hall' 'of' 'mountain' 'king',
        description
            "You are in the hall of the mountain king, with passages off in all directions.",
        cant_go "Well, perhaps not quite all directions.",
        u_to In_Hall_Of_Mists,
        e_to In_Hall_Of_Mists,
        n_to Low_N_S_Passage,
        s_to In_South_Side_Chamber,
        w_to In_West_Side_Chamber,
        sw_to In_Secret_E_W_Canyon,
        before [;
          Go:
            if (Snake in self && (noun == n_obj or s_obj or w_obj ||
                                 (noun == sw_obj && random(100) <= 35)))
                "You can't get by the snake.";
        ];

Object  -> Snake "snake"
  with  name 'snake' 'cobra' 'asp' 'huge' 'fierce' 'green' 'ferocious'
             'venemous' 'venomous' 'large' 'big' 'killer',
        description "I wouldn't mess with it if I were you.",
        initial "A huge green fierce snake bars the way!",
        life [;
          Order, Ask, Answer:
            "Hiss!";
          ThrowAt:
            if (noun == axe) <<Attack self>>;
            <<Give noun self>>;
          Give:
            if (noun == little_bird) {
                remove little_bird;
                "The snake has now devoured your bird.";
            }
            "There's nothing here it wants to eat (except perhaps you).";
          Attack:
            "Attacking the snake both doesn't work and is very dangerous.";
          Take:
            deadflag = 1;
            "It takes you instead. Glrp!";
        ],
  has   animate;

! ------------------------------------------------------------------------------

Room    Low_N_S_Passage "Low N/S Passage"
  with  name 'low' 'n/s' 'passage',
        description
            "You are in a low N/S passage at a hole in the floor.
             The hole goes down to an E/W passage.",
        s_to In_Hall_Of_Mt_King,
        d_to In_Dirty_Passage,
        n_to At_Y2;

Treasure -> "bars of silver"
  with  name 'silver' 'bars',
        article "some",
        description "They're probably worth a fortune!",
        initial "There are bars of silver here!";

! ------------------------------------------------------------------------------

Room    In_South_Side_Chamber "In South Side Chamber"
  with  name 'south' 's//''side' 'chamber',
        description "You are in the south side chamber.",
        n_to In_Hall_Of_Mt_King;

Treasure -> "precious jewelry"
  with  name 'jewel' 'jewels' 'jewelry' 'precious' 'exquisite',
        article "some",
        description "It's all quite exquisite!",
        initial "There is precious jewelry here!";

! ------------------------------------------------------------------------------

Room    In_West_Side_Chamber "In West Side Chamber"
  with  name 'west' 'w//' 'wide' 'chamber',
        description
            "You are in the west side chamber of the hall of the mountain king.
             A passage continues west and up here.",
        w_to Crossover,
        u_to Crossover,
        e_to In_Hall_Of_Mt_King;

Treasure -> rare_coins "rare coins"
  with  name 'coins' 'rare',
        article "many",
        description "They're a numismatist's dream!",
        initial "There are many coins here!",
  has   multitude;

! ------------------------------------------------------------------------------
!   The Y2 Rock Room and environs, slightly below
! ------------------------------------------------------------------------------

Room    At_Y2 "At ~Y2~"
  with  name 'y2',
        description
            "You are in a large room, with a passage to the south,
             a passage to the west, and a wall of broken rock to the east.
             There is a large ~Y2~ on a rock in the room's center.",
        after [;
          Look:
            if (random(100) <= 25) print "^A hollow voice says, ~Plugh.~^";
        ],
        before [;
          Plugh:
            PlayerTo(Inside_Building);
            rtrue;
          Plover:
            if (In_Plover_Room hasnt visited) rfalse;
            if (egg_sized_emerald in player) {
                move egg_sized_emerald to In_Plover_Room;
                score = score - 5;
            }
            PlayerTo(In_Plover_Room);
            rtrue;
        ],
        s_to Low_N_S_Passage,
        e_to Jumble_Of_Rock,
        w_to At_Window_On_Pit_1;

Scenic  -> "~Y2~ rock"
  with  name 'rock' 'y2',
        description "There is a large ~Y2~ painted on the rock.",
  has   supporter;

! ------------------------------------------------------------------------------

Room    Jumble_Of_Rock "Jumble of Rock"
  with  name 'jumble' 'of' 'rock',
        description "You are in a jumble of rock, with cracks everywhere.",
        d_to At_Y2,
        u_to In_Hall_Of_Mists;

! ------------------------------------------------------------------------------

Room    At_Window_On_Pit_1 "At Window on Pit"
  with  name 'window' 'on' 'pit' 'east' 'e//',
        description
            "You're at a low window overlooking a huge pit, which extends up out of sight.
             A floor is indistinctly visible over 50 feet below.
             Traces of white mist cover the floor of the pit, becoming thicker to the right.
             Marks in the dust around the window would seem to indicate that someone has been here recently.
             Directly across the pit from you and 25 feet away
             there is a similar window looking into a lighted room.
             A shadowy figure can be seen there peering back at you.",
        before [;
          WaveHands:
            "The shadowy figure waves back at you!";
        ],
        cant_go "The only passage is back east to Y2.",
        e_to At_Y2;

Class   PitScenic
  with  found_in At_Window_On_Pit_1 At_Window_On_Pit_2,
  has   scenery;

PitScenic "window"
  with  name 'window' 'low',
        description "It looks like a regular window.",
  has   openable;

PitScenic "huge pit"
  with  name 'pit' 'deep' 'large',
        description
            "It's so deep you can barely make out the floor below,
             and the top isn't visible at all.";

PitScenic "marks in the dust"
  with  name 'marks' 'dust',
        description "Evidently you're not alone here.",
  has   multitude;

PitScenic "shadowy figure"
  with  name 'figure' 'shadow' 'person' 'individual' 'shadowy' 'mysterious',
        description
            "The shadowy figure seems to be trying to attract your attention.";

! ------------------------------------------------------------------------------

Room    In_Dirty_Passage "Dirty Passage"
  with  name 'dirty' 'passage',
        description
            "You are in a dirty broken passage.
             To the east is a crawl.
             To the west is a large passage.
             Above you is a hole to another passage.",
        e_to On_Brink_Of_Pit,
        u_to Low_N_S_Passage,
        w_to In_Dusty_Rock_Room;

! ------------------------------------------------------------------------------

Room    On_Brink_Of_Pit "Brink of Pit"
  with  name 'brink' 'of' 'pit',
        description
            "You are on the brink of a small clean climbable pit.
             A crawl leads west.",
        w_to In_Dirty_Passage,
        d_to In_Pit,
        in_to In_Pit;

Scenic  -> "small pit"
  with  name 'pit' 'small' 'clean' 'climbable',
        description "It looks like you might be able to climb down into it.",
        before [;
          Climb, Enter:
            MovePlayer(d_obj);
            rtrue;
        ];

! ------------------------------------------------------------------------------

Room    In_Pit "In Pit"
  with  name 'in' 'pit',
        description
            "You are in the bottom of a small pit with a little stream,
             which enters and exits through tiny slits.",
        u_to On_Brink_Of_Pit,
        d_to "You don't fit through the tiny slits!",
  has   nodwarf;

Scenic  -> "tiny slits"
  with  name 'slit' 'slits' 'tiny',
        description "The slits form a complex pattern in the rock.",
  has   multitude;

! ------------------------------------------------------------------------------

Room    In_Dusty_Rock_Room "In Dusty Rock Room"
  with  name 'dusty' 'rock' 'room',
        description
            "You are in a large room full of dusty rocks.
             There is a big hole in the floor.
             There are cracks everywhere, and a passage leading east.",
        e_to In_Dirty_Passage,
        d_to At_Complex_Junction;

Scenic  -> "dusty rocks"
  with  name 'rocks' 'boulders' 'stones' 'rock' 'boulder' 'stone' 'dusty' 'dirty',
        description "They're just rocks. (Dusty ones, that is.)",
        before [;
          LookUnder, Push, Pull:
            "You'd have to blast your way through.";
        ],
  has   multitude;

! ------------------------------------------------------------------------------
!   A maze of twisty little passages, all alike...
! ------------------------------------------------------------------------------

Class   MazeRoom
  with  short_name "Maze",
        description "You are in a maze of twisty little passages, all alike.",
        out_to "Easier said than done.";

MazeRoom Alike_Maze_1
  with  u_to At_West_End_Of_Hall_Of_Mists,
        n_to Alike_Maze_1,
        e_to Alike_Maze_2,
        s_to Alike_Maze_4,
        w_to Alike_Maze_11;

MazeRoom Alike_Maze_2
  with  w_to Alike_Maze_1,
        s_to Alike_Maze_3,
        e_to Alike_Maze_4;

MazeRoom Alike_Maze_3
  with  e_to Alike_Maze_2,
        d_to Dead_End_3,
        s_to Alike_Maze_6,
        n_to Dead_End_13;

MazeRoom Alike_Maze_4
  with  w_to Alike_Maze_1,
        n_to Alike_Maze_2,
        e_to Dead_End_1,
        s_to Dead_End_2,
        u_to Alike_Maze_14,
        d_to Alike_Maze_14;

MazeRoom Alike_Maze_5
  with  e_to Alike_Maze_6,
        w_to Alike_Maze_7;

MazeRoom Alike_Maze_6
  with  e_to Alike_Maze_3,
        w_to Alike_Maze_5,
        d_to Alike_Maze_7,
        s_to Alike_Maze_8;

DeadendRoom Dead_End_1
  with  w_to Alike_Maze_4,
        out_to Alike_Maze_4;

DeadendRoom Dead_End_2
  with  w_to Alike_Maze_4,
        out_to Alike_Maze_4;

DeadendRoom Dead_End_3
  with  u_to Alike_Maze_3,
        out_to Alike_Maze_3;

MazeRoom Alike_Maze_7
  with  w_to Alike_Maze_5,
        u_to Alike_Maze_6,
        e_to Alike_Maze_8,
        s_to Alike_Maze_9;

MazeRoom Alike_Maze_8
  with  w_to Alike_Maze_6,
        e_to Alike_Maze_7,
        s_to Alike_Maze_8,
        u_to Alike_Maze_9,
        n_to Alike_Maze_10,
        d_to Dead_End_12;

MazeRoom Alike_Maze_9
  with  w_to Alike_Maze_7,
        n_to Alike_Maze_8,
        s_to Dead_End_4;

DeadendRoom Dead_End_4
  with  w_to Alike_Maze_9,
        out_to Alike_Maze_9;

MazeRoom Alike_Maze_10
  with  w_to Alike_Maze_8,
        n_to Alike_Maze_10,
        d_to Dead_End_5,
        e_to At_Brink_Of_Pit;

DeadendRoom Dead_End_5
  with  u_to Alike_Maze_10,
        out_to Alike_Maze_10;

! ------------------------------------------------------------------------------

Room    At_Brink_Of_Pit "At Brink of Pit"
  with  name 'brink' 'of' 'pit',
        description
            "You are on the brink of a thirty foot pit with a massive orange column down one wall.
             You could climb down here but you could not get back up.
             The maze continues at this level.",
        d_to In_Bird_Chamber,
        w_to Alike_Maze_10,
        s_to Dead_End_6,
        n_to Alike_Maze_12,
        e_to Alike_Maze_13;

Scenic  -> "massive orange column"
  with  name 'column' 'massive' 'orange' 'big' 'huge',
        description "It looks like you could climb down it.",
        before [;
          Climb:
            MovePlayer(d_obj);
            rtrue;
        ];

Scenic  -> "pit"
  with  name 'pit' 'thirty' 'foot' 'thirty-foot',
        description "You'll have to climb down to find out anything more...",
        before [;
          Climb:
            MovePlayer(d_obj);
            rtrue;
        ];

DeadendRoom Dead_End_6
  with  e_to At_Brink_Of_Pit,
        out_to At_Brink_Of_Pit;

! ------------------------------------------------------------------------------
!   A line of three vital junctions, east to west
! ------------------------------------------------------------------------------

Room    At_Complex_Junction "At Complex Junction"
  with  name 'complex' 'junction',
        description
            "You are at a complex junction.
             A low hands and knees passage from the north joins a higher crawl from the east
             to make a walking passage going west.
             There is also a large room above.
             The air is damp here.",
        u_to In_Dusty_Rock_Room,
        w_to In_Bedquilt,
        n_to In_Shell_Room,
        e_to In_Anteroom;

! ------------------------------------------------------------------------------

Room    In_Bedquilt "Bedquilt"
  with  name 'bedquilt',
        description
            "You are in bedquilt, a long east/west passage with holes everywhere.
             To explore at random select north, south, up, or down.",
        e_to At_Complex_Junction,
        w_to In_Swiss_Cheese_Room,
        s_to In_Slab_Room,
        u_to In_Dusty_Rock_Room,
        n_to At_Junction_Of_Three,
        d_to In_Anteroom,
        before [ destiny;
          Go:
            if (noun == s_obj or d_obj && random(100) <= 80) destiny = 1;
            if (noun == u_obj && random(100) <= 80)          destiny = 1;
            if (noun == u_obj && random(100) <= 50) destiny = In_Secret_N_S_Canyon_1;
            if (noun == n_obj && random(100) <= 60)          destiny = 1;
            if (noun == n_obj && random(100) <= 75) destiny = In_Large_Low_Room;
            if (destiny == 1)
                "You have crawled around in some little holes and wound up back
                 in the main passage.";
            if (destiny == 0) rfalse;
            PlayerTo(destiny);
            rtrue;
        ];

! ------------------------------------------------------------------------------

Room    In_Swiss_Cheese_Room "In Swiss Cheese Room"
  with  name 'swiss' 'cheese' 'room',
        description
            "You are in a room whose walls resemble swiss cheese.
             Obvious passages go west, east, ne, and nw.
             Part of the room is occupied by a large bedrock block.",
        w_to At_East_End_Of_Twopit_Room,
        s_to In_Tall_E_W_Canyon,
        ne_to In_Bedquilt,
        nw_to In_Oriental_Room,
        e_to In_Soft_Room,
        before [;
          Go:
            if ((noun == s_obj && random(100) <= 80) ||
                (noun == nw_obj && random(100) <= 50))
                "You have crawled around in some little holes and wound up
                 back in the main passage.";
        ];

Scenic  -> "bedrock block"
  with  name 'block' 'bedrock' 'large',
        description "It's just a huge block.",
        before [;
          LookUnder, Push, Pull, Take:
            "Surely you're joking.";
        ];

! ------------------------------------------------------------------------------
!   The Twopit Room area
! ------------------------------------------------------------------------------
!   Possible heights for the plant:
! ------------------------------------------------------------------------------

Constant TINY_P = 0;
Constant TALL_P = 1;
Constant HUGE_P = 2;

Room    At_West_End_Of_Twopit_Room "At West End of Twopit Room"
  with  name 'west' 'w//' 'end' 'of' 'twopit' 'room',
        description
            "You are at the west end of the twopit room.
             There is a large hole in the wall above the pit at this end of the room.",
        e_to At_East_End_Of_Twopit_Room,
        w_to In_Slab_Room,
        d_to In_West_Pit,
        u_to "It is too far up for you to reach.",
        before [;
          Enter:
            if (noun == HoleAbovePit_1) "It is too far up for you to reach.";
        ];

Object  PlantStickingUp "beanstalk"
  with  name 'plant' 'beanstalk' 'stalk' 'bean' 'giant' 'tiny' 'little'
             'murmuring' 'twelve' 'foot' 'tall' 'bellowing',
        describe [;
            if (Plant.height == TALL_P)
                "The top of a 12-foot-tall beanstalk is poking out of the west pit.";
            "There is a huge beanstalk growing out of the west pit up to the hole.";
        ],
        before [;
          Examine:
            RunRoutines(self, describe);
            rtrue;
          Climb:
            if (Plant.height == HUGE_P) <<Climb Plant>>;
        ],
        found_in At_West_End_Of_Twopit_Room At_East_End_Of_Twopit_Room,
  has   absent static;

Scenic  HoleAbovePit_1 "hole above pit"
  with  name 'hole' 'large' 'above' 'pit',
        description
            "The hole is in the wall above the pit at this end of the room.",
        found_in In_West_Pit At_West_End_Of_Twopit_Room;

! ------------------------------------------------------------------------------

Room    In_West_Pit "In West Pit"
  with  name 'in' 'west' 'pit',
        description
            "You are at the bottom of the western pit in the twopit room.
             There is a large hole in the wall about 25 feet above you.",
        before [;
          Climb:
            if (noun == Plant) rfalse;
            if (Plant.height == TINY_P)
                "There is nothing here to climb.
                 Use ~up~ or ~out~ to leave the pit.";
        ],
        u_to At_West_End_Of_Twopit_Room,
  has   nodwarf;

Object  -> Plant "plant"
  with  name 'plant' 'beanstalk' 'stalk' 'bean' 'giant' 'tiny' 'little'
             'murmuring' 'twelve' 'foot' 'tall' 'bellowing',
        describe [;
            switch (self.height) {
              TINY_P:
                "There is a tiny little plant in the pit, murmuring ~Water, water, ...~";
              TALL_P:
                "There is a 12-foot-tall beanstalk stretching up out of the pit, bellowing ~Water!! Water!!~";
              HUGE_P:
                "There is a gigantic beanstalk stretching all the way up to the hole.";
            }
        ],
        before [;
          Climb:
            switch (self.height) {
              TINY_P:
                "It's just a little plant!";
              TALL_P:
                print
                    "You have climbed up the plant and out of the pit.^";
                PlayerTo(At_West_End_Of_Twopit_Room);
                rtrue;
              HUGE_P:
                print
                    "You clamber up the plant and scurry through the hole at the top.^";
                PlayerTo(In_Narrow_Corridor);
                rtrue;
            }
          Take:
            "The plant has exceptionally deep roots and cannot be pulled free.";
          Water:
            if (bottle notin player)
                "You have nothing to water the plant with.";
            switch (child(bottle)) {
              nothing:
                "The bottle is empty.";
              oil_in_the_bottle:
                remove oil_in_the_bottle;
                "The plant indignantly shakes the oil off its leaves and asks, ~Water?~";
            }
            remove water_in_the_bottle;
            switch ((self.height)++) {
              TINY_P:
                print
                    "The plant spurts into furious growth for a few seconds.^^";
                give PlantStickingUp ~absent;
              TALL_P:
                print
                    "The plant grows explosively, almost filling the bottom of the pit.^^";
              HUGE_P:
                print
                    "You've over-watered the plant! It's shriveling up! It's, it's...^^";
                give PlantStickingUp absent;
                remove PlantStickingUp;
                self.height = TINY_P;
            }
            <<Examine self>>;
          Oil:
            <<Water self>>;
          Examine:
            self.describe();
            rtrue;
        ],
        height TINY_P;

! ------------------------------------------------------------------------------

Room    At_East_End_Of_Twopit_Room "At East End of Twopit Room"
  with  name 'east' 'e//' 'end' 'of' 'twopit' 'room',
        description
            "You are at the east end of the twopit room.
             The floor here is littered with thin rock slabs, which make it easy to descend the pits.
             There is a path here bypassing the pits to connect passages from east and west.
             There are holes all over,
             but the only big one is on the wall directly over the west pit where you can't get to it.",
        e_to In_Swiss_Cheese_Room,
        w_to At_West_End_Of_Twopit_Room,
        d_to In_East_Pit;

Scenic  -> "thin rock slabs"
  with  name 'slabs' 'slab' 'rocks' 'stairs' 'thin' 'rock',
        description "They almost form natural stairs down into the pit.",
        before [;
          LookUnder, Push, Pull, Take:
            "Surely you're joking. You'd have to blast them aside.";
        ],
  has   multitude;

! ------------------------------------------------------------------------------

Room    In_East_Pit "In East Pit"
  with  name 'in' 'east' 'e//' 'pit',
        description
            "You are at the bottom of the eastern pit in the twopit room.
             There is a small pool of oil in one corner of the pit.",
        u_to At_East_End_Of_Twopit_Room,
  has   nodwarf;

Scenic  -> Oil "pool of oil"
  with  name 'pool' 'oil' 'small',
        description "It looks like ordinary oil.",
        before [;
          Drink:
            "Absolutely not.";
          Take:
            if (bottle notin player)
                "You have nothing in which to carry the oil.";
            <<Fill bottle>>;
          Insert:
            if (second == bottle) <<Fill bottle>>;
            "You have nothing in which to carry the oil.";
        ];

Scenic  "hole above pit"
  with  name 'hole' 'large' 'above' 'pit',
        description "The hole is in the wall above you.",
        found_in In_East_Pit At_East_End_Of_Twopit_Room;

! ------------------------------------------------------------------------------

Room    In_Slab_Room "Slab Room"
  with  name 'slab' 'room',
        description
            "You are in a large low circular chamber
             whose floor is an immense slab fallen from the ceiling (slab room).
             East and west there once were large passages, but they are now filled with boulders.
             Low small passages go north and south, and the south one quickly bends west around the boulders.",
        s_to At_West_End_Of_Twopit_Room,
        u_to In_Secret_N_S_Canyon_0,
        n_to In_Bedquilt;

Scenic  -> "slab"
  with  name 'slab' 'immense',
        description "It is now the floor here.",
        before [;
          LookUnder, Push, Pull, Take:
            "Surely you're joking.";
        ];

Scenic  -> "boulders"
  with  name 'boulder' 'boulders' 'rocks' 'stones',
        description "They're just ordinary boulders.",
  has   multitude;

! ------------------------------------------------------------------------------
!   A small network of Canyons, mainly Secret
! ------------------------------------------------------------------------------

Room    In_Secret_N_S_Canyon_0 "Secret N/S Canyon"
  with  name 'secret' 'n/s' 'canyon' '0//',
        description
            "You are in a secret N/S canyon above a large room.",
        d_to In_Slab_Room,
        s_to In_Secret_Canyon,
        n_to In_Mirror_Canyon,
        before [;
          Go:
            if (noun == s_obj) canyon_from = self;
        ];

Room    In_Secret_N_S_Canyon_1 "Secret N/S Canyon"
  with  name 'secret' 'n/s' 'canyon' '1//',
        description "You are in a secret N/S canyon above a sizable passage.",
        n_to At_Junction_Of_Three,
        d_to In_Bedquilt,
        s_to Atop_Stalactite;

Room    At_Junction_Of_Three "Junction of Three Secret Canyons"
  with  name 'junction' 'of' 'three' 'secret' 'canyons',
        description
            "You are in a secret canyon at a junction of three canyons, bearing north, south, and se.
             The north one is as tall as the other two combined.",
        se_to In_Bedquilt,
        s_to In_Secret_N_S_Canyon_1,
        n_to At_Window_On_Pit_2;

Room    In_Large_Low_Room "Large Low Room"
  with  name 'large' 'low' 'room',
        description
            "You are in a large low room. Crawls lead north, se, and sw.",
        sw_to In_Sloping_Corridor,
        se_to In_Oriental_Room,
        n_to Dead_End_Crawl;

Room    Dead_End_Crawl "Dead End Crawl"
  with  name 'dead' 'end' 'crawl',
        description "This is a dead end crawl.",
        s_to In_Large_Low_Room,
        out_to In_Large_Low_Room;

Room    In_Secret_E_W_Canyon "Secret E/W Canyon Above Tight Canyon"
  with  name 'secret' 'e/w' 'canyon' 'above' 'tight' 'canyon',
        description
            "You are in a secret canyon which here runs E/W.
             It crosses over a very tight canyon 15 feet below.
             If you go down you may not be able to get back up.",
        e_to In_Hall_Of_Mt_King,
        w_to In_Secret_Canyon,
        before [;
          Go:
            if (noun == w_obj) canyon_from = self;
        ],
        d_to In_N_S_Canyon;

Room    In_N_S_Canyon "N/S Canyon"
  with  name 'n/s' 'canyon',
        description "You are at a wide place in a very tight N/S canyon.",
        s_to Canyon_Dead_End,
        n_to In_Tall_E_W_Canyon;

Room    Canyon_Dead_End "Canyon Dead End"
  with  description "The canyon here becomes too tight to go further south.",
        n_to In_N_S_Canyon;

Room    In_Tall_E_W_Canyon "In Tall E/W Canyon"
  with  name 'tall' 'e/w' 'canyon',
        description
            "You are in a tall E/W canyon. A low tight crawl goes 3 feet north
             and seems to open up.",
        e_to In_N_S_Canyon,
        w_to Dead_End_8,
        n_to In_Swiss_Cheese_Room;

! ------------------------------------------------------------------------------

Room    Atop_Stalactite "Atop Stalactite"
  with  name 'atop' 'stalactite',
        description
            "A large stalactite extends from the roof and almost reaches the floor below.
             You could climb down it, and jump from it to the floor,
             but having done so you would be unable to reach it to climb back up.",
        n_to In_Secret_N_S_Canyon_1,
        d_to [;
            if (random(100) <= 40) return Alike_Maze_6;
            if (random(100) <= 50) return Alike_Maze_9;
            return Alike_Maze_4;
        ],
        before [;
          Jump, Climb:
            <<Go d_obj>>;
        ];

Scenic  -> "stalactite"
  with  name 'stalactite' 'stalagmite' 'stalagtite' 'large',
        description
            "You could probably climb down it, but you can forget coming back up.",
        before [;
          LookUnder, Push, Take:
            "Do get a grip on yourself.";
        ];

! ------------------------------------------------------------------------------
!   Here be dragons
! ------------------------------------------------------------------------------

Room    In_Secret_Canyon "Secret Canyon"
  with  name 'secret' 'canyon',
        description
            "You are in a secret canyon which exits to the north and east.",
        e_to [;
            if (canyon_from == In_Secret_E_W_Canyon) return canyon_from;
            if (Dragon in location)
                "The dragon looks rather nasty. You'd best not try to get by.";
            return In_Secret_E_W_Canyon;
        ],
        n_to [;
            if (canyon_from == In_Secret_N_S_Canyon_0) return canyon_from;
            if (Dragon in location)
                "The dragon looks rather nasty. You'd best not try to get by.";
            return In_Secret_N_S_Canyon_0;
        ],
        out_to [;
            return canyon_from;
        ],
        before [;
            if (action == ##Yes && Dragon.is_being_attacked) {
                remove Dragon;
                move DragonCorpse to location;
                Dragon.is_being_attacked = false;
                "Congratulations! You have just vanquished a dragon with your bare hands!
                 (Unbelievable, isn't it?)";
            }
            if (action == ##No && Dragon.is_being_attacked) {
                Dragon.is_being_attacked = false;
                "I should think not.";
            }
            Dragon.is_being_attacked = false;
        ];

Object  -> Dragon "dragon"
  with  name 'dragon' 'monster' 'beast' 'lizard' 'huge' 'green' 'fierce' 'scaly'
             'giant' 'ferocious',
        description "I wouldn't mess with it if I were you.",
        initial "A huge green fierce dragon bars the way!",
        life [;
          Attack:
            self.is_being_attacked = true;
            "With what? Your bare hands?";
          Give:
            "The dragon is implacable.";
          ThrowAt:
            if (noun ~= axe)
                "You'd probably be better off using your bare hands than that thing!";
            move axe to location;
            "The axe bounces harmlessly off the dragon's thick scales.";
        ],
        is_being_attacked false,
  has   animate;

Treasure -> "Persian rug"
  with  name 'rug' 'persian' 'persian' 'fine' 'finest' 'dragon^s',
        describe [;
            if (Dragon in location)
                "The dragon is sprawled out on the Persian rug!";
            "The Persian rug is spread out on the floor here.";
        ],
        before [;
          Take:
            if (Dragon in location)
                "You'll need to get the dragon to move first!";
        ],
        depositpoints 14;

Object  DragonCorpse "dragon's body"
  with  name 'dragon' 'corpse' 'dead' 'dragon^s' 'body',
        initial "The body of a huge green dead dragon is lying off to one side.",
        before [;
          Attack:
            "You've already done enough damage!";
        ],
  has   static;

! ------------------------------------------------------------------------------
!   And more of the Alike Maze
! ------------------------------------------------------------------------------

DeadendRoom Dead_End_8
  with  description "The canyon runs into a mass of boulders -- dead end.",
        s_to In_Tall_E_W_Canyon,
        out_to In_Tall_E_W_Canyon;

MazeRoom Alike_Maze_11
  with  n_to Alike_Maze_1,
        w_to Alike_Maze_11,
        s_to Alike_Maze_11,
        e_to Dead_End_9,
        ne_to Dead_End_10;

DeadendRoom Dead_End_9
  with  w_to Alike_Maze_11,
        out_to Alike_Maze_11;

DeadendRoom Dead_End_10
  with  s_to Alike_Maze_3,
        out_to Alike_Maze_3;

MazeRoom Alike_Maze_12
  with  s_to At_Brink_Of_Pit,
        e_to Alike_Maze_13,
        w_to Dead_End_11;

MazeRoom Alike_Maze_13
  with  n_to At_Brink_Of_Pit,
        w_to Alike_Maze_12,
        nw_to Dead_End_13;

DeadendRoom Dead_End_11
  with  e_to Alike_Maze_12,
        out_to Alike_Maze_12;

DeadendRoom Dead_End_12
  with  u_to Alike_Maze_8,
        out_to Alike_Maze_8;

MazeRoom Alike_Maze_14
  with  u_to Alike_Maze_4,
        d_to Alike_Maze_4;

DeadendRoom Dead_End_13
  class Room
  with  name 'pirate^s' 'dead' 'end' 'treasure' 'chest',
        se_to Alike_Maze_13,
        out_to Alike_Maze_13,
        description "This is the pirate's dead end.",
        initial [;
            StopDaemon(Pirate);
            if (treasure_chest in self && treasure_chest hasnt moved)
                "You've found the pirate's treasure chest!";
        ],
  has   nodwarf;

Treasure -> treasure_chest "treasure chest"
  with  name 'chest' 'box' 'treasure' 'riches' 'pirate' 'pirate^s' 'treasure',
        description
            "It's the pirate's treasure chest, filled with riches of all kinds!",
        initial "The pirate's treasure chest is here!",
        depositpoints 12;

! ------------------------------------------------------------------------------
!   Above the beanstalk: the Giant Room and the Waterfall
! ------------------------------------------------------------------------------

Room    In_Narrow_Corridor "In Narrow Corridor"
  with  name 'narrow' 'corridor',
        description
            "You are in a long, narrow corridor stretching out of sight to the west.
             At the eastern end is a hole through which you can see a profusion of leaves.",
        d_to In_West_Pit,
        w_to In_Giant_Room,
        e_to In_West_Pit,
        before [;
          Jump:
            deadflag = 1;
            "You fall and break your neck!";
        ];

Scenic  -> "leaves"
  with  name 'leaf' 'leaves' 'plant' 'tree' 'stalk' 'beanstalk' 'profusion',
        article "some",
        description
            "The leaves appear to be attached to the beanstalk you climbed to get here.",
        before [;
          Count:
            "69,105.";                  ! (I thank Rene Schnoor for counting them)
        ];

! ------------------------------------------------------------------------------

Room    At_Steep_Incline "Steep Incline Above Large Room"
  with  name 'steep' 'incline' 'above' 'large' 'room',
        description
            "You are at the top of a steep incline above a large room.
             You could climb down here, but you would not be able to climb up.
             There is a passage leading back to the north.",
        n_to In_Cavern_With_Waterfall,
        d_to In_Large_Low_Room;

! ------------------------------------------------------------------------------

Room    In_Giant_Room "Giant Room"
  with  name 'giant' 'room',
        description
            "You are in the giant room.
             The ceiling here is too high up for your lamp to show it.
             Cavernous passages lead east, north, and south.
             On the west wall is scrawled the inscription, ~Fee fie foe foo~ [sic].",
        s_to In_Narrow_Corridor,
        e_to At_Recent_Cave_In,
        n_to In_Immense_N_S_Passage;

Scenic  -> "scrawled inscription"
  with  name 'inscription' 'writing' 'scrawl' 'scrawled',
        description "It says, ~Fee fie foe foo [sic].~";

Treasure -> golden_eggs "nest of golden eggs"
  with  name 'eggs' 'egg' 'nest' 'golden' 'beautiful',
        description "The nest is filled with beautiful golden eggs!",
        initial "There is a large nest here, full of golden eggs!",
        depositpoints 14,
  has   multitude;

! ------------------------------------------------------------------------------

Room    At_Recent_Cave_In "Recent Cave-in"
  with  description "The passage here is blocked by a recent cave-in.",
        s_to In_Giant_Room;

! ------------------------------------------------------------------------------

Room    In_Immense_N_S_Passage "Immense N/S Passage"
  with  name 'immense' 'n/s' 'passage',
        description "You are at one end of an immense north/south passage.",
        s_to In_Giant_Room,
        n_to [;
            if (RustyDoor has locked) <<Open RustyDoor>>;
            if (RustyDoor hasnt open) {
                give RustyDoor open;
                print "(first wrenching the door open)^";
            }
            return RustyDoor;
        ];

Object  -> RustyDoor "rusty door"
  with  name 'door' 'hinge' 'hinges' 'massive' 'rusty' 'iron',
        description "It's just a big iron door.",
        when_closed "The way north is barred by a massive, rusty, iron door.",
        when_open "The way north leads through a massive, rusty, iron door.",
        door_to In_Cavern_With_Waterfall,
        door_dir n_to,
        before [;
          Open:
            if (self has locked)
                "The hinges are quite thoroughly rusted now and won't budge.";
          Close:
            if (self has open)
                "With all the effort it took to get the door open,
                 I wouldn't suggest closing it again.";
            "No problem there -- it already is.";
          Oil:
            if (bottle in player && oil_in_the_bottle in bottle) {
                remove oil_in_the_bottle;
                give self ~locked openable;
                "The oil has freed up the hinges so that the door will now move,
                 although it requires some effort.";
            }
            else
                "You have nothing to oil it with.";
          Water:
            if (bottle in player && water_in_the_bottle in bottle) {
                remove water_in_the_bottle;
                give self locked ~open;
                "The hinges are quite thoroughly rusted now and won't budge.";
            }
            else
                "You have nothing to water it with.";
        ],
        after [;
          Open:
            "The door heaves open with a shower of rust.";
        ],
  has   static door locked;

! ------------------------------------------------------------------------------

Room    In_Cavern_With_Waterfall "In Cavern With Waterfall"
  with  name 'cavern' 'with' 'waterfall',
        description
            "You are in a magnificent cavern with a rushing stream,
             which cascades over a sparkling waterfall into a roaring whirlpool
             which disappears through a hole in the floor.
             Passages exit to the south and west.",
        s_to In_Immense_N_S_Passage,
        w_to At_Steep_Incline;

Scenic  -> "waterfall"
  with  name 'waterfall' 'whirlpool' 'sparkling' 'whirling',
        description "Wouldn't want to go down in in a barrel!";

Treasure -> trident "jeweled trident"
  with  name 'trident' 'jeweled' 'jewel-encrusted' 'encrusted' 'fabulous',
        description "The trident is covered with fabulous jewels!",
        initial "There is a jewel-encrusted trident here!",
        depositpoints 14;

! ------------------------------------------------------------------------------
!   The caves around Bedquilt
! ------------------------------------------------------------------------------

Room    In_Soft_Room "In Soft Room"
  with  name 'soft' 'room',
        description
            "You are in the soft room.
             The walls are covered with heavy curtains, the floor with a thick pile carpet.
             Moss covers the ceiling.",
        w_to In_Swiss_Cheese_Room;

Scenic  -> "carpet"
  with  name 'carpet' 'shag' 'pile' 'heavy' 'thick',
        description "The carpet is quite plush.";

Scenic  -> "curtains"
  with  name 'curtain' 'curtains' 'heavy' 'thick',
        description "They seem to absorb sound very well.",
        before [;
          Take:
            "Now don't go ripping up the place!";
          LookUnder, Search:
            "You don't find anything exciting behind the curtains.";
        ];

Scenic  -> "moss"
  with  name 'moss' 'typical' 'everyday',
        description "It just looks like your typical, everyday moss.",
        before [;
          Take:
            "It crumbles to nothing in your hands.";
        ],
  has   edible;

Object  -> velvet_pillow "velvet pillow"
  with  name 'pillow' 'velvet' 'small',
        description "It's just a small velvet pillow.",
        initial "A small velvet pillow lies on the floor.";

! ------------------------------------------------------------------------------

Room    In_Oriental_Room "Oriental Room"
  with  name 'oriental' 'room',
        description
            "This is the oriental room.
             Ancient oriental cave drawings cover the walls.
             A gently sloping passage leads upward to the north, another passage leads se,
             and a hands and knees crawl leads west.",
        w_to In_Large_Low_Room,
        se_to In_Swiss_Cheese_Room,
        u_to In_Misty_Cavern,
        n_to In_Misty_Cavern;

Scenic  -> "ancient oriental drawings"
  with  name 'paintings' 'drawings' 'art' 'cave' 'ancient' 'oriental',
        description "They seem to depict people and animals.",
  has   multitude;

Treasure -> ming_vase "ming vase"
  with  name 'vase' 'ming' 'delicate',
        description "It's a delicate, precious, ming vase!",
        after [;
          Drop:
            if (velvet_pillow in location) {
                print "(coming to rest, delicately, on the velvet pillow)^";
                rfalse;
            }
            remove ming_vase;
            move shards to location;
            "The ming vase drops with a delicate crash.";
        ],
        before [;
          Attack:
            remove ming_vase;
            move shards to location;
            "You have taken the vase and
            hurled it delicately to the ground.";
          Receive:
            "The vase is too fragile to use as a container.";
        ],
        depositpoints 14;

Object  shards "some worthless shards of pottery"
  with  name 'pottery' 'shards' 'remains' 'vase' 'worthless',
        description
            "They look to be the remains of what was once a beautiful vase.
             I guess some oaf must have dropped it.",
        initial "The floor is littered with worthless shards of pottery.",
  has   multitude;

! ------------------------------------------------------------------------------

Room    In_Misty_Cavern "Misty Cavern"
  with  name 'misty' 'cavern',
        description
            "You are following a wide path around the outer edge of a large cavern.
             Far below, through a heavy white mist, strange splashing noises can be heard.
             The mist rises up through a fissure in the ceiling.
             The path exits to the south and west.",
        s_to In_Oriental_Room,
        w_to In_Alcove;

Scenic  -> "fissure"
  with  name 'fissure' 'ceiling',
        description "You can't really get close enough to examine it.";

! ------------------------------------------------------------------------------
!   Plovers and pyramids
! ------------------------------------------------------------------------------

Room    In_Alcove "Alcove"
  with  name 'alcove',
        description
            "You are in an alcove.
             A small northwest path seems to widen after a short distance.
             An extremely tight tunnel leads east.
             It looks like a very tight squeeze.
             An eerie light can be seen at the other end.",
        nw_to In_Misty_Cavern,
        e_to [ j;
            j = children(player);
            if (j == 0 || (j == 1 && egg_sized_emerald in player))
                return In_Plover_Room;
            "Something you're carrying won't fit through the tunnel with you.
             You'd best take inventory and drop something.";
        ];

! ------------------------------------------------------------------------------

Room    In_Plover_Room "Plover Room"
  with  name 'plover' 'room',
        description
            "You're in a small chamber lit by an eerie green light.
             An extremely narrow tunnel exits to the west.
             A dark corridor leads northeast.",
        ne_to In_Dark_Room,
        w_to [ j;
            j = children(player);
            if (j == 0 || (j == 1 && egg_sized_emerald in player))
                return In_Alcove;
            "Something you're carrying won't fit through the tunnel with you.
             You'd best take inventory and drop something.";
        ],
        before [;
          Plover:
            if (egg_sized_emerald in player) {
                move egg_sized_emerald to In_Plover_Room;
                score = score - 5;
            }
            PlayerTo(At_Y2);
            rtrue;
          Go:
            if (noun == out_obj)
                <<Go w_obj>>;
        ],
  has   light;

Treasure -> egg_sized_emerald "emerald the size of a plover's egg"
  with  name 'emerald' 'egg-sized' 'egg' 'sized' 'plover^s',
        article "an",
        description "Plover's eggs, by the way, are quite large.",
        initial "There is an emerald here the size of a plover's egg!",
        depositpoints 14;

! ------------------------------------------------------------------------------

Room    In_Dark_Room "The Dark Room"
  with  name 'dark' 'room',
        description
            "You're in the dark-room. A corridor leading south is the only exit.",
        s_to In_Plover_Room,
  has   nodwarf;

Object  -> "stone tablet"
  with  name 'tablet' 'massive' 'stone',
        initial
		    "A massive stone tablet imbedded in the wall reads:
		     ~Congratulations on bringing light into the dark-room!~",
  has   static;

Treasure -> "platinum pyramid"
  with  name 'platinum' 'pyramid' 'platinum' 'pyramidal',
        description "The platinum pyramid is 8 inches on a side!",
        initial "There is a platinum pyramid here, 8 inches on a side!",
        depositpoints 14;

! ------------------------------------------------------------------------------
!   North of the complex junction: a long up-down corridor
! ------------------------------------------------------------------------------

Room    In_Arched_Hall "Arched Hall"
  with  name 'arched' 'hall',
        description
            "You are in an arched hall.
             A coral passage once continued up and east from here, but is now blocked by debris.
             The air smells of sea water.",
        d_to In_Shell_Room;

! ------------------------------------------------------------------------------

Room    In_Shell_Room "Shell Room"
  with  name 'shell' 'room',
        description
            "You're in a large room carved out of sedimentary rock.
             The floor and walls are littered with bits of shells imbedded in the stone.
             A shallow passage proceeds downward, and a somewhat steeper one leads up.
             A low hands and knees passage enters from the south.",
        u_to In_Arched_Hall,
        d_to In_Ragged_Corridor,
        s_to [;
            if (giant_bivalve in player) {
                if (giant_bivalve has open)
                    "You can't fit this five-foot oyster through that little passage!";
                else
                    "You can't fit this five-foot clam through that little passage!";
            }
            return At_Complex_Junction;
        ];

Object  -> giant_bivalve "giant clam"
  with  name 'giant' 'clam' 'oyster' 'bivalve',
        describe [;
            if (self.has_been_opened)
                "There is an enormous oyster here with its shell tightly closed.";
            "There is an enormous clam here with its shell tightly closed.";
        ],
        before [;
          Examine:
            if (location == At_Ne_End or At_Sw_End)
                "Interesting.
                 There seems to be something written on the underside of the oyster:
                 ^^
                 ~There is something strange about this place,
                 such that one of the curses I've always known now has a new effect.~";
            "A giant bivalve of some kind.";
          Open:
            "You aren't strong enough to open the clam with your bare hands.";
          Unlock:
            if (second ~= trident)
                print_ret (The) second, " isn't strong enough to open the clam.";
            if (self.has_been_opened)
                "The oyster creaks open, revealing nothing but oyster inside.
                 It promptly snaps shut again.";
            self.has_been_opened = true;
            move pearl to In_A_Cul_De_Sac;
            "A glistening pearl falls out of the clam and rolls away.
             Goodness, this must really be an oyster.
             (I never was very good at identifying bivalves.)
             Whatever it is, it has now snapped shut again.";
          Attack:
            "The shell is very strong and is impervious to attack.";
        ],
        has_been_opened false;

Treasure pearl "glistening pearl"
  with  name 'pearl' 'glistening' 'incredible' 'incredibly' 'large',
        description "It's incredibly large!",
        initial "Off to one side lies a glistening pearl!",
        depositpoints 14;

! ------------------------------------------------------------------------------

Room    In_Ragged_Corridor "Ragged Corridor"
  with  name 'ragged' 'corridor',
        description "You are in a long sloping corridor with ragged sharp walls.",
        u_to In_Shell_Room,
        d_to In_A_Cul_De_Sac;

Room    In_A_Cul_De_Sac "Cul-de-Sac"
  with  name 'cul-de-sac' 'cul' 'de' 'sac',
        description "You are in a cul-de-sac about eight feet across.",
        u_to In_Ragged_Corridor,
        out_to In_Ragged_Corridor;

! ------------------------------------------------------------------------------
!   Witt's End: Cave under construction
! ------------------------------------------------------------------------------

Room    In_Anteroom "In Anteroom"
  with  name 'anteroom',
        description
            "You are in an anteroom leading to a large passage to the east.
             Small passages go west and up.
             The remnants of recent digging are evident.",
        u_to At_Complex_Junction,
        w_to In_Bedquilt,
        e_to At_Witts_End;

Object  -> "sign"
  with  name 'sign' 'witt' 'company' 'construction',
        initial
            "A sign in midair here says ~Cave under construction beyond this point.
             Proceed at own risk. [Witt Construction Company]~",
        before [;
          Take:
            "It's hanging way above your head.";
        ],
  has   static;

Object  -> "recent issues of ~Spelunker Today~"
  with  name 'magazines' 'magazine' 'issue' 'issues' 'spelunker' 'today',
        article "a few",
        description "I'm afraid the magazines are written in Dwarvish.",
        initial "There are a few recent issues of ~Spelunker Today~ magazine here.",
        after [;
          Take:
            if (location == At_Witts_End) score--;
          Drop:
            if (location == At_Witts_End) {
                score++;
                "You really are at wit's end.";
            }
        ],
  has   multitude;

! ------------------------------------------------------------------------------

Room    At_Witts_End "At Witt's End"
  with  name 'witt^s' 'witts' 'end',
        description
            "You are at Witt's End. Passages lead off in *all* directions.",
        w_to
            "You have crawled around in some little holes
             and found your way blocked by a recent cave-in.
             You are now back in the main passage.",
        before [;
          Go:
            if (noun ~= w_obj && random(100) <= 95)
                "You have crawled around in some little holes and wound up
                 back in the main passage.";
            PlayerTo(In_Anteroom);
            rtrue;
        ];

! ------------------------------------------------------------------------------
!   North of the secret canyons, on the other side of the pit
! ------------------------------------------------------------------------------

Room    In_Mirror_Canyon "In Mirror Canyon"
  with  name 'mirror' 'canyon',
        description
            "You are in a north/south canyon about 25 feet across.
             The floor is covered by white mist seeping in from the north.
             The walls extend upward for well over 100 feet.
             Suspended from some unseen point far above you,
             an enormous two-sided mirror is hanging parallel to and midway between the canyon walls.
             ^^
             A small window can be seen in either wall, some fifty feet up.",
        s_to In_Secret_N_S_Canyon_0,
        n_to At_Reservoir;

Object  -> "suspended mirror"
  with  name 'mirror' 'massive' 'enormous' 'hanging' 'suspended' 'dwarves^'
             'two-sided' 'two' 'sided',
        description
            "The mirror is obviously provided for the use of the dwarves who,
             as you know, are extremely vain.",
        initial
            "The mirror is obviously provided for the use of the dwarves,
             who as you know, are extremely vain.",
        before [;
          Attack, Remove:
            "You can't reach it from here.";
        ],
  has   static;

! ------------------------------------------------------------------------------

Room    At_Window_On_Pit_2 "At Window on Pit"
  with  name 'window' 'on' 'pit' 'west' 'w//',
        description
            "You're at a low window overlooking a huge pit, which extends up out of sight.
             A floor is indistinctly visible over 50 feet below.
             Traces of white mist cover the floor of the pit, becoming thicker to the left.
             Marks in the dust around the window would seem to indicate that someone has been here recently.
             Directly across the pit from you and 25 feet away
             there is a similar window looking into a lighted room.
             A shadowy figure can be seen there peering back at you.",
        w_to At_Junction_Of_Three,
        cant_go "The only passage is back west to the junction.",
        before [;
          Jump:
            deadflag = 1;
            "You jump and break your neck!";
          WaveHands:
            "The shadowy figure waves back at you!";
        ];

! ------------------------------------------------------------------------------

Room    At_Reservoir "At Reservoir"
  with  name 'reservoir',
        description
            "You are at the edge of a large underground reservoir.
             An opaque cloud of white mist fills the room and rises rapidly upward.
             The lake is fed by a stream, which tumbles out of a hole in the wall about 10 feet overhead
             and splashes noisily into the water somewhere within the mist.
             The only passage goes back toward the south.",
        s_to In_Mirror_Canyon,
        out_to In_Mirror_Canyon,
        before [;
          Swim:
            "The water is icy cold, and you would soon freeze to death.";
        ];

! ------------------------------------------------------------------------------
!   The Chasm and the Troll Bridge
! ------------------------------------------------------------------------------

Room    In_Sloping_Corridor "Sloping Corridor"
  with  name 'sloping' 'corridor',
        description
            "You are in a long winding corridor sloping out of sight in both directions.",
        d_to In_Large_Low_Room,
        u_to On_Sw_Side_Of_Chasm,
        cant_go "The corridor slopes steeply up and down.";

Room    On_Sw_Side_Of_Chasm "On SW Side of Chasm"
  with  name 'southwest' 'sw' 'side' 'of' 'chasm',
        description
            "You are on one side of a large, deep chasm.
             A heavy white mist rising up from below obscures all view of the far side.
             A southwest path leads away from the chasm into a winding corridor.",
        ne_to CrossRicketyBridge,
        sw_to In_Sloping_Corridor,
        d_to In_Sloping_Corridor,
        cant_go "The path winds southwest.",
        before [;
          Jump:
            if (RicketyBridge in self)
                "I respectfully suggest you go across the bridge instead of jumping.";
            deadflag = 1;
            "You didn't make it.";
        ];

[ CrossRicketyBridge;
    if (Troll.has_caught_treasure || Troll in nothing) {
        Troll.has_caught_treasure = false;
        if (Bear.is_following_you) {
            remove Bear;
            remove self;
            give Wreckage ~absent;
            remove RicketyBridge;
            give RicketyBridge absent;
            StopDaemon(Bear);
            deadflag = 1;
            "Just as you reach the other side, the bridge buckles beneath the weight of the bear,
             which was still following you around.
             You scrabble desperately for support,
             but as the bridge collapses you stumble back and fall into the chasm.";
        }
        return RicketyBridge;
    }
    if (Troll in location) "The troll refuses to let you cross.";
    move Troll to location;
    "The troll steps out from beneath the bridge and blocks your way.";
];

Object  -> RicketyBridge "rickety bridge"
  with  name 'bridge' 'rickety' 'unstable' 'wobbly' 'rope',
        description "It just looks like an ordinary, but unstable, bridge.",
        describe [;
            print
                "A rickety wooden bridge extends across the chasm, vanishing into the mist.
                 ^^
                 A sign posted on the bridge reads, ~Stop! Pay troll!~^";
            if (Troll notin location)
                "The troll is nowhere to be seen.";
            rtrue;
        ],
        door_dir [;
            if (location == On_Sw_Side_Of_Chasm) return ne_to;
            return sw_to;
        ],
        door_to [;
            if (location == On_Sw_Side_Of_Chasm) return On_Ne_Side_Of_Chasm;
            return On_Sw_Side_Of_Chasm;
        ],
        found_in On_Sw_Side_Of_Chasm On_Ne_Side_Of_Chasm,
  has   static door open;

Object  -> -> Troll "burly troll"
  with  name 'troll' 'burly',
        description
            "Trolls are close relatives with rocks and have skin as tough as that of a rhinoceros.",
        initial
            "A burly troll stands by the bridge
             and insists you throw him a treasure before you may cross.",
        life [;
          Attack:
            "The troll laughs aloud at your pitiful attempt to injure him.";
          ThrowAt, Give:
            if (noun ofclass Treasure) {
                remove noun;
                move self to RicketyBridge;
                self.has_caught_treasure = true;
                score = score - 5;
                "The troll catches your treasure and scurries away out of sight.";
            }
            if (noun == tasty_food)
                "Gluttony is not one of the troll's vices. Avarice, however, is.";
            "The troll deftly catches ", (the) noun,
                ", examines it carefully, and tosses it back, declaring,
                ~Good workmanship, but it's not valuable enough.~";
          Order:
            "You'll be lucky.";
          Answer, Ask:
            "Trolls make poor conversation.";
        ],
        has_caught_treasure false,
  has   animate;

Object  Wreckage "wreckage of bridge"
  with  name 'wreckage' 'wreck' 'bridge' 'dead' 'bear',
        initial
            "The wreckage of the troll bridge (and a dead bear)
             can be seen at the bottom of the chasm.",
        before [;
            "The wreckage is too far below.";
        ],
        found_in On_Sw_Side_Of_Chasm On_Ne_Side_Of_Chasm,
  has   static absent;

! ------------------------------------------------------------------------------

Room    On_Ne_Side_Of_Chasm "On NE Side of Chasm"
  with  name 'northeast' 'ne' 'side' 'of' 'chasm',
        description
            "You are on the far side of the chasm.
             A northeast path leads away from the chasm on this side.",
        sw_to CrossRicketyBridge,
        ne_to In_Corridor,
        before [;
          Jump:
            if (RicketyBridge in self)
                "I respectfully suggest you go across the bridge instead of jumping.";
            deadflag = 1;
            "You didn't make it.";
        ],
  has   nodwarf;

Room    In_Corridor "In Corridor"
  with  name 'corridor',
        description
            "You're in a long east/west corridor.
             A faint rumbling noise can be heard in the distance.",
        w_to On_Ne_Side_Of_Chasm,
        e_to At_Fork_In_Path,
  has   nodwarf;

! ------------------------------------------------------------------------------
!   The Volcano
! ------------------------------------------------------------------------------

Room    At_Fork_In_Path "At Fork in Path"
  with  name 'fork' 'in' 'path',
        description
            "The path forks here. The left fork leads northeast.
             A dull rumbling seems to get louder in that direction.
             The right fork leads southeast down a gentle slope.
             The main corridor enters from the west.",
        w_to In_Corridor,
        ne_to At_Junction_With_Warm_Walls,
        se_to In_Limestone_Passage,
        d_to In_Limestone_Passage,
  has   nodwarf;

! ------------------------------------------------------------------------------

Room    At_Junction_With_Warm_Walls "At Junction With Warm Walls"
  with  name 'junction' 'with' 'warm' 'walls',
        description
            "The walls are quite warm here.
             From the north can be heard a steady roar,
             so loud that the entire cave seems to be trembling.
             Another passage leads south, and a low crawl goes east.",
        s_to At_Fork_In_Path,
        n_to At_Breath_Taking_View,
        e_to In_Chamber_Of_Boulders,
  has   nodwarf;

! ------------------------------------------------------------------------------

Room    At_Breath_Taking_View "At Breath-Taking View"
  with  name 'breath-taking' 'breathtaking' 'breath' 'taking' 'view',
        description
            "You are on the edge of a breath-taking view.
             Far below you is an active volcano, from which great gouts of molten lava come surging  out,
             cascading back down into the depths.
             The glowing rock fills the farthest reaches of the cavern with a blood-red glare,
             giving everything an eerie, macabre appearance.
             The air is filled with flickering sparks of ash and a heavy smell of brimstone.
             The walls are hot to the touch,
             and the thundering of the volcano drowns out all other sounds.
             Embedded in the jagged roof far overhead
             are myriad twisted formations composed of pure white alabaster,
             which scatter the murky light into sinister apparitions upon the walls.
             To one side is a deep gorge, filled with a bizarre chaos of tortured rock
             which seems to have been crafted by the devil himself.
             An immense river of fire crashes out from the depths of the volcano,
             burns its way through the gorge, and plummets into a bottomless pit far off to your left.
             To the right, an immense geyser of blistering steam erupts continuously
             from a barren island in the center of a sulfurous lake, which bubbles ominously.
             The far right wall is aflame with an incandescence of its own,
             which lends an additional infernal splendor to the already hellish scene.
             A dark, forboding passage exits to the south.",
        s_to At_Junction_With_Warm_Walls,
        out_to At_Junction_With_Warm_Walls,
        d_to "Don't be ridiculous!",
        before [;
          Jump:
            <<Go d_obj>>;
        ],
  has   light;

Scenic  -> "active volcano"
  with  name 'volcano' 'rock' 'active' 'glowing' 'blood' 'blood-red' 'red'
             'eerie' 'macabre',
        description
            "Great gouts of molten lava come surging out of the volcano
             and go cascading back down into the depths.
             The glowing rock fills the farthest reaches of the cavern with a blood-red glare,
             giving everything an eerie, macabre appearance.";

Scenic  -> "sparks of ash"
  with  name 'spark' 'sparks' 'ash' 'air' 'flickering',
        description
            "The sparks too far away for you to get a good look at them.",
  has   multitude;

Scenic  -> "jagged roof"
  with  name 'roof' 'formations' 'light' 'apparaitions' 'jagged' 'twsited'
             'murky' 'sinister',
        description
            "Embedded in the jagged roof far overhead are myriad twisted formations
             composed of pure white alabaster,
             which scatter the murky light into sinister apparitions upon the walls.";

Scenic  -> "deep gorge"
  with  name 'gorge' 'chaos' 'rock' 'deep' 'bizarre' 'tortured',
        description
            "The gorge is filled with a bizarre chaos of tortured rock
             which seems to have been crafted by the devil himself.";

Scenic  -> "river of fire"
  with  name 'river' 'fire' 'depth' 'pit' 'fire' 'fiery' 'bottomless',
        description
            "The river of fire crashes out from the depths of the volcano,
             burns its way through the gorge, and plummets into a bottomless pit far off to your left.";

Scenic  -> "immense geyser"
  with  name 'geyser' 'steam' 'island' 'lake' 'immense' 'blistering' 'barren'
             'sulfrous' 'sulferous' 'sulpherous' 'sulphrous' 'bubbling',
        description
            "The geyser of blistering steam erupts continuously from a barren island
             in the center of a sulfurous lake, which bubbles ominously.";

! ------------------------------------------------------------------------------

Room    In_Chamber_Of_Boulders "In Chamber of Boulders"
  with  name 'chamber' 'of' 'boulders',
        description
            "You are in a small chamber filled with large boulders.
             The walls are very warm, causing the air in the room to be almost stifling from the heat.
             The only exit is a crawl heading west, through which is coming a low rumbling.",
        w_to At_Junction_With_Warm_Walls,
        out_to At_Junction_With_Warm_Walls,
  has   nodwarf;

Scenic  -> "boulders"
  with  name 'boulder' 'boulders' 'rocks' 'stones',
        description "They're just ordinary boulders. They're warm.",
        before [;
          LookUnder, Push, Pull:
            "You'd have to blast them aside.";
        ],
  has   multitude;

Treasure -> "rare spices"
  with  name 'spices' 'spice' 'rare' 'exotic',
        article "a selection of",
        before [;
          Smell, Examine:
            "They smell wonderfully exotic!";
        ],
        depositpoints 14,
  has   multitude;

! ------------------------------------------------------------------------------

Room    In_Limestone_Passage "In Limestone Passage"
  with  name 'limestone' 'passage',
        description
            "You are walking along a gently sloping north/south passage
             lined with oddly shaped limestone formations.",
        n_to At_Fork_In_Path,
        u_to At_Fork_In_Path,
        s_to In_Front_Of_Barren_Room,
        d_to In_Front_Of_Barren_Room,
  has   nodwarf;

Scenic  -> "limestone formations"
  with  name 'formations' 'shape' 'shapes' 'lime' 'limestone' 'stone' 'oddly'
             'shaped' 'oddly-shaped',
        description
            "Every now and then a particularly strange shape catches your eye.",
  has   multitude;

! ------------------------------------------------------------------------------
!   If you go down to the woods today...
! ------------------------------------------------------------------------------

Room    In_Front_Of_Barren_Room "In Front of Barren Room"
  with  name 'front' 'of' 'entrance' 'to' 'barren' 'room',
        description
            "You are standing at the entrance to a large, barren room.
             A sign posted above the entrance reads: ~Caution! Bear in room!~",
        w_to In_Limestone_Passage,
        u_to In_Limestone_Passage,
        e_to In_Barren_Room,
        in_to In_Barren_Room,
  has   nodwarf;

Scenic  -> "caution sign"
  with  name 'sign' 'barren' 'room' 'caution',
        description "The sign reads, ~Caution! Bear in room!~";

! ------------------------------------------------------------------------------

Room    In_Barren_Room "In Barren Room"
  with  name 'in' 'barren' 'room',
        description
            "You are inside a barren room.
             The center of the room is completely empty except for some dust.
             Marks in the dust lead away toward the far end of the room.
             The only exit is the way you came in.",
        w_to In_Front_Of_Barren_Room,
        out_to In_Front_Of_Barren_Room,
  has   nodwarf;

Scenic  -> "dust"
  with  name 'dust' 'marks',
        description "It just looks like ordinary dust.";

Object  -> Bear "large cave bear"
  with  name 'bear' 'large' 'tame' 'ferocious' 'cave',
        describe [;
            if (self.is_following_you)
                "You are being followed by a very large, tame bear.";
            if (self.is_friendly == false)
                "There is a ferocious cave bear eyeing you from the far end of the room!";
            if (location == In_Barren_Room)
                "There is a gentle cave bear sitting placidly in one corner.";
            "There is a contented-looking bear wandering about nearby.";
        ],
        life [;
          Attack:
            if (axe in player) <<ThrowAt axe self>>;
            if (self.is_friendly)
                "The bear is confused; he only wants to be your friend.";
            "With what? Your bare hands? Against *his* bear hands??";
          ThrowAt:
            if (noun ~= axe) <<Give noun self>>;
            if (self.is_friendly)
                "The bear is confused; he only wants to be your friend.";
            move axe to location;
            axe.is_near_bear = true;
            "The axe misses and lands near the bear where you can't get at it.";
          Give:
            if (noun == tasty_food) {
                axe.is_near_bear = false;
                remove tasty_food;
                self.is_friendly = true;
                "The bear eagerly wolfs down your food, after which he seems to calm down considerably
                 and even becomes rather friendly.";
            }
            if (self.is_friendly)
                "The bear doesn't seem very interested in your offer.";
            "Uh-oh -- your offer only makes the bear angrier!";
          Order, Ask, Answer:
            "This is a Bear of very little brain.";
        ],
        before [;
          Examine:
            print "The bear is extremely large, ";
            if (self.is_friendly) "but appears to be friendly.";
            "and seems quite ferocious!";
          Take, Catch:
            if (self.is_friendly == false) "Surely you're joking!";
            if (golden_chain has locked)
                "The bear is still chained to the wall.";
            self.is_following_you = true;
            StartDaemon(self);
            "Ok, the bear's now following you around.";
          Drop, Release:
            if (self.is_following_you == false) "What?";
            self.is_following_you = false;
            StopDaemon(self);
            if (Troll in location) {
                remove Troll;
                "The bear lumbers toward the troll, who lets out a startled shriek and scurries away.
                 The bear soon gives up the pursuit and wanders back.";
            }
            "The bear wanders away from you.";
        ],
        daemon [;
            if (location == thedark) rfalse;
            if (self in location) {
                if (location == At_Breath_Taking_View)
                    "^The bear roars with delight.";
                rfalse;
            }
            move self to location;
            "^The bear lumbers along behind you.";
        ],
        is_following_you false,
        is_friendly false,
  has   animate;

Treasure -> golden_chain "golden chain"
  with  name 'chain' 'links' 'shackles' 'solid' 'gold' 'golden' 'thick' 'chains',
        description "The chain has thick links of solid gold!",
        describe [;
            if (self has locked)
                "The bear is held back by a solid gold chain.";
            "A solid golden chain lies in coils on the ground!";
        ],
        with_key set_of_keys,
        before [;
          Take:
            if (self has locked) {
                if (Bear.is_friendly) "It's locked to the friendly bear.";
                "It's locked to the ferocious bear!";
            }
          Unlock:
            if (Bear.is_friendly == false)
                "There is no way to get past the bear to unlock the chain,
                 which is probably just as well.";
          Lock:
            if (self hasnt locked) "The mechanism won't lock again.";
        ],
        after [;
          Unlock:
            "You unlock the chain, and set the tame bear free.";
        ],
        depositpoints 14,
  has   lockable locked;

! ------------------------------------------------------------------------------
!   The Different Maze
! ------------------------------------------------------------------------------

Class   DiffmazeRoom
  with  short_name "Maze";

DiffmazeRoom Different_Maze_1
  with  description "You are in a maze of twisty little passages, all different.",
        s_to Different_Maze_3,
        sw_to Different_Maze_4,
        ne_to Different_Maze_5,
        se_to Different_Maze_6,
        u_to Different_Maze_7,
        nw_to Different_Maze_8,
        e_to Different_Maze_9,
        w_to Different_Maze_10,
        n_to Different_Maze_11,
        d_to At_West_End_Of_Long_Hall;

DiffmazeRoom Different_Maze_2
  with  description "You are in a little maze of twisting passages, all different.",
        sw_to Different_Maze_3,
        n_to Different_Maze_4,
        e_to Different_Maze_5,
        nw_to Different_Maze_6,
        se_to Different_Maze_7,
        ne_to Different_Maze_8,
        w_to Different_Maze_9,
        d_to Different_Maze_10,
        u_to Different_Maze_11,
        s_to Dead_End_14;

DiffmazeRoom Different_Maze_3
  with  description "You are in a maze of twisting little passages, all different.",
        w_to Different_Maze_1,
        se_to Different_Maze_4,
        nw_to Different_Maze_5,
        sw_to Different_Maze_6,
        ne_to Different_Maze_7,
        u_to Different_Maze_8,
        d_to Different_Maze_9,
        n_to Different_Maze_10,
        s_to Different_Maze_11,
        e_to Different_Maze_2;

DiffmazeRoom Different_Maze_4
  with  description "You are in a little maze of twisty passages, all different.",
        nw_to Different_Maze_1,
        u_to Different_Maze_3,
        n_to Different_Maze_5,
        s_to Different_Maze_6,
        w_to Different_Maze_7,
        sw_to Different_Maze_8,
        ne_to Different_Maze_9,
        e_to Different_Maze_10,
        d_to Different_Maze_11,
        se_to Different_Maze_2;

DiffmazeRoom Different_Maze_5
  with  description "You are in a twisting maze of little passages, all different.",
        u_to Different_Maze_1,
        d_to Different_Maze_3,
        w_to Different_Maze_4,
        ne_to Different_Maze_6,
        sw_to Different_Maze_7,
        e_to Different_Maze_8,
        n_to Different_Maze_9,
        nw_to Different_Maze_10,
        se_to Different_Maze_11,
        s_to Different_Maze_2;

DiffmazeRoom Different_Maze_6
  with  description "You are in a twisting little maze of passages, all different.",
        ne_to Different_Maze_1,
        n_to Different_Maze_3,
        nw_to Different_Maze_4,
        se_to Different_Maze_5,
        e_to Different_Maze_7,
        d_to Different_Maze_8,
        s_to Different_Maze_9,
        u_to Different_Maze_10,
        w_to Different_Maze_11,
        sw_to Different_Maze_2;

DiffmazeRoom Different_Maze_7
  with  description "You are in a twisty little maze of passages, all different.",
        n_to Different_Maze_1,
        se_to Different_Maze_3,
        d_to Different_Maze_4,
        s_to Different_Maze_5,
        e_to Different_Maze_6,
        w_to Different_Maze_8,
        sw_to Different_Maze_9,
        ne_to Different_Maze_10,
        nw_to Different_Maze_11,
        u_to Different_Maze_2;

DiffmazeRoom Different_Maze_8
  with  description "You are in a twisty maze of little passages, all different.",
        e_to Different_Maze_1,
        w_to Different_Maze_3,
        u_to Different_Maze_4,
        sw_to Different_Maze_5,
        d_to Different_Maze_6,
        s_to Different_Maze_7,
        nw_to Different_Maze_9,
        se_to Different_Maze_10,
        ne_to Different_Maze_11,
        n_to Different_Maze_2;

DiffmazeRoom Different_Maze_9
  with  description "You are in a little twisty maze of passages, all different.",
        se_to Different_Maze_1,
        ne_to Different_Maze_3,
        s_to Different_Maze_4,
        d_to Different_Maze_5,
        u_to Different_Maze_6,
        nw_to Different_Maze_7,
        n_to Different_Maze_8,
        sw_to Different_Maze_10,
        e_to Different_Maze_11,
        w_to Different_Maze_2;

DiffmazeRoom Different_Maze_10
  with  description "You are in a maze of little twisting passages, all different.",
        d_to Different_Maze_1,
        e_to Different_Maze_3,
        ne_to Different_Maze_4,
        u_to Different_Maze_5,
        w_to Different_Maze_6,
        n_to Different_Maze_7,
        s_to Different_Maze_8,
        se_to Different_Maze_9,
        sw_to Different_Maze_11,
        nw_to Different_Maze_2;

DiffmazeRoom Different_Maze_11
  with  description "You are in a maze of little twisty passages, all different.",
        sw_to Different_Maze_1,
        nw_to Different_Maze_3,
        e_to Different_Maze_4,
        w_to Different_Maze_5,
        n_to Different_Maze_6,
        d_to Different_Maze_7,
        se_to Different_Maze_8,
        u_to Different_Maze_9,
        s_to Different_Maze_10,
        ne_to Different_Maze_2;

! ------------------------------------------------------------------------------

DeadendRoom Dead_End_14
  class Room
  with  name 'dead' 'end' 'near' 'vending' 'machine',
        short_name "Dead End, near Vending Machine",
        description
            "You have reached a dead end. There is a massive vending machine here.
             ^^
             Hmmm... There is a message here scrawled in the dust in a flowery script.",
        n_to Different_Maze_2,
        out_to Different_Maze_2,
  has   nodwarf;

Scenic  -> "message in the dust"
  with  name 'message' 'scrawl' 'writing' 'script' 'scrawled' 'flowery',
        description
            "The message reads, ~This is not the maze where the pirate leaves
             his treasure chest.~";

Scenic  -> VendingMachine "vending machine"
  with  name 'machine' 'slot' 'vending' 'massive' 'battery' 'coin',
        description
            "The instructions on the vending machine read,
             ~Insert coins to receive fresh batteries.~",
        before [;
          Receive:
            if (noun == rare_coins) {
                move fresh_batteries to location;
                remove rare_coins;
                "Soon after you insert the coins in the coin slot,
                 the vending machine makes a grinding sound, and a set of fresh batteries falls at your feet.";
            }
            "The machine seems to be designed to take coins.";
          Attack:
            "The machine is quite sturdy and survives your attack without getting so much as a scratch.";
          LookUnder:
            "You don't find anything under the machine.";
          Search:
            "You can't get inside the machine.";
          Take:
            "The vending machine is far too heavy to move.";
        ];

Object  fresh_batteries "fresh batteries" VendingMachine
  with  name 'batteries' 'battery' 'fresh',
        description
            "They look like ordinary batteries. (A sepulchral voice says, ~Still going!~)",
        initial "There are fresh batteries here.",
        before [;
          Count:
            "A pair.";
        ],
        have_been_used false;

Object  old_batteries "worn-out batteries"
  with  name 'batteries' 'battery' 'worn' 'out' 'worn-out',
        description "They look like ordinary batteries.",
        initial "Some worn-out batteries have been discarded nearby.",
        before [;
          Count:
            "A pair.";
        ];

! ------------------------------------------------------------------------------
!   Dwarves!
! ------------------------------------------------------------------------------

Object  dwarf "threatening little dwarf"
  with  name 'dwarf' 'threatening' 'nasty' 'little' 'mean',
        description
            "It's probably not a good idea to get too close.
             Suffice it to say the little guy's pretty aggressive.",
        initial "A threatening little dwarf hides in the shadows.",
        number 5,
        daemon [;
            if (location == thedark) return;
            if (self.number == 0) {
                StopDaemon(self);
                return;
            }
            if (parent(self) == nothing) {
                if (location has nodwarf || location has light) return;
                if (random(100) <= self.number) {
                    if (Bear in location || Troll in location) return;
                    new_line;
                    if (Dragon in location) {
                        self.number--;
                        "A dwarf appears, but with one casual blast the dragon vapourises him!";
                    }
                    move self to location;
                    "A threatening little dwarf comes out of the shadows!";
                }
                return;
            }
            if (parent(self) ~= location) {
                if (location == thedark) return;
                if (location has nodwarf || location has light) return;
                if (random(100) <= 96 && parent(self) ~= In_Mirror_Canyon) {
                    move self to location;
                    print "^The dwarf stalks after you...^";
                }
                else {
                    remove self;
                    return;
                }
            }
            if (random(100) <= 75) {
                new_line;
                if (self.has_thrown_axe == false) {
                    move axe to location;
                    self.has_thrown_axe = true;
                    remove self;
                    "The dwarf throws a nasty little axe at you, misses,
                     curses, and runs away.";
                }
                if (location == In_Mirror_Canyon)
                    "The dwarf admires himself in the mirror.";
                print "The dwarf throws a nasty little knife at you, ";
                if (random(1000) <= 95) {
                    deadflag = 1;
                    "and hits!";
                }
                "but misses!";
            }
            if (random(3) == 1) {
                remove self;
                "^Tiring of this, the dwarf slips away.";
            }
        ],
        before [;
          Kick:
            "You boot the dwarf across the room. He curses, then gets up and brushes himself off.
             Now he's madder than ever!";
        ],
        life [;
          ThrowAt:
            if (noun == axe) {
                if (random(3) ~= 1) {
                    remove self;
                    move axe to location;
                    self.number--;
                    "You killed a little dwarf! The body vanishes in a cloud of greasy black smoke.";
                }
                move axe to location;
                "Missed! The little dwarf dodges out of the way of the axe.";
            }
            <<Give noun second>>;
          Give:
            if (noun == tasty_food)
                "You fool, dwarves eat only coal! Now you've made him *really* mad!";
            "The dwarf is not at all interested in your offer. (The reason being,
             perhaps, that if he kills you he gets everything you have anyway.)";
          Attack:
            "Not with your bare hands. No way.";
        ],
        has_thrown_axe false,
  has   animate;

Object  axe "dwarvish axe"
  with  name 'axe' 'little' 'dwarvish' 'dwarven',
        description "It's just a little axe.",
        initial "There is a little axe here.",
        before [;
            if (~~self.is_near_bear) rfalse;
          Examine:
            "It's lying beside the bear.";
          Take:
            "No chance. It's lying beside the ferocious bear, quite within harm's way.";
        ],
        is_near_bear false;

! ------------------------------------------------------------------------------
!   Two brushes with piracy
! ------------------------------------------------------------------------------

Object  pirate
  with  daemon [ obj booty_nearby;
            if (random(100) > 2 || location == thedark or In_Secret_Canyon ||
                location has light || location has nodwarf) return;
            if (dwarf in location)
                "^A bearded pirate appears, catches sight of the dwarf and runs away.";
            objectloop (obj ofclass Treasure && obj in player or location)
                booty_nearby = true;
            if (booty_nearby == false) {
                if (self.has_been_spotted) return;
                self.has_been_spotted = true;
                if (self.has_stolen_something) StopDaemon(self);
                "^There are faint rustling noises from the darkness behind you.
                 As you turn toward them, you spot a bearded pirate.
                 He is carrying a large chest.
                 ^^
                 ~Shiver me timbers!~ he cries, ~I've been spotted!
                 I'd best hie meself off to the maze to hide me chest!~
                 ^^
                 With that, he vanishes into the gloom.";
            }
            if (self.has_stolen_something) return;
            self.has_stolen_something = true;
            if (self.has_been_spotted) StopDaemon(self);
            objectloop (obj ofclass Treasure && obj in player or location) {
                if (obj in player) score = score - 5;
                move obj to Dead_End_13;
            }
            "^Out from the shadows behind you pounces a bearded pirate!
             ~Har, har,~ he chortles. ~I'll just take all this booty and hide it away
             with me chest deep in the maze!~
             He snatches your treasure and vanishes into the gloom.";
        ],
        has_stolen_something false,
        has_been_spotted false;

! ----------------------------------------------------------------------------
!   The cave is closing now...
! ----------------------------------------------------------------------------

Object  cave_closer
  with  daemon [;
            if (treasures_found < MAX_TREASURES) return;
            StopDaemon(self);
            caves_closed = true;
            score = score + 25;
            remove CrystalBridge;
            give Grate locked ~open;
            remove set_of_keys;
            StopDaemon(dwarf);
            StopDaemon(pirate);
            remove Troll;
            remove Bear;
            remove Dragon;
            StartTimer(endgame_timer, 25);
            "^A sepulchral voice reverberating through the cave says, ~Cave
             closing soon. All adventurers exit immediately through main office.~";
        ];

Object  endgame_timer
  with  time_left 0,
        time_out [;
            score = score + 10;
            while (child(player)) remove child(player);
            move bottle to At_Ne_End;
            if (child(bottle)) remove child(bottle);
            move giant_bivalve to At_Ne_End;
            move brass_lantern to At_Ne_End;
            move black_rod to At_Ne_End;
            move little_bird to At_Sw_End;
            move velvet_pillow to At_Sw_End;
            print
                "^The sepulchral voice intones, ~The cave is now closed.~
                 As the echoes fade, there is a blinding flash of light
                 (and a small puff of orange smoke). . .
                 ^^
                 As your eyes refocus, you look around...^";
            PlayerTo(At_Ne_End);
        ];

! ------------------------------------------------------------------------------
!   The End Game
! ------------------------------------------------------------------------------

Room    At_Ne_End "NE End of Repository"
  with  name 'northeast' 'ne' 'end' 'of' 'repository',
        description
            "You are at the northeast end of an immense room, even larger than the giant room.
             It appears to be a repository for the ~Adventure~ program.
             Massive torches far overhead bathe the room with smoky yellow light.
             Scattered about you can be seen a pile of bottles (all of them empty),
             a nursery of young beanstalks murmuring quietly, a bed of oysters,
             a bundle of black rods with rusty stars on their ends, and a collection of brass lanterns.
             Off to one side a great many dwarves are sleeping on the floor, snoring loudly.
             A sign nearby reads: ~Do not disturb the dwarves!~",
        sw_to At_Sw_End,
  has   light;

Object  -> "enormous mirror"
  with  name 'mirror' 'enormous' 'huge' 'big' 'large' 'suspended' 'hanging'
             'vanity' 'dwarvish',
        description "It looks like an ordinary, albeit enormous, mirror.",
        initial
            "An immense mirror is hanging against one wall, and stretches to the other end of the room,
             where various other sundry objects can be glimpsed dimly in the distance.",
        before [;
          Attack:
            print
                "You strike the mirror a resounding blow,
                 whereupon it shatters into a myriad tiny fragments.^^";
            SleepingDwarves.wake_up();
            rtrue;
        ],
        found_in At_Ne_End At_Sw_End,
  has   static;

Scenic  -> "collection of adventure game materials"
  with  name 'stuff' 'junk' 'materials' 'torches' 'objects' 'adventure'
             'repository' 'massive' 'sundry',
        description
            "You've seen everything in here already, albeit in somewhat different contexts.",
        before [;
          Take:
            "Realizing that by removing the loot here you'd be ruining the game for future players,
             you leave the ~Adventure~ materials where they are.";
        ];

Scenic  -> SleepingDwarves "sleeping dwarves"
  with  name 'dwarf' 'dwarves' 'sleeping' 'snoring' 'dozing' 'snoozing',
        article "hundreds of angry",
        description "I wouldn't bother the dwarves if I were you.",
        before [;
          Take:
            "What, all of them?";
        ],
        life [;
          WakeOther:
            print
                "You prod the nearest dwarf, who wakes up grumpily,
                 takes one look at you, curses, and grabs for his axe.^^";
            self.wake_up();
            rtrue;
          Attack:
            self.wake_up();
            rtrue;
        ],
        wake_up [;
            deadflag = 1;
            "The resulting ruckus has awakened the dwarves.
             There are now dozens of threatening little dwarves in the room with you!
             Most of them throw knives at you! All of them get you!";
        ],
  has   animate multitude;

! ------------------------------------------------------------------------------

Room    At_Sw_End "SW End of Repository"
  with  name 'southwest' 'sw' 'end' 'of' 'repository',
        description
            "You are at the southwest end of the repository.
             To one side is a pit full of fierce green snakes.
             On the other side is a row of small wicker cages, each of which contains a little sulking bird.
             In one corner is a bundle of black rods with rusty marks on their ends.
             A large number of velvet pillows are scattered about on the floor.
             A vast mirror stretches off to the northeast.
             At your feet is a large steel grate, next to which is a sign which reads,
             ~TREASURE VAULT. Keys in main office.~",
        d_to RepositoryGrate,
        ne_to At_Ne_End,
  has   light;

Object  -> RepositoryGrate "steel grate"
  with  name 'ordinary' 'steel' 'grate' 'grating',
        description "It just looks like an ordinary steel grate.",
        when_open "The grate is open.",
        when_closed "The grate is closed.",
        door_dir d_to,
        door_to Outside_Grate,
        with_key nothing,
  has   static door locked openable;

Scenic  -> "collection of adventure game materials"
  with  name 'pit' 'snake' 'snakes' 'fierce' 'green' 'stuff' 'junk' 'materials'
             'adventure' 'repository' 'massive' 'sundry',
        description
            "You've seen everything in here already, albeit in somewhat different contexts.",
        before [;
          Take:
            "Realizing that by removing the loot here you'd be ruining the game for future players,
             you leave the ~Adventure~ materials where they are.";
        ];

Object  -> black_mark_rod "black rod with a rusty mark on the end"
  with  name 'rod' 'black' 'rusty' 'mark' 'three' 'foot' 'iron' 'explosive'
             'dynamite' 'blast',
        description "It's a three foot black rod with a rusty mark on an end.",
        initial
            "A three foot black rod with a rusty mark on one end lies nearby.",
        before [;
          Wave:
            "Nothing happens.";
        ];

! ------------------------------------------------------------------------------
!   Some entry points
! ------------------------------------------------------------------------------

[ Initialise;
    location = At_End_Of_Road;
    score = 36;
    StartDaemon(dwarf);
    StartDaemon(pirate);
    StartDaemon(cave_closer);
    "^^^^^Welcome to Adventure!^
          (Please type HELP for instructions and information.)^^";
];

[ PrintRank;
    print ", earning you the rank of ";
    if (score >= 348) "Grandmaster Adventurer!";
    if (score >= 330) "Master, first class.";
    if (score >= 300) "Master, second class.";
    if (score >= 200) "Junior Master.";
    if (score >= 130) "Seasoned Adventurer.";
    if (score >= 100) "Experienced Adventurer.";
    if (score >= 35)  "Adventurer.";
    if (score >= 10)  "Novice.";
                      "Amateur.";
];

[ DarkToDark;
    if (dark_warning == false) {
        dark_warning = true;
        "It is now pitch dark. If you proceed you will likely fall into a pit.";
    }
    if (random(4) == 1) {
        deadflag = 1;
        "You fell into a pit and broke every bone in your body!";
    }
    rfalse;
];

[ UnknownVerb word
    obj;
    objectloop (obj ofclass Room) {
        if (obj has visited && WordInProperty(word, obj, name)) {
            verb_wordnum = 0;
            return 'go';
        }
    }
    rfalse;
];

! ------------------------------------------------------------------------------
!   Resurrection
! ------------------------------------------------------------------------------

[ AfterLife o;
    if (deadflag == 3) {
        deadflag = 1;
        rfalse;
    }
    print "^^";
    if (caves_closed)
        "It looks as though you're dead. Well, seeing as how it's so close to closing time anyway,
         I think we'll just call it a day.";
    switch (deaths) {
      0:
        print
            "Oh dear, you seem to have gotten yourself killed.
             I might be able to help you out, but I've never really done this before.
             Do you want me to try to reincarnate you?^^";
      1:
        print
            "You clumsy oaf, you've done it again!
             I don't know how long I can keep this up.
             Do you want me to try reincarnating you again?^^";
      2:
        print
            "Now you've really done it! I'm out of orange smoke!
             You don't expect me to do a decent reincarnation without any orange smoke, do you?^^";
    }
    print "> ";
    if (YesOrNo() == false) {
        switch (deaths) {
          0: "Very well.";
          1: "Probably a wise choice.";
          2: "I thought not!";
        }
    }
    switch (deaths) {
      0:
        print
            "All right. But don't blame me if something goes wr......
             ^^^^
             --- POOF!! ---
             ^^
             You are engulfed in a cloud of orange smoke.
             Coughing and gasping, you emerge from the smoke and find that you're....^";
      1:
        print
            "Okay, now where did I put my orange smoke?.... >POOF!<
             ^^
             Everything disappears in a dense cloud of orange smoke.^";
      2:
        "Okay, if you're so smart, do it yourself! I'm leaving!";
    }
    deaths++;
    score = score - 10;
    if (location ~= thedark) {
        while (child(player)) {
            o = child(player);
            move o to location;
            if (o ofclass Treasure) score = score - 5;
        }
    }
    else {
        while (child(player)) {
            o = child(player);
            move o to real_location;
            if (o ofclass Treasure) score = score - 5;
        }
    }
    move brass_lantern to At_End_Of_Road;
    give brass_lantern ~on ~light;
    remove dwarf;
    deadflag = 0;
    PlayerTo(Inside_Building);
];

! ------------------------------------------------------------------------------
!   Menu-driven help (not really a part of the game itself)
! ------------------------------------------------------------------------------

[ HelpMenu;
    if (menu_item == 0) {
        item_width = 8;
        item_name = "About Adventure";
        if (deadflag == 2) return 4;
        else               return 3;
    }
    if (menu_item == 1) {
        item_width = 6;
        item_name = "Instructions";
    }
    if (menu_item == 2) {
        item_width = 4;
        item_name = "History";
    }
    if (menu_item == 3) {
        item_width = 6;
        item_name = "Authenticity";
    }
    if (menu_item == 4) {
        item_width = 7;
        item_name = "Did you know...";
    }
];

[ HelpInfo;
    if (menu_item == 1) {
        print
            "I know of places, actions, and things.
             You can guide me using commands that are complete sentences.
             To move, try commands like ~enter,~ ~east,~ ~west,~ ~north,~ ~south,~
             ~up,~ ~down,~ ~enter building,~ ~climb pole,~ etc.^^";
        print
            "I know about a few special objects, like a black rod hidden in the cave.
             These objects can be manipulated using some of the action words that I know.
             Usually you will need to give a verb followed by an object
             (along with descriptive adjectives when desired),
             but sometimes I can infer the object from the verb alone.
             Some objects also imply verbs; in particular, ~inventory~ implies ~take inventory~,
             which causes me to give you a list of what you're carrying.
             The objects have side effects; for instance, the rod scares the bird.^^";
        print
            "Many commands have abbreviations.
             For example, you can type ~i~ in place of ~inventory,~
             ~x object~ instead of ~examine object,~ etc.^^";
        print
            "Usually people having trouble moving just need to try a few more words.
             Usually people trying unsuccessfully to manipulate an object are attempting
             something beyond their (or my!) capabilities and should try a completely different tack.^^";
        print
            "Note that cave passages turn a lot, and that leaving a room to the north
             does not guarantee entering the next from the south.^^";
        print
            "If you want to end your adventure early, type ~quit~.
             To suspend your adventure such that you can continue later, type ~save,~
             and to resume a saved game, type ~restore.~
             To see how well you're doing, type ~score~.
             To get full credit for a treasure, you must have left it safely in the building,
             though you get partial credit just for locating it.
             You lose points for getting killed, or for quitting, though the former costs you more.
             There are also points based on how much (if any) of the cave you've managed to explore;
             in particular, there is a large bonus just for getting in
             (to distinguish the beginners from the rest of the pack),
             and there are other ways to determine whether you've been through
             some of the more harrowing sections.^^";
        print
            "If you think you've found all the treasures, just keep exploring for a while.
             If nothing interesting happens, you haven't found them all yet.
             If something interesting *does* happen, it means you're getting a bonus
             and have an opportunity to garner many more points in the master's section.^^";
        "Good luck!";
    }
    if (menu_item == 2) {
        print
            "Perhaps the first adventurer was a mulatto slave named Stephen Bishop, born about 1820:
             `slight, graceful, and very handsome'; a `quick, daring, enthusiastic' guide
             to the Mammoth Cave in the Kentucky karst.
             The story of the Cave is a curious microcosm of American history.
             Its discovery is a matter of legend dating back to the 1790s;
             it is said that a hunter, John Houchin, pursued a wounded bear to a large pit
             near the Green River and stumbled upon the entrance.
             The entrance was thick with bats and by the War of 1812 was intensively mined for guano,
             dissolved into nitrate vats to make saltpetre for gunpowder.
             After the war prices fell; but the Cave became a minor side-show when a dessicated
             Indian mummy was found nearby, sitting upright in a stone coffin, surrounded by talismans.
             In 1815, Fawn Hoof, as she was nicknamed after one of the charms,
             was taken away by a circus, drawing crowds across America
             (a tour rather reminiscent of Don McLean's song `The Legend of Andrew McCrew').
             She ended up in the Smithsonian but by the 1820s the Cave was being called
             one of the wonders of the world, largely due to her posthumous efforts.^^";
        print
            "By the early nineteenth century European caves were big tourist attractions,
             but hardly anyone visited the Mammoth, `wonder of the world' or not.
             Nor was it then especially large (the name was a leftover from the miners,
             who boasted of their mammoth yields of guano).
             In 1838, Stephen Bishop's owner bought up the Cave.
             Stephen, as (being a slave) he was invariably called, was by any standards a remarkable man:
             self-educated in Latin and Greek, he became famous as the `chief ruler' of his underground realm.
             He explored and named much of the layout in his spare time, doubling the known map in a year.
             The distinctive flavour of the Cave's names -- half-homespun American, half-classical --
             started with Stephen: the River Styx, the Snowball Room, Little Bat Avenue, the Giant Dome.
             Stephen found strange blind fish, snakes, silent crickets, the remains of cave bears
             (savage, playful creatures, five feet long and four high, which became extinct
             at the end of the last Ice Age), centuries-old Indian gypsum workings and ever more cave.
             His 1842 map, drafted entirely from memory, was still in use forty years later.^^";
        print
            "As a tourist attraction (and, since Stephen's owner was a philanthropist,
             briefly a sanatorium for tuberculosis, owing to a hopeless medical theory)
             the Cave became big business: for decades nearby caves were hotly seized
             and legal title endlessly challenged.
             The neighbouring chain, across Houchins Valley in the Flint Ridge,
             opened the Great Onyx Cave in 1912.
             By the 1920s, the Kentucky Cave Wars were in full swing.
             Rival owners diverted tourists with fake policemen, employed stooges
             to heckle each other's guided tours, burned down ticket huts,
             put out libellous and forged advertisements.
             Cave exploration became so dangerous and secretive that finally in 1941 the U.S. Government
             stepped in, made much of the area a National Park and effectively banned caving.
             The gold rush of tourists was, in any case, waning.^^";
        print
            "Convinced that the Mammoth and Flint Ridge caves were all linked in a huge chain,
             explorers tried secret entrances for years, eventually winning official backing.
             Throughout the 1960s all connections from Flint Ridge -- difficult and water-filled tunnels
             -- ended frustratingly in chokes of boulders.
             A `reed-thin' physicist, Patricia Crowther, made the breakthrough in 1972
             when she got through the Tight Spot and found a muddy passage:
             it was a hidden way into the Mammoth Cave.^^";
        print
            "Under the terms of his owner's will, Stephen Bishop was freed in 1856,
             at which time the cave boasted 226 avenues, 47 domes, 23 pits and 8 waterfalls.
             He died a year later, before he could buy his wife and son.
             In the 1970s, Crowther's muddy passage was found on his map.^^";
        print
            "The Mammoth Cave is huge, its full extent still a matter of speculation
             (estimates vary from 300 to 500 miles).
             Although this game has often been called ~Colossal Cave~,
             it is actually a simulation of the Bedquilt Cave region.
             Here is Will Crowther's story of how it came about:^^";
        print
            "~I had been involved in a non-computer role-playing game called Dungeons and Dragons
             at the time, and also I had been actively exploring in caves --
             Mammoth Cave in Kentucky in particular.
             Suddenly, I got involved in a divorce, and that left me a bit pulled apart in various ways.
             In particular I was missing my kids.
             Also the caving had stopped, because that had become awkward,
             so I decided I would fool around and write a program that was a re-creation
             in fantasy of my caving, and also would be a game for the kids,
             and perhaps some aspects of the Dungeons and Dragons that I had been playing.^^";
        print
            "~My idea was that it would be a computer game that would not be intimidating
             to non-computer people, and that was one of the reasons why I made it so that
             the player directs the game with natural language input, instead of more standardized commands.
             My kids thought it was a lot of fun.~
             [Quoted in ~Genesis II: Creation and Recreation with Computers~, Dale Peterson (1983).]^^";
        print
            "Crowther's original FORTRAN program had five or so treasures, but no formal scoring.
             The challenge was really to explore, though there was opposition from for instance the snake.
             Like the real Bedquilt region, Crowther's simulation has a map on about four levels
             of depth and is rich in geological detail.
             A good example is the orange column which descends to the Orange River Rock room
             (where the bird lives): the real column is of orange travertine,
             a beautiful mineral found in wet limestone.^^";
        print
            "The game's language is loaded with references to caving, to `domes' and `crawls'.
             A `slab room', for instance, is a very old cave whose roof has begun to break away
             into sharp flakes which litter the floor in a crazy heap.
             The program's use of the word `room' for all manner of caves and places
             seems slightly sloppy in everyday English, but is widespread in American caving
             and goes back as far as Stephen Bishop: so the Adventure-games usage of the word `room'
             to mean `place' may even be bequeathed from him.^^";
        print
            "The game took its decisive step toward puzzle-solving when Don Woods, a student at Stanford,
             debugged and expanded it.
             He tripled the number of treasures and added the non-geological zones:
             everything from the Troll Bridge onward, together with most of the antechambers on the Bedquilt level.
             All of the many imitations and extensions of the original Adventure
             are essentially based on Woods's 350-point edition.
             (Many bloated, corrupted or enhanced -- it depends how you see it --
             versions of the game are in Internet circulation, and the most useful way to identify them
             is by the maximum attainable score.
             Many versions exist scoring up to around the 400s and 500s, and one up to 1000.
             Woods himself continues to release new versions of his game;
             most of the other extenders haven't his talent.)^^";
        print
            "Although the game has veered away from pure simulation, a good deal of it remains realistic.
             Cavers do turn back when their carbide lamps flicker;
             there are indeed mysterious markings and initials on the cave walls, some left by the miners,
             some by Bishop, some by 1920s explorers.
             Of course there isn't an active volcano in central Kentucky, nor are there dragons and dwarves.
             But even these embellishments are, in a sense, derived from tradition:
             like most of the early role-playing games, `Adventure' owes much to J. R. R. Tolkien's
             `The Hobbit', and the passage through the mountains and Moria of `The Lord of the Rings'
             (arguably its most dramatic and atmospheric passage).
             Tolkien himself, the most successful myth-maker of the twentieth century,
             worked from the example of Icelandic, Finnish and Welsh sagas.^^";
        print
            "By 1977 tapes of `Adventure' were being circulated widely, by the Digital user group DECUS,
             amongst others: taking over lunchtimes and weekends wherever it went... but that's another story.
             (Tracy Kidder's fascinating book `The Soul of a New Machine', a journalist's-eye-view
             of a mainframe computer development group, catches it well.)^^";
        "This is a copy at third or fourth hand: from Will Crowther's original
         to Donald Woods's 350-point edition to Donald Ekman's PC port to
         David M. Baggett's excellent TADS version (1993), to this.^^";
    }
    if (menu_item == 3) {
        print
            "This port is fairly close to the original.
             The puzzles, items and places of Woods's original 350-point version are exactly those here.^^";
        print
            "I have added a few helpful messages, such as ~This is a dead end.~, here and there:
             and restored some ~initial position~ messages from objects, such as the (rather lame)
             ^^  There is tasty food here.^^
             from source files which are certainly early but of doubtful provenance.
             They seem to sit well with the rest of the text.^^";
        print
            "The scoring system is the original, except that you no longer lose 4 points for quitting
             (since you don't get the score if you quit an Inform game, this makes no difference)
             and, controversially, I award 5 points for currently carrying a treasure, as some early 1980s ports did.
             The rank names are tidied up a little.
             The only significant rule change is that one cannot use magic words
             until their destinations have been visited.^^";
        print
            "The dwarves are simpler in their movements, but on the other hand I have added
             a very few messages to make them interact better with the rest of the game.
             The probabilities are as in the original game.^^";
        print
            "In the original one could type the name of a room to visit it:
             for the sake of keeping the code small, I have omitted this feature, but with some regrets.
             [RF: this feature incorporated into Release 9.]^^";
        print
            "The text itself is almost everywhere preserved intact, but I've corrected some
             spelling and grammatical mistakes (and altered a couple of utterly misleading and gnomic remarks).
             The instructions have been slightly altered (for obvious reasons) but are basically as written.^^";
        "A good source for details is David Baggett's source code, which is circulated on the Internet.";
    }
    print "Did you know that...^^";
    print
        "The five dwarves have a 96% chance of following you, except into light, down pits or
         when admiring themselves: and the nasty little knives are 9.5% accurate.^^";
    print "Dragons burn up dwarves (perhaps because dwarves eat only coal).^^";
    print
        "The bear (who likes the volcano) is too heavy for the bridge...
         and you can go back to the scene after being resurrected.^^";
    print
        "You can slip past the snake into the secret E/W canyon, 35% of the time at any rate.
         And walking about in the dark is not all that gruesome:
         it carries only a 25% risk of falling down a pit.^^";
    print "The vase does not like being immersed.^^";
    print "Shadowy figures can wave to each other.^^";
    print "Watering the hinges of the door rusts them up again.^^";
    print
        "When the cave closes, the grate is locked and the keys are thrown away,
         creatures run off and the crystal bridge vanishes...^^";
    print
        "...and a completely useless hint is written on the giant oyster's shell in the end game.
         (To make this hint slightly fairer, I've altered one word and placed suggestions elsewhere in the game.)^^";
    "The last lousy point can be won by... but no. That would be telling.";
];

[ HelpSub;
    if (deadflag ~= 2)
        DoMenu(
            "There is information provided on the following:^
            ^     Instructions for playing
            ^     A historical preface
            ^     How authentic is this edition?^", HelpMenu, HelpInfo);
    else
        DoMenu(
            "There is information provided on the following:^
            ^     Instructions for playing
            ^     A historical preface
            ^     How authentic is this edition?
            ^     Did you know...^", HelpMenu, HelpInfo);
];

[ Amusing; HelpSub(); ];

Verb 'help'
    *                       -> Help;

! ------------------------------------------------------------------------------
!   Grammar: the usual grammar and some extensions
! ------------------------------------------------------------------------------

Include "Grammar";

! ------------------------------------------------------------------------------

[ OffSub;
    if (brass_lantern notin player) "You have no lamp.";
    <<SwitchOff brass_lantern>>;
];

[ OnSub;
    if (brass_lantern notin player) "You have no lamp.";
    <<SwitchOn brass_lantern>>;
];

Verb 'off'
    *                       -> Off;

Verb 'on'
    *                       -> On;

! ------------------------------------------------------------------------------

[ CatchSub; "You can't catch ", (the) noun, "."; ];

[ ReleaseSub; "You can't release ", (the) noun, "."; ];

A creature is a kind of thing with held. 

[The Verb 'catch' 'capture'
    * creature              -> Catch
    * creature 'with' held  -> Catch;

The Verb 'release' 'free'
    * creature              -> Release;
]
! ------------------------------------------------------------------------------

[ WaterSub;
    if (bottle in player) <<Empty bottle>>;
    "Water? What water?";
];

[ OilSub;
    if (bottle in player) <<Empty bottle>>;
    "Oil? What oil?";
];

Verb 'water'
    * noun                  -> Water;

Verb 'oil' 'grease' 'lubricate'
    * noun                  -> Oil;

Verb 'pour' 'douse'
    * 'water' 'on' noun     -> Water
    * 'oil' 'on' noun       -> Oil
    * noun                  -> Empty;

! ------------------------------------------------------------------------------

[ BlastSub;
    if (location ~= At_Sw_End or At_Ne_End) "Frustrating, isn't it?";
    if (location == At_Sw_End && parent(black_mark_rod) == At_Ne_End) {
        score = score + 35;
        deadflag = 2;
        "There is a loud explosion, and a twenty-foot hole appears in the far wall,
         burying the dwarves in the rubble.
         You march through the hole and find yourself in the main office,
         where a cheering band of friendly elves carry the conquering adventurer off into the sunset.";
    }
    if (location == At_Ne_End && parent(black_mark_rod) == At_Sw_End) {
        score = score + 20;
        deadflag = 1;
        "There is a loud explosion, and a twenty-foot hole appears in the far wall,
         burying the snakes in the rubble.
         A river of molten lava pours in through the hole, destroying everything in its path, including you!";
    }
    deadflag = 1;
    "There is a loud explosion, and you are suddenly splashed across the walls of the room.";
];

[ BlastWithSub;
    if (second ~= black_mark_rod) "Blasting requires dynamite.";
    "Been eating those funny brownies again?";
];

[
Verb 'blast'
    *                       -> Blast
    * noun 'with' held      -> BlastWith;
]
! ------------------------------------------------------------------------------

[ XyzzySub; "Nothing happens."; ];

[ PlughSub; "Nothing happens."; ];

[ PloverSub; "Nothing happens."; ];

[ FeeSub; FthingSub(0); ];

[ FieSub; FthingSub(1); ];

[ FoeSub; FthingSub(2); ];

[ FooSub; FthingSub(3); ];

[ FthingSub i;
    if (feefie_count ~= i) {
        feefie_count = 0;
        "Get it right, dummy!";
    }
    if (feefie_count++ == 3) {
        feefie_count = 0;
        if (golden_eggs in In_Giant_Room) "Nothing happens.";
        if ((golden_eggs in player) || (golden_eggs in location))
            print "The nest of golden eggs has vanished!^";
        else
            print "Done!";
        if (golden_eggs in player) score = score - 5;
        if (golden_eggs in Inside_Building)
            score = score - golden_eggs.depositpoints;
        move golden_eggs to In_Giant_Room;
        if (location == In_Giant_Room)
            "^^A large nest full of golden eggs suddenly appears out of nowhere!";
    }
    else
        "Ok.";
];

[ OldMagicSub; "Good try, but that is an old worn-out magic word."; ];

Verb 'xyzzy'
    *                       -> Xyzzy;

Verb 'plugh'
    *                       -> Plugh;

Verb 'plover'
    *                       -> Plover;

Verb 'fee'
    *                       -> Fee;

Verb 'fie'
    *                       -> Fie;

Verb 'foe'
    *                       -> Foe;

Verb 'foo'
    *                       -> Foo;

Verb 'sesame' 'shazam' 'hocus' 'abracadabra' 'foobar' 'open-sesame' 'frotz'
    *                       -> OldMagic;

Extend 'say' first
    * 'blast'               -> Blast
    * 'xyzzy'               -> Xyzzy
    * 'plugh'               -> Plugh
    * 'plover'              -> Plover
    * 'fee'                 -> Fee
    * 'fie'                 -> Fie
    * 'foe'                 -> Foe
    * 'foo'                 -> Foo
    * 'sesame'/'shazam'/'hocus'/'abracadabra'/'foobar'/'open-sesame'/'frotz'
                            -> OldMagic;

! ------------------------------------------------------------------------------

[ CountSub;
    if (noun has multitude) "There are a multitude.";
    "I see one (1) ", (name) noun, ".";
];

[ KickSub;  <<Attack noun>>; ];         ! For kicking dwarves

[ UseSub; "You'll have to be a bit more explicit than that."; ];

Verb 'count'
    * noun                  -> Count;

Verb 'kick'
    * noun                  -> Kick;

Verb 'use'
    *                       -> Use;

! ------------------------------------------------------------------------------
!   Teleportation (uses also UnknownVerb entry point)
! ------------------------------------------------------------------------------

[ TeleportScope
    obj;
    switch (scope_stage) {
      1:    rfalse;
      2:    objectloop (obj ofclass Room)
                if (obj has visited) PlaceInScope(obj);
            rtrue;
      3:    return L__M(##Go, 2);
    }
];

[ TeleportSub;
    if (noun == location) "But you're already here!";
    PlayerTo(noun);
];

Extend 'go'
    * scope=TeleportScope       -> Teleport
    * 'to' scope=TeleportScope  -> Teleport;

#Ifndef DEBUG;

Verb 'goto'
    * scope=TeleportScope       -> Teleport;

#Endif;

! ------------------------------------------------------------------------------
!   In the test version: no dwarves or pirates, and magic words work from the start
! ------------------------------------------------------------------------------

#Ifdef TEST_VERSION;

[ XdetermSub;
    StopDaemon(dwarf);
    StopDaemon(pirate);
    give In_Debris_Room visited;
    give At_Y2 visited;
    give In_Plover_Room visited;
];

Verb 'xdeterm'
    *                       -> Xdeterm;

#Endif;

! ------------------------------------------------------------------------------