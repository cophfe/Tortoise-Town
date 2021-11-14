using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Activator : MonoBehaviour
{
	[SerializeField] protected BooleanSwitch[] bSwitch;
	[SerializeField]  protected bool activateOnce = false;
	[SerializeField] UnityEvent onActivate = null;
	[SerializeField] UnityEvent onDeactivate = null;
	protected bool activated = false;
	public virtual void Switch()
	{
		activated = !activated;
		if (!(activateOnce && !activated))
		{
			if (activated)
				onActivate.Invoke();
			else
				onDeactivate.Invoke();
			
			for (int i = 0; i < bSwitch.Length; i++)
			{
				bSwitch[i].Switch(activated);
			}
		}
	}

	public virtual void TurnAllOff()
	{
		activated = false;
		onDeactivate.Invoke();
		for (int i = 0; i < bSwitch.Length; i++)
		{
			bSwitch[i].Switch(false);
		}
	}

	public virtual void TurnAllOn()
	{
		activated = true;
		onActivate.Invoke();
		for (int i = 0; i < bSwitch.Length; i++)
		{
			bSwitch[i].Switch(true);
		}
	}
}
