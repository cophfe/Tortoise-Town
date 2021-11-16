using System.Collections;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif
using UnityEngine;
using UnityEngine.Jobs;

public abstract class IsoShape : MonoBehaviour
{
	public bool negative = false;
	public float strength = 1;
	IsosurfaceGenerator generator = null;

	protected int negativeMultiplier = 1;

	//cannot use gameobject.transform in parallel thread
	protected TransformCapturedState transformState;

	public void InitializeForParallel()
	{
		transformState = new TransformCapturedState(transform);
		negativeMultiplier = negative ? -1 : 1;
	}

	public abstract float GetIsoValue(Vector3 point, Transform generator);
	public abstract float GetIsoValueParallel(Vector3 point, ref TransformCapturedState generator);

	public abstract Bounds GetInfluenceBounds(float threshold, Transform generator);

	protected IsosurfaceGenerator GetGenerator()
	{
		if (generator == null)
			generator = GetComponentInParent<IsosurfaceGenerator>();
		return generator;
	}

	public abstract void DrawMetaGizmos();
	public abstract void DrawMetaGizmosSelected();

#if UNITY_EDITOR
	private void OnDrawGizmosSelected()
	{
		var selected = Selection.activeTransform;
		var generatorObject = GetGenerator().transform;
		bool generatorIsSelected;

		do
		{
			generatorIsSelected = generatorObject == selected;
			generatorObject = generatorObject.parent;
		}
		while (generatorObject != null && !generatorIsSelected);
		
		if (generatorIsSelected)
		{
			DrawMetaGizmos();
		}
		else
		{
			GetGenerator().DrawEveryGizmo();
			DrawMetaGizmosSelected();
		}
	}
#endif

	
}

public struct TransformCapturedState
{
	public readonly Vector3 position;
	public readonly Quaternion rotation;
	public readonly Vector3 scale;
	public readonly Vector3 localScale;
	public readonly Matrix4x4 localToWorld;
	public readonly Matrix4x4 worldToLocal;

	public TransformCapturedState(Transform transform)
	{
		position = transform.position;
		rotation = transform.rotation;
		scale = transform.lossyScale;
		localScale = transform.localScale;
		localToWorld = transform.localToWorldMatrix;
		worldToLocal = transform.worldToLocalMatrix;
	}

	public Vector3 TransformPoint(Vector3 point)
	{
		//return (rotation * Vector3.Scale(point, scale) + position);
		return localToWorld.MultiplyPoint3x4(point);
	}

	public Vector3 InverseTransformPoint(Vector3 point)
	{
		//return Quaternion.Inverse(rotation) * (point - position);
		return worldToLocal.MultiplyPoint3x4(point);
	}

	
}
