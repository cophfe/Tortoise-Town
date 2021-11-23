using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NewPortal : BooleanSwitch
{
	public bool open = false;
	public Renderer Renderer { get; private set; }
	List<NewPortalTraveller> travelling;
	new BoxCollider collider;
	Transform renderBox;

	public NewPortal OtherPortal { get; set; }
	void Awake()
	{
		Renderer = GetComponentInChildren<Renderer>();
		travelling = new List<NewPortalTraveller>();
		collider = GetComponent<BoxCollider>();
	}

	private void OnTriggerEnter(Collider other)
	{
		var traveller = other.GetComponent<NewPortalTraveller>();

		if (traveller && !travelling.Contains(traveller))
		{
			traveller.OnEnter(this, OtherPortal);
			travelling.Add(traveller);
		}
	}
	private void OnTriggerExit(Collider other)
	{
		var traveller = other.GetComponent<NewPortalTraveller>();
		if (traveller)
		{
			travelling.Remove(traveller);
		}
	}

	public List<NewPortalTraveller> GetTravellers()
	{
		return travelling;
	}

	public void TempTravelStart()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].MoveToNextPortal();
		}
	}

	public void TempTravelEnd()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].RevertMove();
		}
	}

	public void TeleportTravellers()
	{
		for (int i = 0; i < travelling.Count; i++)
		{
			travelling[i].UpdateTeleport();
		}
	}
	public Vector3 TransformPositionToOtherPortal(Vector3 position)
	{
		//get position relative to this portal
		Vector3 inPosition = transform.InverseTransformPoint(position);
		//flip to opposite side
		inPosition = Quaternion.Euler(0, 180, 0) * inPosition;
		//set final positions relative to the other portal
		Vector3 outPosition = OtherPortal.transform.TransformPoint(inPosition);
		return outPosition;
	}

	public Quaternion TransformRotationToOtherPortal( Quaternion rotation)
	{
		//get position relative to this portal
		Quaternion inRotation = Quaternion.Inverse(transform.rotation) * rotation;
		//flip to opposite side
		inRotation = Quaternion.Euler(0, 180, 0) * inRotation;
		//set final positions relative to the out portal
		Quaternion outRotation = OtherPortal.transform.rotation * inRotation;
		return outRotation;
	}

	public Vector3 TransformDirectionToOtherPortal(Vector3 direction)
	{
		//get position relative to this portal
		Vector3 inDirection = transform.InverseTransformDirection(direction);
		//flip to opposite side
		inDirection = Quaternion.Euler(0, 180, 0) * inDirection;
		//set final positions relative to the other portal
		Vector3 outDirection = OtherPortal.transform.TransformDirection(inDirection);
		return outDirection;
	}

	public bool CheckPointInBounds(Vector3 point)
	{
		return point == collider.ClosestPoint(point);
	}

	public bool CheckPointInBounds2D(Vector3 point)
	{
		point = collider.transform.InverseTransformPoint(point);

		return point.x > collider.center.x - collider.size.x / 2 && point.x < collider.center.x + collider.size.x / 2
			&& point.y > collider.center.y - collider.size.y / 2 && point.y < collider.center.y + collider.size.y / 2;
	}

	public Transform GetRenderBox()
	{
		return Renderer.transform;
	}

	public override void ResetSwitchTo(bool on)
	{
		Switch(on);
	}
}
