using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "GooDamageData", menuName = "ScriptableObjects/GooDamageData", order = 1)]
public class GooDamageData : ScriptableObject
{
	public int damageAmount = 1;
	public float knockbackAmount = 2;
	public float knockbackDuration = 0.1f;
	public AnimationCurve knockbackCurve = null;
}
