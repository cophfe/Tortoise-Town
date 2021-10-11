using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class PlayerCombat : MonoBehaviour
{
	PlayerController playerController;

	public GameObject rangedWeapon;
	public GameObject meleeWeapon;
	public GameObject arrowPrefab;

	public float meleeDamage = 10;
	public float rangedDamage = 10;

	public float meleeCooldownTime = 0.5f;
	public float rangedCooldownTime = 0.5f;
	[Min(0.001f)] public float rangedChargeUpSpeed = 2;
	[Min(0.001f)] public float rangedChargeDownSpeed= 4;

	public UnityEvent onAttack;
	public UnityEvent onChargeUp;

	bool charging = false;
	float chargeUpPercent = 0;
	float cooldownTimer = 0;

	WeaponType currentWeapon = WeaponType.NONE;
	public enum WeaponType
	{
		MELEE,
		RANGED,
		NONE
	}

	private void Start()
	{
		playerController = GetComponent<PlayerController>();
	}

	private void FixedUpdate()
	{
		cooldownTimer -= Time.fixedDeltaTime;

		if (charging)
		{
			chargeUpPercent = Mathf.Min(chargeUpPercent + Time.deltaTime * rangedChargeUpSpeed, 1);
		}
		else
		{
			chargeUpPercent = Mathf.Max(chargeUpPercent - Time.deltaTime * rangedChargeDownSpeed, 0);
		}

		if (chargeUpPercent > 0)
		{
			EquipWeapon(WeaponType.RANGED);
			playerController.Motor.alwaysLookAway = true;

		}
		else
		{
			playerController.Motor.alwaysLookAway = false;
		}

	}

	public void StartChargeUp()
	{
		charging = true;
	}

	public void EndChargeUp()
	{
		charging = false;
	}

	public void EquipWeapon(WeaponType weaponType)
	{
		if (currentWeapon == weaponType) return;
		
		switch (weaponType)
		{
			case WeaponType.MELEE:
				rangedWeapon.SetActive(false);
				meleeWeapon.SetActive(true);
				break;
			case WeaponType.RANGED:
				rangedWeapon.SetActive(true);
				meleeWeapon.SetActive(false);
				break;
			case WeaponType.NONE:
				rangedWeapon.SetActive(false);
				meleeWeapon.SetActive(false);
				break;
		}
		currentWeapon = weaponType;
	}

	public float ChargePercentage { get { return Mathf.Clamp01(chargeUpPercent); } }
}
