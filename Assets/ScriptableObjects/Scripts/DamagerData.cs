using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "DamagerData", menuName = "ScriptableObjects/DamagerData", order = 1)]
public class DamagerData : ScriptableObject
{
	public int damageAmount = 1;
	public float knockbackAmount = 2;
	public float knockbackDuration = 0.1f;
	public float cameraShakeAmount = 2;
	public AnimationCurve knockbackCurve = null;
}
