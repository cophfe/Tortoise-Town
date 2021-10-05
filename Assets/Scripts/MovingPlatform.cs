using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class MovingPlatform : MonoBehaviour
{
	public bool playOnAwake = true;
	[HideInInspector] public bool align = false;
	[HideInInspector, SerializeField] bool useBezier = false;
	[HideInInspector, SerializeField] bool automaticallyCalculateBezierCurve = false;
	[HideInInspector, SerializeField] public IntermediateControlPointType intermediateType = IntermediateControlPointType.Free;

	public float stopTime = 0;
	public float speed = 5;
	//relative to startPosition
	[HideInInspector] public Vector3[] points;
	public EaseMode ease = EaseMode.NONE;
	[HideInInspector] public LoopType loopType = LoopType.PINGPONG;
	[SerializeField, HideInInspector] Vector3 startPosition;
	[SerializeField, HideInInspector] Vector3[] intermediates = null;
	bool playing = false;
	float totalLength;
	float[] lengthPerLine;
	float t = 0;
	float iterateAmount = 0;
	float stopTimer = 0;
	Vector3 prevPosition;
	int negMultiply = 1;
	const int bezierCurveSteps = 10;
	Vector3 velocity = Vector3.zero;

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
	public enum IntermediateControlPointType
	{
		Free,
		Aligned,
		Mirrored
	}
	void Start()
    {
		startPosition = transform.position;
		CalculateLength();
		if (playOnAwake)
			Play();
	}
	
	void FixedUpdate()
    {
		if (!playing) return;

		stopTimer -= Time.deltaTime;
		if (stopTimer > 0)
		{
			prevPosition = transform.position;
			return;
		}

		t += negMultiply * iterateAmount * Time.deltaTime;
		
		//check for end of loop
		if (loopType == LoopType.PINGPONG)
		{
			if (t >= 1)
			{
				t = 1;
				negMultiply = -1;
				stopTimer = stopTime;
			}
			else if (t < 0)
			{
				stopTimer = stopTime;
				negMultiply = 1;
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
		Vector3 position = GetPointOnSpline(easedT);

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
				lengthPerLine[0] = ApproximateBezierCurveLength(Vector3.zero, points[0], intermediates[0], intermediates[1]);
				totalLength += lengthPerLine[0];

				for (int i = 1; i < points.Length; i++)
				{
					lengthPerLine[i] = ApproximateBezierCurveLength(points[i - 1], points[i], intermediates[2*i], intermediates[2*i + 1]);
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

	Vector3 GetPointOnSpline(float t)
	{
		int i = (int)(t * (points.Length));
		float localT = (t * (points.Length)) - i;
		if (t >= 1)
		{
			localT = 1;
			i = points.Length - 1;
		}
		Vector3 prevPoint = i - 1 >= 0 ? points[i - 1] : Vector3.zero;

		if (useBezier)
		{
			iterateAmount = GetCurrentSpeed(prevPoint, points[i], intermediates[2 * i], intermediates[2 * i + 1], localT);
			return startPosition + GetPointOnBezierCurve(prevPoint, points[i], intermediates[2 * i], intermediates[2 * i + 1], localT);
		}
		else
		{
			iterateAmount = GetCurrentSpeed(prevPoint, points[i]);
			return startPosition + GetPointOnLine(prevPoint, points[i], localT);
		}
	}

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
		//formula for cubic bezier curve is here: (it is a bunch of lerps) 
		return opT * opT * opT * start + 3 * t * opT * opT * (start + startTangent) + 3 * t * t * opT * (end + endTangent) + t * t * t * end;
	}

	Vector3 GetPointOnLine(Vector3 start, Vector3 end, float t)
	{
		return start + t * (end - start);
	}

	float GetCurrentSpeed(Vector3 start, Vector3 end)
	{
		Vector3 gradient = end - start;
		velocity = gradient;
		return speed / ((gradient).magnitude * points.Length);
	}

	float GetCurrentSpeed(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		float opT = 1 - t;
		//derivitive of displacement is velocity (with time as t axis), so this is just the derivitive of the bezier curve function
		Vector3 b = startTangent + start;
		Vector3 c = endTangent + end;
		Vector3 gradient = t * t * (-3 * start + 9 * b - 9 * c + 3 * end) + t * (6 * start - 12 * b + 6 * c) + (-3 * start + 3 * b);
		velocity = gradient / points.Length;
		return speed / (gradient.magnitude * points.Length);
	}

	public Vector3 GetVelocity()
	{
		float time = Time.timeScale == 0 ? 0 : Time.fixedDeltaTime;
		Vector3 vel = (transform.position - prevPosition) / time;
		return new Vector3(vel.x, 0, vel.z);
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
