using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InstantKillHealthTarget : Health
{
	private void Awake()
	{
	}
	protected override void OnDeath()
	{
		Revive(1000);
		GameManager.Instance.Player.Health.Damage(900);
	}
}
