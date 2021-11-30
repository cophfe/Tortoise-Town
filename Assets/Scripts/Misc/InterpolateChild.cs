using System.Collections;
using System.Collections.Generic;
using System.Timers;
using UnityEngine;

//THIS SHOULD INTERPOLATE A CHILD OBJECT OF AN OBJECT THAT UPDATES ON FIXEDUPDATE
[DefaultExecutionOrder(10000)]
public class InterpolateChild : MonoBehaviour
{
	Vector3 start;
	Vector3 end;
	public Transform target = null;
	Vector3 initialLocalPosition;
	float fixedUpdateTime;
	public bool disable = false;

	private void Awake()
	{
		if (target == null || target == transform.parent)
		{
			target = transform.parent;
			initialLocalPosition = transform.localPosition;
		}

		start = target.TransformPoint(initialLocalPosition);
		end = start;
	}

	private void OnEnable()
	{
		start = target.TransformPoint(initialLocalPosition);
		end = start;
		fixedUpdateTime = Time.unscaledTime;
	}

	private void FixedUpdate()
	{
		fixedUpdateTime = Time.unscaledTime;
		start = end;
		end = target.TransformPoint(initialLocalPosition);
	}

	void Update()
	{
		if (disable) return;
		//yes using time.time for precise values surely will not cause any problems whatsoever yes
		float currentTime = Time.unscaledTime;
		float t = (currentTime - fixedUpdateTime) / Mathf.Max(Time.fixedUnscaledDeltaTime, 0.000000001f);
		transform.position = Vector3.Lerp(start, end, t);
	}

	public void ResetPosition()
	{
		start -= end;
		end = target.TransformPoint(initialLocalPosition);
		start += end;
	}

	public void TransformStartAndEndByPortal(NewPortal inPortal)
	{
		start = inPortal.TransformPositionToOtherPortal(start);
		end = inPortal.TransformPositionToOtherPortal(end);
	}

	public Vector3 GetTargetPosition()
	{
		return target.TransformPoint(initialLocalPosition);
	}
}
