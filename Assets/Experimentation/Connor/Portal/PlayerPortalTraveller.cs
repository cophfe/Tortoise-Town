using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerPortalTraveller : PortalTraveller
{
	PlayerController controller;
	public PortalRenderer portalRenderer;

	private void Start()
	{
		if (!portalRenderer)
			portalRenderer = FindObjectOfType<PortalRenderer>();
		controller = GetComponent<PlayerController>();
	}

	public override bool RevertMove(Portal inPortal, Portal outPortal)
	{
		bool newDot = Vector3.Dot(storedPosition - inPortal.transform.position, inPortal.transform.forward) > 0;
		bool returnValue = oldDot == newDot;
		if (returnValue)
		{
			Vector3 pos = transform.position;
			Quaternion rot = transform.rotation;
			transform.position = storedPosition;
			transform.rotation = storedRotation;
			storedPosition = pos;
			storedRotation = rot;
		}
		else
		{
			controller.MainCamera.SetPositionAndRotation(portalRenderer.transform.position, portalRenderer.transform.rotation);
			portalRenderer.OnPlayerThroughPortal();
		}
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		return returnValue;
	}

	public override void OnEnter(Portal inPortal)
	{
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
	}

	public override void OnExit(Portal inPortal)
	{
		return;
		//bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		//if (newDot != oldDot)
		//{
		//	controller.Interpolator.ResetPosition();
		//	controller.MainCamera.SetPositionAndRotation(portalRenderer.transform.position, portalRenderer.transform.rotation);
		//	portalRenderer.OnPlayerThroughPortal();
		//}
		//oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
	}
}
