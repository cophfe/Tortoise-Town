using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(EnemyMotor))]
public class EnemyHealth : Health
{
	EnemyMotor motor;
	private void Start()
	{
		motor = GetComponent<EnemyMotor>();
	}

	protected override void OnDeath()
	{
		motor.LocalManager.OnEnemyDeath(gameObject);
		gameObject.SetActive(false);
	}
}
