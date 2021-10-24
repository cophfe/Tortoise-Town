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

	private void OnValidate()
	{
		if (controlPoints.Length == 0)
		{
			controlPoints = new Vector3[4];
			controlPoints[1] = Vector3.forward * 0.25f;
			controlPoints[2] = Vector3.forward * 0.75f;
			controlPoints[3] = Vector3.forward;
		}
		controlPoints[0] = Vector3.zero;
	}

	Vector3 GetPointOnSpline(float t)
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

	int GetCurveCount()
	{
		return (controlPoints.Length - 1) / 3;
	}

	Vector3 GetPointOnBezierCurve(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		float opT = (1 - t);
		return opT * opT * opT * start + 3 * t * opT * opT * startTangent + 3 * t * t * opT * endTangent + t * t * t * end;
	}
}
