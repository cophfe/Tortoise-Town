using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class NewPortalTraveller : MonoBehaviour
{
	public UnityEvent tempTPStart;
	public UnityEvent tempTPEnd;

	protected Vector3 storedPosition;
	protected Quaternion storedRotation;

	protected bool enterDotIsPositive;
	protected NewPortal inPortal, outPortal;
	public virtual void MoveToNextPortal()
	{
		tempTPStart?.Invoke();

		storedPosition = transform.position;
		storedRotation = transform.rotation;
		transform.position = inPortal.TransformPositionToOtherPortal(transform.position);
		transform.rotation = inPortal.TransformRotationToOtherPortal(transform.rotation);
	}

	public virtual void RevertMove()
	{
		tempTPEnd?.Invoke();

		Vector3 pos = transform.position;
		Quaternion rot = transform.rotation;
		transform.position = storedPosition;
		transform.rotation = storedRotation;
		storedPosition = pos;
		storedRotation = rot;
	}

	public virtual void UpdateTeleport()
	{
		//if on other side of portal from where it was entered
		bool newDot = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
		if (enterDotIsPositive != newDot)
		{
			//teleport to other side
			transform.position = inPortal.TransformPositionToOtherPortal(transform.position);
			transform.rotation = inPortal.TransformRotationToOtherPortal(transform.rotation);

			inPortal.GetTravellers().Remove(this);
			if (!outPortal.GetTravellers().Contains(this))
				outPortal.GetTravellers().Add(this);
			OnEnter(outPortal, inPortal);
		}
	}
	public virtual void OnEnter(NewPortal inPortal, NewPortal outPortal)
	{
		this.inPortal = inPortal;
		this.outPortal = outPortal;

		if (inPortal != null && outPortal != null)
		enterDotIsPositive = Vector3.Dot(transform.position - inPortal.transform.position, inPortal.transform.forward) > 0;
	}

	public virtual void OnExit(NewPortal inPortal)
	{

	}
}
