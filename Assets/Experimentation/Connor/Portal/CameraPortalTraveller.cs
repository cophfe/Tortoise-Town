using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraPortalTraveller : PortalTraveller
{
	public PortalRenderer portalRenderer;
	CameraController cameraController;
	//bool justTeleported;
	[System.NonSerialized]
	public bool tempMovedThisTime = false;

	void Start()
    {
		cameraController = GetComponent<CameraController>();
		if (!portalRenderer) portalRenderer = FindObjectOfType<PortalRenderer>();
	}

	public override void MoveToNextPortal(Portal inPortal, Portal outPortal)
	{
		storedPosition = inPortal.TransformPositionToOtherPortal(outPortal, transform.position);
		storedRotation = inPortal.TransformRotationToOtherPortal(outPortal, transform.rotation);
		tempMovedThisTime = true;
	}

	public override bool RevertMove(Portal inPortal, Portal outPortal)
	{
		return true;
	}

	public bool CheckIfWillCompleteTeleport(Portal inPortal)
	{
		if (!tempMovedThisTime) return false;

		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		return oldDot != newDot;

	}

	public override void OnEnter(Portal inPortal)
	{
		portalRenderer.OnCameraThroughPortal();
	}
	public override void OnExit(Portal inPortal)
	{
		portalRenderer.OnCameraThroughPortal();
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
	}

	public override bool EligableForEarlyMove()
	{
		return false;
	}

}
