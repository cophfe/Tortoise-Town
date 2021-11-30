using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class EnableDisableInput : MonoBehaviour
{
	public PlayerInput input;
	private void OnEnable()
	{
		input.enabled = false;
	}

	private void OnDisable()
	{
		input.enabled = true;
	}
}
