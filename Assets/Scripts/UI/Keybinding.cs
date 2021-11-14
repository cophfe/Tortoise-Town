using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.InputSystem;
using UnityEngine.EventSystems;

public class Keybinding : MonoBehaviour
{
	[SerializeField] TextMeshProUGUI text = null;
	[SerializeField] TextMeshProUGUI bind = null;
	InputAction action = null;
	OptionsMenu menu = null;
	int bindingIndex = 0;
	bool applyImmediate;

	public void SetText(string text)
	{
		this.text.text = text;
	}

	public void SetBind(string bind)
	{
		this.bind.text = bind;
	}

	public void SetAction (InputAction action, int bindingIndex = 0)
	{
		this.action = action;
		this.bindingIndex = bindingIndex;
	}

	public void NewBind()
	{
		if (action != null)
		{
			var rebinder = action.PerformInteractiveRebinding()
				.WithControlsExcluding("Mouse")
				.WithCancelingThrough("<Keyboard>/escape")
				.WithTargetBinding(bindingIndex)
				.OnMatchWaitForAnother(0.1f)
				.OnComplete(OnBind)
				.OnCancel(OnCancelBind);
			if (action.bindings[bindingIndex].isPartOfComposite)
				rebinder.WithExpectedControlType("Button");
			rebinder.Start();
		}
	}

	public void OnBind(InputActionRebindingExtensions.RebindingOperation rebinder)
	{
		rebinder.Dispose();
		SetBind();

		EventSystem.current.SetSelectedGameObject(null);
		menu.SaveKeybinds();
	}

	public void OnCancelBind(InputActionRebindingExtensions.RebindingOperation rebinder)
	{
		EventSystem.current.SetSelectedGameObject(null);
		rebinder.Dispose();
	}

	public void Set(string text, string bind, InputAction action, OptionsMenu menu, int bindingIndex = 0, bool applyImmediately = true)
	{
		SetText(text);
		SetBind(bind);
		SetAction(action, bindingIndex);
		applyImmediate = applyImmediately;
		if (menu)
		{
			this.menu = menu;
		}
	}

	public void SetBind()
	{
		if (action.bindings[bindingIndex].isPartOfComposite)
			SetBind(action.bindings[bindingIndex].ToDisplayString());
		else
			SetBind(action.bindings[bindingIndex].ToDisplayString());
	}
}
