using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public abstract class MetaShape : MonoBehaviour
{
	public bool negative = false;
	MetaballGenerator generator = null;

	public abstract float GetDistance(Vector3 point);

	protected virtual void Awake()
	{
		generator = GetComponentInParent<MetaballGenerator>();
		if (generator)
			generator.metaShapes.Add(this);
	}

	protected virtual void OnDestroy()
	{
		if (transform.parent)
		{
			MetaballGenerator gen = GetGenerator();
			if (gen)
				gen.metaShapes.Remove(this);
		}
	}

	protected MetaballGenerator GetGenerator()
	{
		if (generator == null)
			generator = GetComponentInParent<MetaballGenerator>();
		return generator;
	}
}
