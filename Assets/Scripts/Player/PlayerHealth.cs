using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

[RequireComponent(typeof(PlayerController))]
public class PlayerHealth : Health
{
	[SerializeField, Min(0)] float damageTimeout = 3;
	[SerializeField] float startToRegenerateTime = 10000;
	[SerializeField] float regenerateInterval = 1;

	float cooldownTimer = 0;
	float regenerateTimer = 0;
	PlayerController controller;

	protected override void Start()
	{
		controller = GetComponent<PlayerController>();
		base.Start();
	}

	private void FixedUpdate()
	{
		cooldownTimer -= Time.deltaTime;
		regenerateTimer -= Time.deltaTime;

		if (CurrentHealth < maxHealth && regenerateTimer < 0)
		{
			regenerateTimer = regenerateInterval;
			Heal(1);
		}
	}

	public override bool Damage(int damageAmount)
	{
		if (cooldownTimer > 0 && base.Damage(damageAmount))
		{
			cooldownTimer = damageTimeout;
			regenerateTimer = startToRegenerateTime;
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
