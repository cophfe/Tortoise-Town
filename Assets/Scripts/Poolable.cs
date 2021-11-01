using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Poolable : MonoBehaviour
{
	[HideInInspector] public bool ignoredInPool = false;

	//pool objects are notified if they are soon to be pooled so they can do something like a fade animation
    public virtual bool BeforeReset()
	{
		return !ignoredInPool;
	}

	public virtual void OnReset()
	{

	}

}
