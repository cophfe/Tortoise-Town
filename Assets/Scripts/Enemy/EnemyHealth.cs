using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(EnemyMotor))]
public class EnemyHealth : Health
{
	EnemyMotor motor;
	protected override void Start()
	{
		motor = GetComponent<EnemyMotor>();
		base.Start();
	}

	protected override void OnDeath()
	{
		motor.LocalManager.OnEnemyDeath(gameObject);
		gameObject.SetActive(false);
	}
}
