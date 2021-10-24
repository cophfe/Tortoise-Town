using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class EnemyMotor : MonoBehaviour
{
	public EnemyData data;

	NavMeshAgent agent;
	LocalEnemyManager localManager;

	Vector3 startPosition;
	Vector3 targetPosition;
	float stopTimer = 0;
	EnemyState currentState = EnemyState.PATROL;
	//Idles when too far away from the player

	public enum EnemyState
	{
		PATROL,
		TARGETTING,
		ATTACKING
	}

	public void Initialize(LocalEnemyManager manager)
	{
		this.localManager = manager;
	}

	private void Start()
	{
		agent = GetComponent<NavMeshAgent>();
		startPosition = transform.position;
	}

	void Update()
    {
		stopTimer -= Time.deltaTime;

		switch (currentState)
		{
			case EnemyState.PATROL:
				{
					//check for player
					if (SeenPlayer())
					{
						//alert other enemies
						localManager.EnemiesAlerted = true;
						//target them
						currentState = EnemyState.TARGETTING;
					}
					else if (stopTimer <= 0)
					{
						//if reached the end of current path
						if (!agent.hasPath)
						{
							//get a new path
							targetPosition = localManager.GetRandomPatrolPoint();
							agent.destination = targetPosition;
							
							//then check if should stop for a moment
							if (Random.Range(0, 1.0f) < data.stopChance)
							{
								stopTimer = data.stopTime + Random.Range(0.0f, 1.0f) * data.stopVarience;
							}
						}
					}
				}
				break;
			case EnemyState.TARGETTING:
				{
					//Vector3 delta = GetPlayerCentre() - GetEnemyCentre();
					//if (delta.sqrMagnitude < data.attackRange * data.attackRange)
					//{
					//	agent.destination = GetPlayerCentre();
					//}
				}
				break;
			case EnemyState.ATTACKING:
				{

				}
				break;
		}
	}

	//Enemy manager will handle recalculating of paths through this function
	public void OverwriteDestination(Vector3 target)
	{
		agent.destination = target;

	}

	bool SeenPlayer()
	{
		if (localManager.EnemiesAlerted)
		{
			return true;
		}
		else
		{
			Vector3 playerPosition = GetPlayerCentre();
			Vector3 delta = playerPosition - GetEnemyCentre();
			//if inside of detection range && if raycast to player is unobstructed
			if (delta.sqrMagnitude < data.detectionRange * data.detectionRange
				&& Physics.Raycast(GetEnemyCentre(), delta, out var hit, data.detectionRange, 0xFFFFFF, QueryTriggerInteraction.Ignore))
			{
				//alert self
				return true;
			}
			//otherwise nothing was seen
			else return false;
		}
		
	}

	Vector3 GetPlayerCentre()
	{
		return localManager.GlobalManager.PlayerCentre;
	}

	Vector3 GetEnemyCentre()
	{
		return Vector3.up * agent.height / 2.0f + transform.position; 
	}
	public LocalEnemyManager LocalManager { get { return localManager; } }
	public EnemyState State { get { return currentState; } }
}
