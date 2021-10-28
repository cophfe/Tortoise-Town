using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyHealth : Health
{
	protected override void Start()
	{
		base.Start();
	}

	protected override void OnDeath()
	{
		gameObject.SetActive(false);
	}
}
