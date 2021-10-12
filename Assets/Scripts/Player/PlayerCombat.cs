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

	public UnityEvent onMeleeAttack;
	public UnityEvent onRangedAttack;
	public UnityEvent onWeaponChange;

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
		playerController.Motor.onChangeRoll.AddListener(OnChangeRoll);
	}

	private void FixedUpdate()
	{
		if (cooldownTimer >= 0)
		{
			cooldownTimer -= Time.deltaTime;
			playerController.EvaluateAttackPressed();
			return;
		}
		
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
			if (playerController.EvaluateAttackPressed())
			{
				cooldownTimer = rangedCooldownTime;
				onRangedAttack.Invoke();
				chargeUpPercent = 0.0001f;
			}

		}
		else
		{
			playerController.Motor.alwaysLookAway = false;
			if (playerController.EvaluateAttackPressed())
			{
				cooldownTimer = meleeCooldownTime;
				EquipWeapon(WeaponType.MELEE);
				onMeleeAttack.Invoke();
			}
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

	void OnChangeRoll()
	{
		EquipWeapon(WeaponType.NONE);
		chargeUpPercent = 0;
		charging = false;
	}
	public float ChargePercentage { get { return Mathf.Clamp01(chargeUpPercent); } }
}
