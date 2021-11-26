using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class TabController : MonoBehaviour
{
	public TabStructure[] tabs;
	public Button[] rightButtonPanelButtons;
	int currentTab = 0;
	private void Start()
	{
		for (int i = 0; i < tabs.Length; i++)
		{
			int j = i;
			tabs[i].tabButton.onClick.AddListener(() => SetCurrentTab(j));
		}
	}

	void SetCurrentTab(int index)
	{
		currentTab = index;
		for (int i = 0; i < tabs.Length; i++)
		{
			if (tabs[i].tab && tabs[i].tabButton)
			{
				tabs[i].tab.SetActive(i == index);
				tabs[i].tabButton.interactable = i != index;

				var nav = tabs[i].tabButton.navigation;
				nav.selectOnDown = tabs[index].topSelectableOnTab;
				tabs[i].tabButton.navigation = nav;
			}

			
			
		}

		if (rightButtonPanelButtons != null)
		{
			foreach (var button in rightButtonPanelButtons)
			{
				var nav = button.navigation;
				nav.selectOnLeft = tabs[index].topSelectableOnTab;
				button.navigation = nav;
			}
		}
	}

	public void ChangeTabs(float value)
	{
		if (value > 0)
		{
			SetCurrentTab((currentTab + 1) % tabs.Length);
		}
		else if (value < 0)
		{
			SetCurrentTab((currentTab - 1) < 0 ? tabs.Length - 1 : currentTab - 1);
		}
	}
	private void OnEnable()
	{
		if (tabs.Length > 0)
			SetCurrentTab(0);
	}

	[System.Serializable]
	public struct TabStructure
	{
		public Button tabButton;
		public GameObject tab;
		public Selectable topSelectableOnTab;
	}
}
