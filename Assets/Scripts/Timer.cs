using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Timer : BooleanSwitch
{
	[SerializeField] BooleanSwitch[] bSwitch = null;
	[SerializeField] float time = 5;
	float timer = 0;

	void Switch()
	{
		timer = 0;
		for (int i = 0; i < bSwitch.Length; i++)
		{
			bSwitch[i].Switch(on);
		}
	}

	protected override void Start()
	{
		base.Start();
	}

	public override void Switch(bool on)
	{	
		if (on)
			base.Switch(on);
	}
	public override bool SwitchValue { get => base.SwitchValue; protected set 
		{
			if (value)
			{
				on = value;
				Switch();
			}
		} 
	}

	private void Update()
	{
		if (on) {
			timer += Time.deltaTime;
			if (timer > time)
			{
				timer = 0;
				on = false;
				Switch();
				onSwitchOff.Invoke();
			}
		} 
	}

	public override void ResetSwitchTo(bool on)
	{
		if (on)
		{
			timer = 0;
			this.on = false;
			Switch();
			onSwitchOff.Invoke();
		}
	}
}
