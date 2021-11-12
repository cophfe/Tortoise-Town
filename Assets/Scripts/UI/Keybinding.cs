using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.InputSystem;

public class Keybinding : MonoBehaviour
{
	[SerializeField] TextMeshProUGUI text = null;
	[SerializeField] TextMeshProUGUI bind = null;
	InputAction action;

	public void SetText(string text)
	{
		this.text.text = text;
	}

	public void SetBind(string bind)
	{
		this.bind.text = bind;
	}

	public void SetAction (InputAction action)
	{
		this.action = action;
	}

	public void NewBind()
	{

	}
}
