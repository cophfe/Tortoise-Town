using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooArrow : Arrow
{
	public DamagerData knockbackData = null;

	protected override void OnCollide(Collider collider)
	{
		gameObject.SetActive(false);
		ignoredInPool = false;

		var controller = collider.GetComponent<PlayerController>();
		if (controller && knockbackData)
		{
			controller.Motor.AddKnockback(knockbackData.knockbackAmount, knockbackData.knockbackDuration, velocity.normalized, knockbackData.knockbackCurve);
			controller.MainCamera.AddCameraShake(velocity.normalized * knockbackData.cameraShakeAmount);
		}
	}
}
