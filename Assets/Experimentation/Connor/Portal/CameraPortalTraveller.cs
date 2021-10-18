using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraPortalTraveller : PortalTraveller
{
	public PortalRenderer portalRenderer;
	OldCameraController cameraController;
	//bool justTeleported;

	void Start()
    {
		cameraController = GetComponent<OldCameraController>();
		if (!portalRenderer) portalRenderer = FindObjectOfType<PortalRenderer>();
	}

	public override void MoveToNextPortal(Portal inPortal, Portal outPortal)
	{
		storedPosition = inPortal.TransformPositionToOtherPortal(outPortal, transform.position);
		storedRotation = inPortal.TransformRotationToOtherPortal(outPortal, transform.rotation);
	}

	public override bool RevertMove(Portal inPortal, Portal outPortal)
	{
		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		bool returnValue = oldDot == newDot;
		if (!returnValue)
		{
			portalRenderer.OnCameraThroughPortal();
			//justTeleported = true;
		}
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		return returnValue;
	}

	public override void OnExit(Portal inPortal)
	{
		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		if (newDot != oldDot)
		{
			portalRenderer.OnCameraThroughPortal();
		}
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		//if (justTeleported)
		//{
		//	justTeleported = false;
		//	portalRenderer.firstPortalActive = !portalRenderer.firstPortalActive;
		//}
	}

	public override bool EligableForEarlyMove()
	{
		return false;
	}

}
