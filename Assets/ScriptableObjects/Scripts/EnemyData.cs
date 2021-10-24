using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "EnemyData", menuName = "ScriptableObjects/EnemyData", order = 1)]
public class EnemyData : ScriptableObject
{
	//PATROL STUFF
	public float stopTime = 2;
	public float stopVarience = 0.5f;
	[Range(0, 1)] public float stopChance = 0.3f;
	//DETECTION STUFF
	public float detectionRange = 30;
	public float attackRange = 2;
}
