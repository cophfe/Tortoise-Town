using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Door : BooleanSwitch
{
	public Animator doorAnimator;

    void Start()
    {
		if (!doorAnimator)
			doorAnimator = GetComponentInChildren<Animator>();
    }

	public override bool SwitchValue 
	{
		get { return on; } 
		protected set 
		{
			on = value;
			doorAnimator.SetBool("Open", on);
		} 
	}
}
