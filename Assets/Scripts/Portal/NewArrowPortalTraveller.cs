using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewArrowPortalTraveller : NewPortalTraveller
{
	TrailRenderer tRenderer;
	private void Start()
	{
		tRenderer = GetComponent<TrailRenderer>();
	}
	public override void UpdateTeleport()
	{
		//if on other side of portal from where it was entered
		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		if (enterDotIsPositive != newDot)
		{
			var arrow = GetComponent<Arrow>();
			if (arrow)
			{
				Debug.DrawRay(transform.position, arrow.Velocity, Color.red, 10, false);
				arrow.Velocity = inPortal.TransformDirectionToOtherPortal(arrow.Velocity);
				Debug.DrawRay(transform.position, arrow.Velocity, Color.blue, 10, false);
			}

			//teleport to other side
			transform.position = inPortal.TransformPositionToOtherPortal(transform.position);
			transform.rotation = inPortal.TransformRotationToOtherPortal(transform.rotation);
			tRenderer?.Clear();

			inPortal.GetTravellers().Remove(this);
			if (!outPortal.GetTravellers().Contains(this))
				outPortal.GetTravellers().Add(this);
			OnEnter(outPortal, inPortal);
		}
	}

	bool beforeEmitValue;
	public void SetEmitting(bool val)
	{
		if (tRenderer)
		{
			if (!val)
			{
				beforeEmitValue = tRenderer.emitting;
				tRenderer.emitting = false;
			}
			else
			{
				tRenderer.emitting = beforeEmitValue;
			}
		}
	}
}
