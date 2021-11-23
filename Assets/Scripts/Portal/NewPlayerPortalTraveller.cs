using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewPlayerPortalTraveller : NewPortalTraveller
{
	PlayerController controller;
	NewPortalRenderer portalRenderer;

	private void Start()
	{
		controller = GameManager.Instance.Player;
		portalRenderer = FindObjectOfType<NewPortalRenderer>();
	}
	public override void UpdateTeleport()
	{
		//if on other side of portal from where it was entered
		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		if (enterDotIsPositive != newDot)
		{
			//teleport to other side
			transform.position = inPortal.TransformPositionToOtherPortal(transform.position);
			controller.RotateChild.rotation = inPortal.TransformRotationToOtherPortal(controller.RotateChild.rotation);

			portalRenderer.OnPlayerThroughPortal(inPortal);
			controller.Interpolator.ResetPosition();
			controller.MainCamera.SetPositionAndRotation(portalRenderer.transform.position, portalRenderer.transform.rotation);
			controller.Motor.InputVelocity = inPortal.TransformDirectionToOtherPortal(controller.Motor.InputVelocity);
			controller.Motor.ForcesVelocity = inPortal.TransformDirectionToOtherPortal(controller.Motor.ForcesVelocity);
			if (controller.Motor.IsDashing)
				controller.Motor.DashDirection = inPortal.TransformDirectionToOtherPortal(controller.Motor.DashDirection);

			inPortal.GetTravellers().Remove(this);
			if (!outPortal.GetTravellers().Contains(this))
				outPortal.GetTravellers().Add(this);
			OnEnter(outPortal, inPortal);
		}
	}
}
