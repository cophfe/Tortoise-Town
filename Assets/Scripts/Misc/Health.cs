using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Health : MonoBehaviour
{
	[SerializeField] float maxHealth = 100;
	public float CurrentHealth { get; private set; }
	public bool IsDead { get; private set; }

	private void Start()
	{
		CurrentHealth = maxHealth;
		IsDead = false;
	}

	public void Damage(float damageAmount)
	{
		if (IsDead || !OnDamaged(damageAmount))
			return;
		CurrentHealth = Mathf.Clamp(CurrentHealth - damageAmount, 0, maxHealth);

		if (CurrentHealth <= 0)
			IsDead = OnDeath() | IsDead;
	}

	public void Heal(float healAmount)
	{
		if (IsDead || !OnHealed(healAmount))
			return;
		CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);

		if (CurrentHealth <= 0) //(could happen if healAmount is negative)
			IsDead = OnDeath() | IsDead;
	}

	public void Revive(float healAmount)
	{
		if (IsDead && OnRevive(healAmount) && healAmount > 0)
		{
			CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);
			IsDead = false;
		}
	}

	/// <summary>
	/// Called when player health is set to zero
	/// </summary>
	/// <returns>Whether or not to continue and set dead to true</returns>
	protected virtual bool OnDeath()
	{
		return true;
	}

	protected virtual bool OnRevive(float healAmount)
	{
		return true;
	}

	/// <summary>
	/// Called before healing the player
	/// </summary>
	/// <returns>Whether or not to continue and heal the player</returns>
	protected virtual bool OnHealed(float healAmount)
	{
		return true;
	}

	/// <summary>
	/// Called before damaging the player
	/// </summary>
	/// <returns>Whether or not to continue and damage the player</returns>
	protected virtual bool OnDamaged(float damageAmount)
	{
		return true;
	}
}
