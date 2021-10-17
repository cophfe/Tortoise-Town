using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Portal : MonoBehaviour
{
	public bool open = false;
	public Renderer Renderer {get; private set;}
	List<PortalTraveller> travelling;
	List<PortalTraveller> justTravelled;
	new BoxCollider collider;
	Transform renderBox;

	void Awake()
    {
		Renderer = GetComponentInChildren<Renderer>();
		travelling = new List<PortalTraveller>();
		justTravelled = new List<PortalTraveller>();
		collider = GetComponent<BoxCollider>();
	}

	private void OnTriggerEnter(Collider other)
	{
		var traveller = other.GetComponent<PortalTraveller>();

		if (traveller)
		{
			traveller.OnEnter(this);
			if (!travelling.Contains(traveller)) travelling.Add(traveller);
		}
	}
	private void OnTriggerExit(Collider other)
	{
		var traveller = other.GetComponent<PortalTraveller>();
		if (traveller)
		{
			traveller.OnExit(this);
			travelling.Remove(traveller);
		}
	}

	public List<PortalTraveller> GetTravellers()
	{
		return travelling;
	}

	public void TravelTravellers(Portal other)
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].MoveToNextPortal(this, other);
		}
	}

	public void UndoTravel(Portal other)
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			if (!travelling[i].RevertMove(this, other))
			{
				if (travelling[i].EligableForEarlyMove())
				{
					other.GetTravellers().Add(travelling[i]);
					travelling[i].OnEnter(other);
				}
				travelling.Remove(travelling[i]);
				i -= 1;
			}
		}
	}

	public void TravelJustTravellers(Portal other)
	{
		
	}

	public void RevertJustTravelled(Portal other)
	{
		for (int i = 0; i < justTravelled.Count; i++)
		{
			//justTravelled[i].EnforceUnRevert();
		}
		justTravelled.Clear();

	}

	public Vector3 TransformPositionToOtherPortal(Portal other, Vector3 position)
	{
		//get position relative to this portal
		Vector3 inPosition = transform.InverseTransformPoint(position);
		//flip to opposite side
		inPosition = Quaternion.Euler(0, 180, 0) * inPosition;
		//set final positions relative to the other portal
		Vector3 outPosition = other.transform.TransformPoint(inPosition);
		return outPosition;
	}

	public Quaternion TransformRotationToOtherPortal(Portal other, Quaternion rotation)
	{
		//get position relative to this portal
		Quaternion inRotation = Quaternion.Inverse(transform.rotation) * rotation;
		//flip to opposite side
		inRotation = Quaternion.Euler(0, 180, 0) * inRotation;
		//set final positions relative to the out portal
		Quaternion outRotation = other.transform.rotation * inRotation;
		return outRotation;
	}

	public bool CheckPointInBounds(Vector3 point)
	{
		return point == collider.ClosestPoint(point);
	}

	public Transform GetRenderBox()
	{
		return Renderer.transform;
	}
}
