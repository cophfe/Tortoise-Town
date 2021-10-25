using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class PlayerHealth : Health
{
	PlayerController controller;
	protected override void Start()
	{
		controller = GameManager.Instance.Player;
		base.Start();
	}

	protected override void OnDamaged(float damageAmount)
	{
		//set GUI
		
		//set Animation

	}

	protected override void OnDeath()
	{
		GameManager.Instance.OnPlayerDeath();
	}
}
