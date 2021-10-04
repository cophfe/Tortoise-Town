using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class MovingPlatform : MonoBehaviour
{
	public bool playOnAwake = true;
	[HideInInspector, SerializeField] bool useBezier = false;
	[HideInInspector, SerializeField] public BezierTangentMode bezierTangentMode = BezierTangentMode.Free;

	public float stopTime = 0;
	public float speed = 5;
	//relative to startPosition
	[HideInInspector] public Vector3[] points;
	public EaseMode ease = EaseMode.NONE;
	[HideInInspector] public LoopType loopType = LoopType.PINGPONG;
	[SerializeField, HideInInspector] Vector3 startPosition;
	[SerializeField, HideInInspector] Vector3[] tangents;
	bool playing = false;
	float totalLength;
	float[] lengthPerLine;
	float t = 0;
	float iterateAmount = 0;
	float stopTimer = 0;
	Vector3 prevPosition;

	public enum LoopType
	{
		PINGPONG,
		LOOP,
		RESTART, 
		ONCE
	}
	public enum EaseMode
	{
		NONE,
		INOUT
	}
	public enum BezierTangentMode
	{
		Free,
		Aligned,
		Mirrored
	}
	void Start()
    {
		startPosition = transform.position;
		CalculateLength();
		CalculateIteration();
		if (playOnAwake)
			Play();
	}
	
	void Update()
    {
		if (!playing) return;

		stopTimer -= Time.deltaTime;
		if (stopTimer > 0)
		{
			prevPosition = transform.position;
			return;
		}

		t += iterateAmount * Time.deltaTime;
		
		//check for end of loop
		if (loopType == LoopType.PINGPONG)
		{
			if (t > 1)
			{
				t = 1;
				iterateAmount = -Mathf.Abs(iterateAmount);
				stopTimer = stopTime;
			}
			else if (t < 0)
			{
				stopTimer = stopTime;
				iterateAmount = Mathf.Abs(iterateAmount);
				t = 0;
			}
		}
		else if (t >= 1)
		{
			t = 0;
			stopTimer = stopTime;
			if (loopType == LoopType.ONCE) Pause();
			prevPosition = transform.position;
			return;
		}
		
		float easedT = GetEasedT();
		float currentDistance = easedT * totalLength;
		float dist = 0;
		Vector3 position = startPosition;
		for (int i = 0; i < lengthPerLine.Length; i++)
		{
			dist += lengthPerLine[i];
			if (dist >= currentDistance)
			{
				Vector3 prevPoint = i - 1 >= 0 ? points[i - 1] : Vector3.zero;
				if (useBezier)
				{
					position = startPosition + GetPointOnBezierCurve(prevPoint, points[i], tangents[2*i], tangents[2*i + 1], (currentDistance - (dist - lengthPerLine[i])) / lengthPerLine[i]);
				}
				else
				{
					position = startPosition + Vector3.Lerp(prevPoint, points[i], (currentDistance - (dist - lengthPerLine[i])) / lengthPerLine[i]);
				}
				break;
			}
		}
		//Debug.Log("speed is " + (transform.position - position).magnitude /Time.deltaTime);
		
		prevPosition = transform.position;
		transform.position = position;
	}

	void CalculateLength()
	{
		totalLength = 0;
		lengthPerLine = new float[points.Length];

		if (points.Length > 0)
		{
			if (useBezier)
			{
				lengthPerLine[0] = ApproximateBezierCurveLength(Vector3.zero, points[0], tangents[0], tangents[1]);
				totalLength += lengthPerLine[0];

				for (int i = 1; i < points.Length; i++)
				{
					lengthPerLine[i] = ApproximateBezierCurveLength(points[i - 1], points[i], tangents[2*i], tangents[2*i + 1]);
					totalLength += lengthPerLine[i];
				}
			}
			else 
			{ 
				lengthPerLine[0] = points[0].magnitude;
				totalLength += lengthPerLine[0];

				for (int i = 1; i < points.Length; i++)
				{
					lengthPerLine[i] = (points[i - 1] - points[i]).magnitude;
					totalLength += lengthPerLine[i];
				}
			}
		}
	}

	const int bezierCurveSteps = 10;
	float ApproximateBezierCurveLength(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent)
	{
		float length = 0;
		float t;
		Vector3 previousPoint = start;
		for (int i = 0; i < bezierCurveSteps; i++)
		{
			t = (float)(i + 1) / bezierCurveSteps;
			Vector3 nextPoint = GetPointOnBezierCurve(start, end, startTangent, endTangent, t);
			length += (nextPoint - previousPoint).magnitude;
			previousPoint = nextPoint;
		}
		return length;
	}

	Vector3 GetPointOnBezierCurve(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		float opT = (1 - t);
		//formula for cubic bezier curve is here: 
		return opT * opT * opT * start + t * t * t * end + 3f * opT * opT * t * (start + startTangent) + 3f * opT * t * t * (end + endTangent);
	}
	public Vector3 GetPlayerOffset()
	{
		return transform.position - prevPosition;
	}

	void CalculateIteration()
	{
		iterateAmount =  speed / totalLength;
	}

	public void Play()
	{
		playing = true;
	}

	public void Pause()
	{
		playing = false;
	}

	float GetEasedT()
	{
		switch (ease)
		{
			case EaseMode.INOUT:
				return Ease.EaseInOutQuad(t);
			default:
				return t;
		}
	}

}
