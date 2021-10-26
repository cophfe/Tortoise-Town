using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class PlayerHealth : Health
{
	[SerializeField, Min(0)] float damageTimeout = 3;

	float cooldownTimer = 0;
	PlayerController controller;

	protected override void Start()
	{
		controller = GameManager.Instance.Player;
		base.Start();
	}

	private void FixedUpdate()
	{
		cooldownTimer -= Time.deltaTime;
	}

	public override bool Damage(int damageAmount)
	{
		if (cooldownTimer > 0 && base.Damage(damageAmount))
		{
			cooldownTimer = damageTimeout;

			//set GUI

			//set Animation

			return true;
		}
		else return false;
	}

	protected override void OnDeath()
	{
		GameManager.Instance.OnPlayerDeath();
	}
}
