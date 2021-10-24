using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Activator : MonoBehaviour
{
	[SerializeField] protected BooleanSwitch bSwitch;
	[SerializeField]  protected bool activateOnce = false;
	protected virtual void Activate()
	{
		if (!(activateOnce && bSwitch.SwitchValue))
			bSwitch.Switch(!bSwitch.SwitchValue);
	}


}
