﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;

[RequireComponent(typeof(PlayerController))]
public class PlayerHealth : Health
{
	[SerializeField, Min(0)] float damageTimeout = 3;
	[SerializeField] float startToRegenerateTime = 10000;
	[SerializeField] float regenerateSpeed = 1;
	[SerializeField] Color vignetteDamageColor = Color.red;
	[SerializeField] float vignetteMagnitudeMultiplier = 2;
	[SerializeField] float vignetteSmoothnessMultiplier = 2;
	float oldVignetteMagnitude;
	float oldVignetteSmoothness;

	float cooldownTimer = 0;
	float regenerateTimer = 0;
	PlayerController controller;

	Vignette vignette = null;


	protected override void Start()
	{
		controller = GetComponent<PlayerController>();
		base.Start();

		//will immidiately clone a new profile
		var volume = controller.MainCamera.GetComponentInChildren<Volume>();
		if (volume && volume.profile.TryGet<Vignette>(out vignette))
		{
			oldVignetteMagnitude = vignette.intensity.value;
			oldVignetteSmoothness = vignette.smoothness.value;
		}
	}

	private void FixedUpdate()
	{
		cooldownTimer -= Time.deltaTime;
		regenerateTimer -= Time.deltaTime;

		if (CurrentHealth < maxHealth && !IsDead)
		{
			if (regenerateTimer < 0)
			{
				Heal(Time.deltaTime * regenerateSpeed);
			}
			else
			{
				UpdateDamageEffect();
			}
		}
	}

	public override bool Damage(float damageAmount)
	{
		if (cooldownTimer < 0 && base.Damage(damageAmount))
		{
			cooldownTimer = damageTimeout;
			regenerateTimer = startToRegenerateTime;
			//set GUI

			//set Animation and sound effects
			controller.PlayerAudio.Stop();
			
			if (CurrentHealth <= 0)
				controller.PlayAudioOnce(controller.AudioData.death);
			else if (controller.Motor.IsRolling)
				controller.PlayAudioOnce(controller.AudioData.hitWhileBall);
			else
				controller.PlayAudioOnce(controller.AudioData.hit);
			
			return true;
		}
		else return false;
	}
	
	
	protected override void OnDeath()
	{
		GameManager.Instance.OnPlayerDeath();
		base.OnDeath();
	}

	public override bool Heal(float healAmount)
	{
		bool b = base.Heal(healAmount);
		UpdateDamageEffect();
		return b;
	}

	public override bool Revive(float healAmount)
	{
		bool b = base.Revive(healAmount);
		UpdateDamageEffect();
		return b;
	}

	void UpdateDamageEffect()
	{
		if (vignette == null) return;
		float t = 1 - CurrentHealth / maxHealth;
		vignette.color.value = Color.Lerp(Color.black, vignetteDamageColor, t);
		vignette.intensity.value = Mathf.Lerp(oldVignetteMagnitude, oldVignetteMagnitude * vignetteMagnitudeMultiplier, t) + (t * oldVignetteMagnitude * 0.05f * Mathf.Sin(Time.time * 3));
		vignette.smoothness.value = Mathf.Lerp(oldVignetteSmoothness, oldVignetteSmoothness * vignetteSmoothnessMultiplier, t) + (t * oldVignetteSmoothness * 0.05f * Mathf.Sin(Time.time * 3));
	}
}
