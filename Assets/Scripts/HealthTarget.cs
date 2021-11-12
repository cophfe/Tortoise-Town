using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthTarget : Health
{
	public delegate void DeathDelegate();
	public DeathDelegate deathlegate;

	protected override void OnDeath()
	{
		if (deathlegate != null)
			deathlegate();

		base.OnDeath();
		gameObject.SetActive(false);
	}

	public void ResetTarget()
	{
		gameObject.SetActive(true);
		Revive(100000);
	}
}
