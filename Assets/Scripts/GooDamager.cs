using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDamager : PlayerCollision
{
	[SerializeField] GooDamageData data = null;
	
	public override bool OnCollideWithPlayer(PlayerMotor player, ControllerColliderHit hit)
	{
		player.GetComponent<PlayerHealth>().Damage(data.damageAmount);
		//knockback
		Vector3 direction = hit.normal;
		
		player.AddKnockback(data.knockbackAmount, data.knockbackDuration, direction, data.knockbackCurve);
		return true;
	}

	public override bool OnPlayerGrounded(PlayerMotor player)
	{
		player.GetComponent<PlayerHealth>().Damage(data.damageAmount);
		//knockback
		Vector3 direction = -player.InputVelocity.normalized;
		//knockback doesn't push you into the floor
		if (direction.y < 0)
		{
			direction.y = 0;
			direction.Normalize();
		}
		player.AddKnockback(data.knockbackAmount, data.knockbackDuration, direction, data.knockbackCurve);
		return true;
	}
}
