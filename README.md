This is a heavily edited version of Showin's bot overhaul
(heavily edited as in practically seperate things aside from a couple important functions that i was too lazy to make myself).
As of right now, the large majority of the changes are specific to Spy, with some changes to overall classes. Soon, everyone will be changed.


Commands:
"sm_ai_spy_debug", to toggle debug output into console.
"sm_ai_spy_enabled", to enable and disable the Spy.



Bot Commands to put into whatever server cfg you have:


nb_head_aim_resettle_angle 180


nb_head_aim_resettle_time 1.2


nb_head_aim_settle_duration 1.2


nb_head_aim_steady_max_rate 0.5


This makes the bot more realistic, as it gives them more humanlike reaction times. I tried to make them also have humanlike
aim, but considering the only way to do that is to completely nuke its aim and make it basically a punching bag, I have
decided against that. The bots should aim fine, but the aim is still somewhat robotic

If you REALLY want to see the spy bot's potential and how much its improved versus the stock bots:
make sure to put the GiveBotsMoreWeapons_Pub plugin, and set the bots to easy (tf_bot_difficulty 0).
really funny
