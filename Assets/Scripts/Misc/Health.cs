using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Health : MonoBehaviour
{
	[SerializeField] protected float maxHealth = 100;
	public float CurrentHealth { get; protected set; }
	public bool IsDead { get; protected set; }

	protected virtual void Start()
	{
		CurrentHealth = maxHealth;
		IsDead = false;
	}

	public void Damage(float damageAmount)
	{
		if (IsDead)
			return;
		CurrentHealth = Mathf.Clamp(CurrentHealth - damageAmount, 0, maxHealth);
		OnDamaged(damageAmount);

		if (CurrentHealth <= 0)
		{
			IsDead = true;
			OnDeath();
		}
	}

	public void Heal(float healAmount)
	{
		if (IsDead)
			return;
		CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);
		OnHealed(healAmount);
		
		//(could happen if healAmount is negative)
		if (CurrentHealth <= 0)
		{
			IsDead = true;
			OnDeath();
		}
	}

	public void Revive(float healAmount)
	{
		if (IsDead && healAmount > 0)
		{
			CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);
			IsDead = false;
			OnRevive(healAmount);
		}
	}

	public virtual void ApplyKnockback(Vector3 knockbackVector)
	{

	}
	/// <summary>
	/// Called when player health is set to zero
	/// </summary>
	/// <returns>Whether or not to continue and set dead to true</returns>
	protected virtual void OnDeath()
	{
	}

	protected virtual void OnRevive(float healAmount)
	{
	}

	/// <summary>
	/// Called before healing the player
	/// </summary>
	/// <returns>Whether or not to continue and heal the player</returns>
	protected virtual void OnHealed(float healAmount)
	{
	}

	/// <summary>
	/// Called before damaging the player
	/// </summary>
	/// <returns>Whether or not to continue and damage the player</returns>
	protected virtual void OnDamaged(float damageAmount)
	{
	}
}
