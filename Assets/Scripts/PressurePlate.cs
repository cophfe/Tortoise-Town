using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class PressurePlate : Activator
{
	[SerializeField] bool switchOnLeave = true;
	[SerializeField] Animator pressurePlateAnimator = null;
	[SerializeField] LayerMask getPressedByLayers = 0;

	int collisionCount = 0;
	int boolId;

	private void Start()
	{
		boolId = Animator.StringToHash("Pressed");
	}

	private void OnTriggerEnter(Collider other)
	{
		if ((getPressedByLayers & (1 << other.gameObject.layer)) != 0)
		{
			collisionCount++;
			if (!activated)
				Switch();
		}
	}

	private void OnTriggerExit(Collider other)
	{
		if ((getPressedByLayers & (1 << other.gameObject.layer)) != 0)
		{
			collisionCount--;
			if (switchOnLeave && collisionCount <= 0)
			{
				collisionCount = 0;
				if (activated)
					Switch();
			}
		}
		
	}

	public override void Switch()
	{
		base.Switch();
		pressurePlateAnimator.SetBool(boolId, activated);
	}

	public override void TurnAllOff()
	{
		base.TurnAllOff();
		pressurePlateAnimator.SetBool(boolId, activated);
		if (collisionCount > 0)
		{
			TurnAllOn();
		}
	}

	public override void TurnAllOn()
	{
		base.TurnAllOn();
		pressurePlateAnimator.SetBool(boolId, activated);
	}
}
