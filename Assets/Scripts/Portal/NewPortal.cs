using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewPortal : BooleanSwitch, IBooleanSaveable
{
	public bool Open { get; private set; } = false;
	public Renderer Renderer { get; private set; }
	List<NewPortalTraveller> travelling;
	new BoxCollider collider;
	Transform renderBox;

	//open transition
	Vector3 initialScale;
	float openSpeed = 0.5f;
	Spherize spherizer;
	bool transitioning = false;
	float t = 0;

	public NewPortal OtherPortal { get; set; }

	public bool InitialSaveState { get; private set; }

	void Awake()
	{
		Renderer = GetComponentInChildren<Renderer>();
		travelling = new List<NewPortalTraveller>();
		collider = GetComponent<BoxCollider>();
		GameManager.Instance.SaveManager.RegisterSaveable(this);

		spherizer = GetComponentInChildren<Spherize>();
		initialScale = transform.localScale;
		InitialSaveState = SwitchOnAwake;
	}

	protected override void Start()
	{
		base.Start();
		if (!on)
		{
			Renderer.enabled = false;
			t = 0;
		}
		else
		{
			t = 1;
		}
	}

	private void OnTriggerEnter(Collider other)
	{
		var traveller = other.GetComponent<NewPortalTraveller>();

		if (traveller && traveller.enabled && !travelling.Contains(traveller))
		{
			traveller.OnEnter(this, OtherPortal);
			travelling.Add(traveller);
		}
	}
	private void OnTriggerExit(Collider other)
	{
		var traveller = other.GetComponent<NewPortalTraveller>();
		if (traveller)
		{
			travelling.Remove(traveller);
		}
	}

	public List<NewPortalTraveller> GetTravellers()
	{
		return travelling;
	}

	public void TempTravelStart()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].MoveToNextPortal();
		}
	}

	public void TempTravelEnd()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].RevertMove();
		}
	}

	public void TeleportTravellers()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].UpdateTeleport();
		}
	}
	public Vector3 TransformPositionToOtherPortal(Vector3 position)
	{
		//get position relative to this portal
		Vector3 inPosition = transform.InverseTransformPoint(position);
		//flip to opposite side
		inPosition = Quaternion.Euler(0, 180, 0) * inPosition;
		//set final positions relative to the other portal
		Vector3 outPosition = OtherPortal.transform.TransformPoint(inPosition);
		return outPosition;
	}

	public Quaternion TransformRotationToOtherPortal( Quaternion rotation)
	{
		//get position relative to this portal
		Quaternion inRotation = Quaternion.Inverse(transform.rotation) * rotation;
		//flip to opposite side
		inRotation = Quaternion.Euler(0, 180, 0) * inRotation;
		//set final positions relative to the out portal
		Quaternion outRotation = OtherPortal.transform.rotation * inRotation;
		return outRotation;
	}

	public Vector3 TransformDirectionToOtherPortal(Vector3 direction)
	{
		//get position relative to this portal
		Vector3 inDirection = transform.InverseTransformDirection(direction);
		//flip to opposite side
		inDirection = Quaternion.Euler(0, 180, 0) * inDirection;
		//set final positions relative to the other portal
		Vector3 outDirection = OtherPortal.transform.TransformDirection(inDirection);
		return outDirection;
	}

	public bool CheckPointInBounds(Vector3 point)
	{
		return point == collider.ClosestPoint(point);
	}

	public bool CheckPointInBounds2D(Vector3 point)
	{
		point = collider.transform.InverseTransformPoint(point);

		return point.x > collider.center.x - collider.size.x / 2 && point.x < collider.center.x + collider.size.x / 2
			&& point.y > collider.center.y - collider.size.y / 2 && point.y < collider.center.y + collider.size.y / 2;
	}

	public Transform GetRenderBox()
	{
		return Renderer.transform;
	}

	public override bool SwitchValue
	{
		get => base.SwitchValue; protected set
		{
			if (on != value)
			{
				transitioning = true;
				if (value)
				{
					Renderer.enabled = true;
					Open = true;
				}

				on = value;
				collider.enabled = on;
			}
		}
	}

	private void Update()
	{
		if (transitioning)
		{
			if (on)
			{
				t += Time.deltaTime * openSpeed;

				if (t >= 1)
				{
					transitioning = false;
					t = 1;
				}
			}
			else
			{
				t -= Time.deltaTime * openSpeed;
				if (t <= 0)
				{
					t = 0;
					Renderer.enabled = false;
					transitioning = false;
					Open = false;
				}

			}

			if (spherizer)
				spherizer.PercentSpherized = 1 - Ease.EaseOutPower(t, 4);
			transform.localScale = GetScale(t);
		}
	}

	Vector3 GetScale(float t)
	{
		Vector3 scale = initialScale;
		if (t < 0.001f)
			t = 0.001f;

		scale.y *= Ease.EaseOutQuad(t);
		scale.x *= Ease.EaseOutQuad(t);
		scale.z *= t;
		return scale;
	}

	public override void ResetSwitchTo(bool on)
	{
		Switch(on);
		transitioning = false;
		if (on)
		{
			transform.localScale = initialScale;
			t = 1;
			Renderer.enabled = true;
			Open = true;
		}
		else
		{
			transform.localScale = Vector3.one * 0.0001f;
			t = 0;
			Renderer.enabled = false;
		}
	}

	public MonoBehaviour GetMonoBehaviour()
	{
		return this;
	}

	public bool GetCurrentState()
	{
		return on;
	}

	public void SetToState(bool state)
	{
		ResetSwitchTo(state);
	}
}
