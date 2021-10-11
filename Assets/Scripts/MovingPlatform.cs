using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[DefaultExecutionOrder(11), RequireComponent(typeof(Rigidbody))]
public class MovingPlatform : BooleanSwitch
{
	Rigidbody rb;

	public bool playOnAwake = true;
	[HideInInspector] public bool align = false;
	[HideInInspector, SerializeField] bool useBezier = false;
	[HideInInspector, SerializeField] public bool automaticallyCalculateBezierCurve = false;
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
	float t = 0;
	float iterateAmount = 0;
	float stopTimer = 0;
	Vector3 prevPosition;
	int negMultiply = 1;
	const int bezierCurveSteps = 10;
	PlayerMotor player = null;

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

	public override bool SwitchValue { 
		get { return on; } 
		protected set 
		{ 
			on = value;
			if (value)
			{
				Play();
			}
			else
			{
				Pause();
			}
		} 
	}

	void Start()
    {
		rb = GetComponent<Rigidbody>();
		startPosition = rb.position;
		if (playOnAwake)
			Play();
	}
	
	void FixedUpdate()
    {
		if (!playing) return;

		stopTimer -= Time.deltaTime;
		if (stopTimer > 0)
		{
			prevPosition = rb.position;
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
			stopTimer = stopTime;
			prevPosition = rb.position;

			if (loopType == LoopType.ONCE) Pause();
			if (loopType == LoopType.LOOP)
				t -= 1;
			else
			{
				t = 0;
				return;
			}
		}
		
		float easedT = GetEasedT();
		Vector3 position = GetPointOnSpline(easedT);

		if (player != null)
		{
			Vector3 offset = rb.position - prevPosition;
			//offset.y = Mathf.Max(0, offset.y);
			player.MovingPlatformOffset = offset;
		}

		prevPosition = rb.position;
		rb.position = position;
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
		return speed / ((gradient).magnitude * points.Length);
	}

	float GetCurrentSpeed(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		//derivitive of displacement is velocity (with time as t axis), so this is just the derivitive of the bezier curve function
		Vector3 b = startTangent + start;
		Vector3 c = endTangent + end;
		Vector3 gradient = t * t * (-3 * start + 9 * b - 9 * c + 3 * end) + t * (6 * start - 12 * b + 6 * c) + (-3 * start + 3 * b);
		return speed / (gradient.magnitude * points.Length);
	}

	public void Play()
	{
		playing = true;
	}

	public void Pause()
	{
		playing = false;
		if (player)
			player.MovingPlatformOffset = Vector3.zero;
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

	public void SetConnectedPlayer(PlayerMotor player)
	{
		this.player = player;
	}
}
