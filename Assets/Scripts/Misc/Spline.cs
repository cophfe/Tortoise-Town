using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spline : MonoBehaviour
{
	[SerializeField] Vector3[] controlPoints;
	[SerializeField] bool loop;
	[SerializeField] RestrainType restrainType = RestrainType.MIRRORED;
	public RestrainType Restrain {  get { return restrainType; } 
	}
	[System.Serializable]
	public enum RestrainType
	{
		NONE, 
		ALIGNED,
		MIRRORED
	}

	public bool CheckLooping() { return loop; }

	private void OnValidate()
	{
		if (controlPoints == null || controlPoints.Length == 0)
		{
			controlPoints = new Vector3[4];
			controlPoints[1] = Vector3.forward * 0.25f;
			controlPoints[2] = Vector3.forward * 0.75f;
			controlPoints[3] = Vector3.forward;
		}
		controlPoints[0] = Vector3.zero;
	}

	public Vector3 GetPointOnSpline(float t)
	{
		int curveCount = GetCurveCount();
		int index = (int)(t * curveCount);
		float localT = t * curveCount - index;
		if (t >= 1)
		{
			localT = 1;
			index = controlPoints.Length - 1;
		}
		
		return transform.TransformPoint(GetPointOnBezierCurve(controlPoints[index], controlPoints[index + 3], controlPoints[index + 1], controlPoints[index + 2], localT));
	}

	public float GetIterateAmountOnSpline(float speed, float t)
	{
		int curveCount = GetCurveCount();
		int index = (int)(t * curveCount);
		float localT = t * curveCount - index;
		if (t >= 1)
		{
			localT = 1;
			index = controlPoints.Length - 1;
		}

		return GetIterateAmountOnCurve(speed, controlPoints[index], controlPoints[index + 3], controlPoints[index + 1], controlPoints[index + 2], localT, out _);
	}

	public void GetInfoOnSpline(float speed, float t, out Vector3 point, out float iterateAmount, out Vector3 direction)
	{
		int curveCount = GetCurveCount();
		int index = (int)(t * curveCount);
		float localT = t * curveCount - index;
		if (t >= 1)
		{
			localT = 1;
			index = GetCurveCount() - 1;
		}
		else if (t < 0)
		{
			localT = 0;
			index = 0;
		}

		index *= 3;
		point = transform.TransformPoint(GetPointOnBezierCurve(controlPoints[index], controlPoints[index + 3], controlPoints[index + 1], controlPoints[index + 2], localT));
		iterateAmount = GetIterateAmountOnCurve(speed, controlPoints[index], controlPoints[index + 3], controlPoints[index + 1], controlPoints[index + 2], localT, out direction);

	}
	public int GetCurveCount()
	{
		return (controlPoints.Length - 1) / 3;
	}

	public Vector3 GetPointOnBezierCurve(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		float opT = (1 - t);
		return opT * opT * opT * start + 3 * t * opT * opT * startTangent + 3 * t * t * opT * endTangent + t * t * t * end;
	}

	public float GetIterateAmountOnCurve(float speed, Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t, out Vector3 direction)
	{
		direction = t * t * (-3 * start + 9 * startTangent - 9 * endTangent + 3 * end) + t * (6 * start - 12 * startTangent + 6 * endTangent) + (-3 * start + 3 * startTangent);
		return speed / (direction.magnitude * GetCurveCount());
	}
}
