using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthTarget : Health
{
	public ParticleSystem deathParticles;

	public delegate void DeathDelegate();
	public DeathDelegate deathlegate;
	AudioSource popSoundSource;

	private void Awake()
	{
		popSoundSource = GetComponent<AudioSource>();
		GameManager.Instance.SaveManager.RegisterHealth(this);
	}
	protected override void OnDeath()
	{
		deathlegate?.Invoke();
		
		if (deathParticles != null)
			deathParticles.Play(true);

		if (popSoundSource && GameManager.Instance.AudioData.targetPopSounds.CanBePlayed())
		{
			popSoundSource.PlayOneShot(GameManager.Instance.AudioData.targetPopSounds.GetRandom());
		}
		var arrow = GetComponentInChildren<Arrow>();
		if (arrow)
		{
			arrow.SetRendering(false);
		}

		base.OnDeath();
		GetComponentInChildren<MeshRenderer>().enabled = false;
		GetComponent<Collider>().enabled = false;
		enabled = false;
	}

	public override void ResetTo(float healthValue)
	{
		base.ResetTo(healthValue);
		if (IsDead)
		{
			GetComponentInChildren<MeshRenderer>().enabled = false;
			GetComponent<Collider>().enabled = false;
			enabled = false;
		}
		else
		{
			CurrentHealth = maxHealth;
			GetComponentInChildren<MeshRenderer>().enabled = true;
			GetComponent<Collider>().enabled = true;
			enabled = true;
		}
	}
}
