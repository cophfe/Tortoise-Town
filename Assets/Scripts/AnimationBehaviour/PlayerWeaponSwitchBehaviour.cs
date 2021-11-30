using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerWeaponSwitchBehaviour : StateMachineBehaviour
{
	public bool equipped = false;
	public bool enforce = false;
	//If we ever get equip animations this is for that
	[Min(0)] public float switchToWeaponTime = 0;
	bool done;
	PlayerCombat player;

	// OnStateEnter is called when a transition starts and the state machine starts to evaluate this state
	override public void OnStateEnter(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
	{
		done = false;
	}

	// OnStateUpdate is called on each Update frame between OnStateEnter and OnStateExit callbacks
	override public void OnStateUpdate(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
	{
		if (!done && stateInfo.normalizedTime > switchToWeaponTime)
		{
			var pC = animator.GetComponentInParent<PlayerCombat>();
			if (pC) pC.EquipWeapon(equipped);
			done = true;
		}
	}

	// OnStateExit is called when a transition ends and the state machine finishes evaluating this state
	//override public void OnStateExit(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
	//{
	//    
	//}

	// OnStateMove is called right after Animator.OnAnimatorMove()
	//override public void OnStateMove(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
	//{
	//    // Implement code that processes and affects root motion
	//}

	// OnStateIK is called right after Animator.OnAnimatorIK()
	//override public void OnStateIK(Animator animator, AnimatorStateInfo stateInfo, int layerIndex)
	//{
	//    // Implement code that sets up animation IK (inverse kinematics)
	//}
}
