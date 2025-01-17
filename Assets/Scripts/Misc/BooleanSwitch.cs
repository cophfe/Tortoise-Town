﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class BooleanSwitch : MonoBehaviour
{
	[SerializeField] bool testSwitch = false;
	[SerializeField] protected bool SwitchOnAwake = false;
	public UnityEvent onSwitchOn;
	public UnityEvent onSwitchOff;
	
	protected bool on;
	public virtual bool SwitchValue { get { return on; } protected set { on = value; } }

	private void OnValidate()
	{
		if (Application.isPlaying && testSwitch)
			Switch(!SwitchValue);
		
		testSwitch = false;
	}
	protected virtual void Start()
	{
		if (SwitchOnAwake) Switch(true);
	}

	public virtual void Switch(bool on)
	{
		if (on == this.on) return;

		if (on)
			onSwitchOn.Invoke();
		else
			onSwitchOff.Invoke();
		SwitchValue = on;
	}

	public virtual void ResetSwitchTo(bool on) { Switch(on); }
	
}