using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class KeyBindingNavigator : MonoBehaviour
{
	public Scrollbar scrollbar;
	public GameObject contentHolder;
	public Button backButton;
	public Button defaultButton;

	Selectable firstKeybind = null;
	Selectable lastKeybind = null;
	public void SetNavigationForKeybind(Selectable keyBind)
	{
		if (firstKeybind == null)
		{
			firstKeybind = keyBind;
			firstKeybind.gameObject.AddComponent<SelectSelectable>();
		}	
		var nav = keyBind.navigation;
		nav.selectOnUp = lastKeybind;
		nav.selectOnDown = defaultButton;
		keyBind.navigation = nav;

		if (lastKeybind != null)
		{
			nav = lastKeybind.navigation;
			nav.selectOnDown = keyBind;
			lastKeybind.navigation = nav;
		}

		nav = defaultButton.navigation;
		nav.selectOnUp = keyBind;
		defaultButton.navigation = nav;
		nav = backButton.navigation;
		nav.selectOnUp = keyBind;
		backButton.navigation = nav;

		lastKeybind = keyBind;
	}
}
