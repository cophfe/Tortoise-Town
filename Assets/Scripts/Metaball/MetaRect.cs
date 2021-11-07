using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MetaRect : MetaShape
{
	public Vector3 size = Vector3.one;

	public override float GetIsoValue(Vector3 point, Transform generator)
	{
		Vector3 delta = transform.InverseTransformPoint(generator.TransformPoint(point));
		Vector3 r = size / 2;
		//last bit is just getting the biggest component value unless it is positive
		float iso = Mathf.Min((r.x*r.x)/(delta.x*delta.x), (r.y * r.y) / (delta.y * delta.y), (r.z * r.z) / (delta.z * delta.z));
		return negative ? -iso : iso;
	}

	public override Bounds GetInfluenceBounds(float threshold, Transform generator)
	{
		
		return new Bounds(generator.InverseTransformPoint(transform.position), transform.TransformVector(size));
	}

	protected override void DrawMetaGizmos()
	{
		Gizmos.DrawWireCube(Vector3.zero, size);
	}
}
