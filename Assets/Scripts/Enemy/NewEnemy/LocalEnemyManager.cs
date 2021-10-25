using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LocalEnemyManager : MonoBehaviour
{
	public Vector2 patrolBounds = Vector2.one * 3;
	public float activateDistance = 300;
	public EnemyStartData[] enemyStartData;
	public EnemyMotor enemyPrefab;
	public bool activateOnAwake;
	public float recalculatePathTime = 2;
	public float movementRange = 50;

	float recalculatePathTimer = 2;
	bool activated = false;
	bool allEnemiesAlerted;
	GlobalEnemyManager manager;
	List<EnemyMotor> enemies;

	private void Start()
	{
		enemies = new List<EnemyMotor>();
		manager = GameManager.Instance.EnemyManager;
		SpawnAll();
		if (activateOnAwake)
		{
			ActivateAll(true);
		}
	}

	void SpawnAll()
	{
		if (enemies.Count > 0) return;
		enemies.Capacity = enemyStartData.Length;
		//spawn all enemies and initialise their values
		for (int i = 0; i < enemyStartData.Length; i++)
		{
			enemies.Add(Instantiate(enemyPrefab.gameObject, transform, false).GetComponent<EnemyMotor>());
			enemies[i].transform.position += enemyStartData[i].position;
			enemies[i].transform.rotation *= Quaternion.Euler(0, enemyStartData[i].rotation, 0);
			enemies[i].Initialize(this);
			enemies[i].gameObject.SetActive(false);
		}
	}

	void ActivateAll(bool activate)
	{
		if (activate == activated) return;

		activated = activate;
		for (int i = 0; i < enemies.Count; i++)
		{
			enemies[i].gameObject.SetActive(true);
		}
	}

	public void OnEnemyDeath(GameObject enemy)
	{
		manager.OnEnemyDeath();
		enemies.Remove(enemy.GetComponent<EnemyMotor>());
	}

	private void FixedUpdate()
	{
		//activate when player reached activation distance
		if (!activated && (GameManager.Instance.Player.transform.position - transform.position).sqrMagnitude < activateDistance * activateDistance)
		{
			ActivateAll(true);
		}
		else if (allEnemiesAlerted)
		{
			recalculatePathTimer -= Time.deltaTime;
			//if all enemies alerted and it is time to calculate paths, calculate paths
			if (recalculatePathTimer <= 0)
			{
				//clamp destination to within movement range
				Vector3 destination = Vector3.MoveTowards(transform.position, GlobalManager.PlayerCentre, movementRange);

				recalculatePathTimer = recalculatePathTime;
				for (int i = 0; i < enemies.Count; i++)
				{
					if (enemies[i].State == EnemyMotor.EnemyState.TARGETTING)
						enemies[i].OverwriteDestination(destination);
				}
			}
		}

	}

	public Vector3 GetRandomPatrolPoint()
	{
		Vector3 patrolPoint;
		patrolPoint = transform.position + transform.TransformVector(new Vector3(Random.Range(-patrolBounds.x/2, patrolBounds.x/2), 0, Random.Range(-patrolBounds.x / 2, patrolBounds.x / 2)));
		return patrolPoint;
	}

	private void OnDrawGizmosSelected()
	{
		Gizmos.matrix = Matrix4x4.TRS(transform.position, Quaternion.LookRotation(Vector3.ProjectOnPlane(transform.forward,Vector3.up), Vector3.up), Vector3.one);
		Gizmos.color = Color.red;
		Gizmos.DrawWireCube(Vector3.up * 2.5f, new Vector3(patrolBounds.x, 5, patrolBounds.y));
	}

	public bool EnemiesAlerted { get { return allEnemiesAlerted; } set { allEnemiesAlerted = value; } }
	public GlobalEnemyManager GlobalManager { get { return manager; } }

	[System.Serializable]
	public struct EnemyStartData
	{
		public Vector3 position;
		public float rotation;
	}
}
