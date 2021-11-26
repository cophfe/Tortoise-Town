using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

[RequireComponent(typeof(Selectable))]
public class SelectSelectable : MonoBehaviour
{
	Selectable button;

	private void Awake()
	{
		button = GetComponent<Selectable>();
	}

	private void OnEnable()
	{
		button.Select();
	}


}
