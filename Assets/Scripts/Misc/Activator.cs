using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Activator : MonoBehaviour
{
	[SerializeField] protected BooleanSwitch[] bSwitch;
	[SerializeField]  protected bool activateOnce = false;
	protected bool activated = false;
	public virtual void Switch()
	{
		activated = !activated;
		if (!(activateOnce && activated))
		{
			for (int i = 0; i < bSwitch.Length; i++)
			{
				bSwitch[i].Switch(activated);
			}
		}
	}

	public virtual void TurnAllOff()
	{
		activated = false;
		for (int i = 0; i < bSwitch.Length; i++)
		{
			bSwitch[i].Switch(false);
		}
	}

	public virtual void TurnAllOn()
	{
		activated = true;
		for (int i = 0; i < bSwitch.Length; i++)
		{
			bSwitch[i].Switch(true);
		}
	}
}
