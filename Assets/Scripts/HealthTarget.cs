using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthTarget : Health
{
	public ParticleSystem deathParticles;

	public delegate void DeathDelegate();
	public DeathDelegate deathlegate;
	private void Awake()
	{
		GameManager.Instance.SaveManager.RegisterHealth(this);
	}
	protected override void OnDeath()
	{
		deathlegate?.Invoke();
		
		if (deathParticles != null)
			deathParticles.Play(true);

		base.OnDeath();
		GetComponent<MeshRenderer>().enabled = false;
		enabled = false;
	}

	public override void ResetTo(float healthValue)
	{
		base.ResetTo(healthValue);
		if (IsDead)
		{
			gameObject.SetActive(false);
		}
		else
		{
			CurrentHealth = maxHealth;
			gameObject.SetActive(true);
		}
	}
}
