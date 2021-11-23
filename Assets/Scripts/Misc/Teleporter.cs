using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Teleporter : BooleanSwitch, IBooleanSaveable
{
	MeshRenderer meshRenderer;
	public bool onlyVisual = false;
	public Teleporter otherEnd = null;
	Vector3 initialScale;
	float openSpeed = 14;
	public bool enableOnWin = false;
	Spherize spherizer;
	bool transitioning = false;
	float t = 0;

	public override void ResetSwitchTo(bool on)
	{
		Switch(on);
		transitioning = false;
		if (on)
		{
			transform.localScale = initialScale;
			t = 1;
			meshRenderer.enabled = true;
		}
		else
		{
			transform.localScale = Vector3.one * 0.0001f;
			t = 0;
			meshRenderer.enabled = false;
		}
	}

	private void OnTriggerEnter(Collider other)
	{
		if (on && !onlyVisual && other.CompareTag("Player"))
		{
			if (GameManager.Instance.IsTutorial)
			{
				GameManager.Instance.GUI.WindowManager.AddToQueue(GameManager.Instance.GUI.winMenu);
				if (!Application.isEditor)
					PlayerPrefs.SetInt("TutorialCompleted", 1);
			}
			else
			{
				var controller = other.GetComponent<PlayerController>();
				var camera = controller.MainCamera;

				controller.RotateChild.rotation = TransformRotationRelative(transform, otherEnd.transform, controller.RotateChild.rotation);
				controller.transform.position = TransformPositionRelative(transform, otherEnd.transform, controller.transform.position);

				controller.Interpolator.ResetPosition();
				camera.SetPositionAndRotation(TransformPositionRelative(transform, otherEnd.transform, camera.transform.position), TransformRotationRelative(transform, otherEnd.transform, camera.transform.rotation));

				Switch(false);
			}
			
		}
	}

	private void Awake()
	{
		spherizer = GetComponent<Spherize>();
		initialScale = transform.localScale;
		meshRenderer = GetComponent<MeshRenderer>();
		if (enableOnWin)
		{
			GameManager.Instance.SaveManager.RegisterSaveable(this);
			GameManager.Instance.RegisterWinSwitch(this);
		}
		InitialSaveState = SwitchOnAwake;
	}

	protected override void Start()
	{
		base.Start();
		if (!on)
		{
			meshRenderer.enabled = false;
			t = 0;
		}
		else
		{
			t = 1;
		}
	}

	public override bool SwitchValue { get => base.SwitchValue; protected set
		{
			if (on != value)
			{
				transitioning = true;
				if (value)
				{
					meshRenderer.enabled = true;
				}
				if (!onlyVisual && otherEnd)
				{
					otherEnd.Switch(value);
				}
			}

			on = value;
		}
	}

	public bool InitialSaveState { get; private set; }

	private void Update()
	{
		if (transitioning)
		{
			if (on)
			{
				t += Time.deltaTime;

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
					meshRenderer.enabled = false;
					transitioning = false;
				}

			}

			if (spherizer)
				spherizer.PercentSpherized = 1 - Ease.EaseOutQuad(t);
			transform.localScale = GetScale(t);
		}
	}

	Vector3 GetScale(float t)
	{
		Vector3 scale = initialScale;
		if (t < 0.001f)
			t = 0.001f;

		scale.y *= Ease.EaseOutQuad(t);
		scale.x *= Ease.EaseInQuad(t);
		scale.z *= t;
		return scale;
	}

	public Vector3 TransformPositionRelative(Transform first, Transform second, Vector3 position)
	{
		//get position relative to this portal
		Vector3 inPosition = first.InverseTransformPoint(position);
		//flip to opposite side
		inPosition = Quaternion.Euler(0, 180, 0) * inPosition;
		//set final positions relative to the other portal
		Vector3 outPosition = second.TransformPoint(inPosition);
		return outPosition;
	}

	public Quaternion TransformRotationRelative(Transform first, Transform second, Quaternion rotation)
	{
		//get position relative to this portal
		Quaternion inRotation = Quaternion.Inverse(first.rotation) * rotation;
		//flip to opposite side
		inRotation = Quaternion.Euler(0, 180, 0) * inRotation;
		//set final positions relative to the out portal
		Quaternion outRotation = second.transform.rotation * inRotation;
		return outRotation;
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
