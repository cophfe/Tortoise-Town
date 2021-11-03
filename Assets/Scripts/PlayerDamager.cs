using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerDamager : PlayerCollision
{
	[SerializeField] DamagerData data = null;

	public override bool OnCollideWithPlayer(PlayerController player, ControllerColliderHit hit)
	{
		player = GameManager.Instance.Player;

		//if in the process of bouncing from knockback, do not inflict knockback or damage
		if (player.Motor.IsDashing && player.Motor.IsExternalDash) return true;

		//knockback
		AddKnockback(player, hit.normal);
		player.Health.Damage(data.damageAmount);
		player.MainCamera.AddCameraShake(hit.normal * data.cameraShakeAmount);
		player.Motor.CancelGroundMagnet();

		return true;
	}

	public override bool OnPlayerGrounded(PlayerController player)
	{
		player = GameManager.Instance.Player;
		//if in the process of bouncing from knockback, do not inflict knockback or damage
		if (player.Motor.IsDashing && player.Motor.IsExternalDash) return true;

		//knockback
		AddKnockback(player, player.Motor.GroundNormal);
		//damage player
		player.Health.Damage(data.damageAmount);
		player.MainCamera.AddCameraShake(player.Motor.GroundNormal * data.cameraShakeAmount);
		player.Motor.CancelGroundMagnet();

		return false;
	}

	void AddKnockback(PlayerController player, Vector3 direction)
	{
		GameManager.Instance.Player.Motor.AddKnockback(data.knockbackAmount, data.knockbackDuration, direction, data.knockbackCurve);
	}
}
