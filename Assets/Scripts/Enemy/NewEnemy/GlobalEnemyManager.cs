using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class GlobalEnemyManager : MonoBehaviour
{
	int totalEnemyCount = 0;
	Vector3 playerCentre;
	PlayerController player;

	private void Start()
	{
		player = GameManager.Instance.Player;
	}
	private void FixedUpdate()
	{
		playerCentre = GetPlayerCentre();
	}

	public void RegisterLocalEnemyManager(LocalEnemyManager manager)
	{
		//totalEnemyCount += manager.Length;
	}

	public void OnEnemyDeath()
	{
		totalEnemyCount--;
	}

	Vector3 GetPlayerCentre()
	{
		var CC = GameManager.Instance.Player.CharacterController;
		//does not account for skin width but whatever
		return GameManager.Instance.Player.transform.TransformPoint(CC.center);
	}

	public Vector3 PlayerCentre {  get { return playerCentre; } }
}
