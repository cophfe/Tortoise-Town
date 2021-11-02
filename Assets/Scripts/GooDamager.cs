using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDamager : PlayerCollision
{
	[SerializeField] GooDamageData data = null;
	[SerializeField] bool disableColliderOnDissolve = false;

	public override bool OnCollideWithPlayer(PlayerController player, ControllerColliderHit hit)
	{
		//if in the process of bouncing from knockback, do not inflict knockback or damage
		if (player.Motor.IsDashing && player.Motor.IsExternalDash) return true;
		if (player.Health.Damage(data.damageAmount))
			player.MainCamera.AddCameraShake(hit.normal * data.cameraShakeAmount);

		//knockback
		AddKnockback(player, hit.normal);
		return true;
	}

	public override bool OnPlayerGrounded(PlayerController player)
	{
		//if in the process of bouncing from knockback, do not inflict knockback or damage
		if (player.Motor.IsDashing && player.Motor.IsExternalDash) return true;

		//knockback
		AddKnockback(player, player.Motor.GroundNormal);
		//damage player
		if (player.Health.Damage(data.damageAmount))
			player.MainCamera.AddCameraShake(player.Motor.GroundNormal * data.cameraShakeAmount);

		return true;
	}

	void AddKnockback(PlayerController player, Vector3 direction)
	{
		player.Motor.AddKnockback(data.knockbackAmount, data.knockbackDuration, direction, data.knockbackCurve);
	}

	public void Dissolve()
	{
		if (disableColliderOnDissolve)
			GetComponent<Collider>().enabled = false;
		enabled = false;
	}

	public void Undissolve()
	{
		if (disableColliderOnDissolve)
			GetComponent<Collider>().enabled = true;
		enabled = true;
	}
}
