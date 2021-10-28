using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;

[RequireComponent(typeof(GameWindowManager))]
public class GameplayUIManager : MonoBehaviour
{
	public Image crosshair;

	GameWindowManager windowManager;
	InputMaster input;

	private void Awake()
	{
		input = new InputMaster();
		input.UI.Menu.performed += _ => OnMenuButton();

		windowManager = GetComponent<GameWindowManager>();
	}
	public void OnEnable()
	{
		if (input != null)
			input.Enable();
	}
	public void OnDisable()
	{
		if (input != null)
			input.Disable();
	}

	public void EnableCrossHair(bool enable)
	{
		crosshair.enabled = enable;
	}

	void OnMenuButton()
	{
		windowManager.ToggleWindows();
	}
}
