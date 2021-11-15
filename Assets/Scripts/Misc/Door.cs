using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Door : BooleanSwitch
{
	public Animator doorAnimator;
    
	protected override void Start()
    {
		if (!doorAnimator)
			doorAnimator = GetComponentInChildren<Animator>();
		base.Start();
	}

	public override void ResetSwitchTo(bool on)
	{
		Switch(on);
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
