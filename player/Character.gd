class_name Character
extends CharacterBody3D

#All this is for animation tree states, will come back to later, probably won't use global here
#var anim_tree: AnimationTree

#func animation_state_manager():
	#anim_tree.set("parameters/conditions/Swing", paddle_state == PaddleState.SWING)
	#anim_tree.set("parameters/conditions/Idle", paddle_state == PaddleState.IDLE)
	#anim_tree.set("parameters/conditions/Back", paddle_state == PaddleState.BACK)
	#anim_tree.set("parameters/conditions/Front", paddle_state == PaddleState.FRONT)
	#
	#if Global.back:
		#switch_states("BACK")
	#if Global.front:
		#switch_states("FRONT")
	#if !Global.swing_charging and Global.time_elasped < 300:
		#switch_states("IDLE")
	#if !Global.swing_charging and Global.time_elasped > 300 and paddle_state != PaddleState.IDLE:
		#switch_states("SWING")
		#await anim_tree.animation_finished
		#switch_states("IDLE")

