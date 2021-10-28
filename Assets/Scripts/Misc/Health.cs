using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Health : MonoBehaviour
{
	[SerializeField] protected int maxHealth = 1;
	

	public int CurrentHealth { get; protected set; }
	public bool IsDead { get; protected set; }

	protected virtual void Start()
	{
		CurrentHealth = maxHealth;
		IsDead = false;
	}

	public virtual bool Damage(int damageAmount)
	{
		if (IsDead)
			return false;
		CurrentHealth = Mathf.Clamp(CurrentHealth - damageAmount, 0, maxHealth);

		if (CurrentHealth <= 0)
		{
			OnDeath();
		}
		return true;
	}

	public virtual bool Heal(int healAmount)
	{
		if (IsDead)
			return false;

		CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);
		
		//(could happen if healAmount is negative)
		if (CurrentHealth <= 0)
		{
			OnDeath();
		}
		return true;
	}

	public virtual bool Revive(int healAmount)
	{
		if (IsDead && healAmount > 0)
		{
			CurrentHealth = Mathf.Clamp(CurrentHealth + healAmount, 0, maxHealth);
			IsDead = false;
		}
		return true;
	}

	/// <summary>
	/// Called when player health is set to zero
	/// </summary>
	/// <returns>Whether or not to continue and set dead to true</returns>
	protected virtual void OnDeath()
	{
		IsDead = true;
	}
}
