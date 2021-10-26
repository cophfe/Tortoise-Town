using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDamager : PlayerCollision
{
	[SerializeField] int damageAmount = 1;
	public override bool OnCollideWithPlayer(PlayerMotor player, ControllerColliderHit hit)
	{
		player.GetComponent<PlayerHealth>().Damage(damageAmount);

		return true;
	}

	public override bool OnPlayerGrounded(PlayerMotor player)
	{
		return true;
	}
}
