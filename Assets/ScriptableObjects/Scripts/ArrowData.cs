using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "ArrowData", menuName = "ScriptableObjects/ArrowData", order = 1)]
public class ArrowData : ScriptableObject
{
	public float maxInitialSpeed = 50;
	public float rotateSpeed = 10;
	public float damage = 10;
	public float gravity = 9;
	public float arrowPenetratePercent = 0.2f;
	public LayerMask ignoreCollisionLayers;
	public float arrowLength = 0.3f;
	public float radius = 0.1f;
	public float disappearTime = 0.1f;
}
