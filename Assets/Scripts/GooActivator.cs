using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooActivator : Activator
{
	public bool activateOnDissolve = true;
	public virtual void Dissolve()
	{
		if (activateOnDissolve)
			TurnAllOn();
		else
			TurnAllOff();
	}

	public virtual void Undissolve()
	{
		if (activateOnDissolve)
			TurnAllOff();
		else
			TurnAllOn();
	}
}
