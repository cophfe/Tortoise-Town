using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PortalTraveller : MonoBehaviour
{
	public MonoBehaviour[] componentsToDisable;
	protected Vector3 storedPosition;
	protected Quaternion storedRotation;
	protected bool oldDot;
	protected bool justTravelled;

	public void ActivateComponents(bool activate)
	{
		for (int i = 0; i < componentsToDisable.Length; i++)
		{
			componentsToDisable[i].enabled = activate;
		}
	}

    public virtual void MoveToNextPortal(Portal inPortal, Portal outPortal)
    {
		storedPosition = transform.position;
		storedRotation = transform.rotation;
		transform.position = inPortal.TransformPositionToOtherPortal(outPortal, transform.position);
		transform.rotation = inPortal.TransformRotationToOtherPortal(outPortal, transform.rotation);
    }

	public virtual bool RevertMove(Portal inPortal, Portal outPortal)
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
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		return returnValue;
	}

	public virtual void OnEnter(Portal inPortal)
	{
		oldDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
	}

	public virtual void OnExit (Portal inPortal)
	{
		
	}

	public virtual bool EligableForEarlyMove()
	{
		return true;
	}
}
