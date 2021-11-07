using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class MetaShape : MonoBehaviour
{
	public bool negative = false;
	MetaballGenerator generator = null;

	public abstract float GetIsoValue(Vector3 point, Transform generator);

	public abstract Bounds GetInfluenceBounds(float threshold, Transform generator);

	protected MetaballGenerator GetGenerator()
	{
		if (generator == null)
			generator = GetComponentInParent<MetaballGenerator>();
		return generator;
	}

	protected abstract void DrawMetaGizmos();

	private void OnDrawGizmos()
	{
		if (!enabled) return;
		Gizmos.color = negative ? Color.red : Color.green;
		Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.lossyScale);
		DrawMetaGizmos();
	}
}
