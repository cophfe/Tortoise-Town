using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Metaball : MetaShape
{
	public float radius = 1;

	public override float GetDistance(Vector3 point)
	{
		Vector3 delta = point - transform.localPosition;
		float dist = (radius * radius) / (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
		return negative ? -dist : dist;
	}

	private void OnDrawGizmosSelected()
	{
		Gizmos.color = Color.red;
		Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
		Gizmos.DrawWireSphere(Vector3.zero, radius);
	}
}
