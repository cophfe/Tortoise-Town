using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(LineRenderer))]
public class BowString : MonoBehaviour
{
	public int extraPointsPerSide = 0;
	public Vector3 finalTensePoint;
	Vector3 initialTensePoint;
	int midIndex;
	LineRenderer lineRenderer;
	private void Awake()
	{
		lineRenderer = GetComponent<LineRenderer>();

		initialTensePoint = lineRenderer.GetPosition(1);

	}

	public Vector3 GetFirstPoint()
	{
		return initialTensePoint;
	}

	public void LerpNewPoint(float t)
	{
		lineRenderer?.SetPosition(1, Vector3.Lerp(initialTensePoint, finalTensePoint, t));
	}

	private void OnDrawGizmosSelected()
	{
		Gizmos.DrawSphere(transform.TransformPoint(finalTensePoint), 0.1f);
	}
}
