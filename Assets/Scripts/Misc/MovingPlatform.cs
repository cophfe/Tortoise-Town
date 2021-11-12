using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[DefaultExecutionOrder(11), RequireComponent(typeof(Rigidbody))]
public class MovingPlatform : BooleanSwitch
{
	Rigidbody rb;

	[HideInInspector] public bool align = false;
	[HideInInspector, SerializeField] bool useBezier = false;
	[HideInInspector, SerializeField] public bool automaticallyCalculateBezierCurve = false;
	[HideInInspector, SerializeField] public IntermediateControlPointType intermediateType = IntermediateControlPointType.Free;

	public float stopTime = 0;
	public float startDelay = 0;
	public float speed = 5;
	//relative to startPosition
	[HideInInspector] public Vector3[] points;
	public EaseMode ease = EaseMode.NONE;
	[HideInInspector] public LoopType loopType = LoopType.PINGPONG;
	public Vector3 StartPosition { get; private set; }
	public Quaternion StartRotation { get; private set; }
	[SerializeField, HideInInspector] Vector3[] intermediates = null;
	bool playing = false;
	float t = 0;
	float iterateAmount = 0;
	float stopTimer = 0;
	int negMultiply = 1;
	PlayerController player;
	BoxCollider platformCollider;

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

	protected override void Start()
    {
		rb = GetComponent<Rigidbody>();
		StartPosition = rb.position;
		StartRotation = rb.rotation;
		stopTimer = stopTime + startDelay;
		platformCollider = GetComponentInChildren<BoxCollider>();
		base.Start();
	}
	
	void FixedUpdate()
    {
		if (!playing) return;

		stopTimer -= Time.deltaTime;
		if (stopTimer > 0)
			return;
		else if (player && loopType == LoopType.RESTART && t == 0)
		{
			AssignPlayer(null);
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

			if (loopType == LoopType.ONCE) 
				Pause();
			else if (loopType == LoopType.LOOP)
				t -= 1;
			else
			{
				t = 0;
				return;
			}
		}
		
		float easedT = GetEasedT();

		if (player)
		{
			Vector3 playerPos = transform.InverseTransformPoint(player.transform.position);

			transform.position = GetPointOnSpline(easedT);

			var t = transform.TransformPoint(playerPos) - player.transform.position;
			if (t.y < 0)
			{
				//need to disable collider if y less than 0, because otherwise the character controller will collide with it
				platformCollider.enabled = false;
				player.CharacterController.Move(transform.TransformPoint(playerPos) - player.transform.position);
				platformCollider.enabled = true;
			}
			else
			{
				player.CharacterController.Move(transform.TransformPoint(playerPos) - player.transform.position);
			}
		}
		else
		{
			transform.position = GetPointOnSpline(easedT);
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
			return TransformPoint(GetPointOnBezierCurve(prevPoint, points[i], intermediates[2 * i], intermediates[2 * i + 1], localT));
		}
		else
		{
			iterateAmount = GetCurrentSpeed(prevPoint, points[i]);
			return TransformPoint(GetPointOnLine(prevPoint, points[i], localT));
		}
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
		gradient = end - start;
		return speed / ((gradient).magnitude * points.Length);
	}

	Vector3 gradient = Vector3.zero;
	float GetCurrentSpeed(Vector3 start, Vector3 end, Vector3 startTangent, Vector3 endTangent, float t)
	{
		//derivitive of displacement is velocity (with time as t axis), so this is just the derivitive of the bezier curve function
		Vector3 b = startTangent + start;
		Vector3 c = endTangent + end;
		gradient = t * t * (-3 * start + 9 * b - 9 * c + 3 * end) + t * (6 * start - 12 * b + 6 * c) + (-3 * start + 3 * b);
		return speed / (gradient.magnitude * points.Length);
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

	float GetEasedAcceleration()
	{
		switch (ease)
		{
			case EaseMode.INOUT:
				return t < 0.5 ? 4 * t : 4 - 4*t;
			default:
				return 1;
		}
	}

	public void AssignPlayer(PlayerController player)
	{
		if (this.player != null && player != this.player)
		{
			if (Time.timeScale != 0)
			{
				this.player.Motor.ForcesVelocity += StartRotation * gradient.normalized * iterateAmount * GetEasedAcceleration() / Time.unscaledDeltaTime * this.player.Motor.movingPlatformForceMultiplier;
			}
		}
		this.player = player;
	}

	Vector3 TransformPoint(Vector3 vec)
	{
		return StartRotation * vec + StartPosition;
	}

	Vector3 InverseTransformPoint(Vector3 vec)
	{
		return Quaternion.Inverse(StartRotation) * (vec - StartPosition);
	}
}
