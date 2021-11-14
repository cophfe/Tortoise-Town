using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooDamager : PlayerDamager
{
	[SerializeField] bool disableColliderOnDissolve = false;

	public void Dissolve()
	{
		if (disableColliderOnDissolve)
			GetComponent<Collider>().enabled = false;
		enabled = false;
	}

	public void Undissolve()
	{
		if (disableColliderOnDissolve)
			GetComponent<Collider>().enabled = true;
		enabled = true;
	}
}
