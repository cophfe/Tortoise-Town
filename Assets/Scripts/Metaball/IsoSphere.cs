using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Jobs;

public class IsoSphere : IsoShape
{
	public float radius = 1;

	public override float GetIsoValue(Vector3 point, Transform generator)
	{
		Vector3 delta = transform.InverseTransformPoint(generator.TransformPoint(point));

		float ir = radius / delta.sqrMagnitude;
		float iso = negativeMultiplier * strength * ir * ir;
		return iso;
	}

	public override float GetIsoValueParallel(Vector3 point, ref TransformCapturedState generator)
	{
		Vector3 delta = generator.TransformPoint(point);
		delta = transformState.InverseTransformPoint(delta);
		float ir = radius/delta.sqrMagnitude;
		float iso = negativeMultiplier * strength * ir * ir;
		return iso;
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
