using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Metaball : MetaShape
{
	public float radius = 1;

	public override float GetIsoValue(Vector3 point, Transform generator)
	{
		Vector3 delta = transform.InverseTransformPoint(generator.TransformPoint(point));
		float iso = (radius * radius) / (delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
		return negative ? -iso : iso;
	}

	public override Bounds GetInfluenceBounds(float threshold, Transform generator)
	{
		float r = 3 * (radius / threshold);
		return new Bounds(generator.InverseTransformPoint(transform.position), transform.TransformVector(new Vector3(r, r, r)));
	}

	protected override void DrawMetaGizmos()
	{
		Gizmos.DrawWireSphere(Vector3.zero, radius);
	}
}
