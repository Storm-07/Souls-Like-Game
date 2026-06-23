# PARAMERC VERSION 2.2 (Godot)

## Update 6/23/26
I just typed out a whole paragraph and forgot to hit save so I'm not typing all that again. I picked up the project again
today. I fixed a runtime bug with a rogue transform on the enemy hitbox. Then I added the enemy scripts to this repo. 
I'll go ahead and write out what each one does soon but that's enough time I just lost doing that so I'll come back soon.

I think the next move is to continue working on my combat system. As it is currently, I can have my player take damage, block, and parry. The enemy can also take damage, block, parry as well as get staggered from a player parrying the enemy attack. I don't have a stagger yet from the enemy's parry though which I just realized. Some things to note are as follows:
  - both the base blocks from player and enemy have no game feel at all. There's no audio cue, no particle system or lighting cue, no knockback, just a held animation. So that needs to be worked on.
  - the player's parrying of the enemy is the most polished interaction so far, there is an audio cue, with an audiostreamplayer3D node, with both an animation from the player and a stagger animation from the enemy
  - There is not yet a posture meter however that may take some time to work on
  - I think I need to make one stagger animation for the player in blender, but I forget tbh
  - the player's hurt state is correctly trigger upon hitbox to hurtbox conversion, but the timing is off, player's hurt animation plays accurately 40% of the time and is usually 1-2 seconds late.
  - enemy's hurt/block/parry behavior is too narrow and also seems a tad late. Takes damage 80% of the time and only blocks and parries rarely. Although I do have it set to be random at the moment so that can probably be fine-tuned a little until I hopefully figure out a better way for the bot to decide on moves.
  - enemy following is still very primitive and will need improvements. Simply follows player position with no obstacle identification (there's not much in my map yet anyway so this is lower on the priority list)
