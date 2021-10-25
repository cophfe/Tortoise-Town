using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VelocitySetterTrampoline : PlayerCollision
{
	[Tooltip("The percentage of velocity that will be added in the opposite direction of the trampoline direction")]
	[SerializeField, Min(0)] float velocityMagnitude = 15;
	[Tooltip("Whether the trampoline direction is defined as the gameobjects up direction or as the collision normal")]
	[SerializeField] bool useTransformUp = true;
	[Tooltip("The minimum velocity into the trampoline before it bounces")]
	[SerializeField, Min(0)] float minBounceVelocity = 1;

	public override bool OnCollideWithPlayer(PlayerMotor player, ControllerColliderHit hit)
	{
		Vector3 trampolineUp = useTransformUp ? transform.up : hit.normal;

		if (Vector3.Dot(player.TotalVelocity, trampolineUp) < -minBounceVelocity)
		{
			player.ForcesVelocity = velocityMagnitude * trampolineUp;
			player.InputVelocity = Vector3.zero; ;

		}
		//do implement the player's default collision implementation, since it won't break anything in this situation
		return true;
	}

	public override bool OnPlayerGrounded(PlayerMotor player)
	{
		Vector3 trampolineUp = transform.up;
		float tDot = Vector3.Dot(player.TotalVelocity, trampolineUp);
		
		return (tDot >= -minBounceVelocity && tDot <= 0);
	}
}
