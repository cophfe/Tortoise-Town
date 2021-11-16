using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;

public class TabController : MonoBehaviour
{
	public TabStructure[] tabs;

	private void Start()
	{
		for (int i = 0; i < tabs.Length; i++)
		{
			int j = i;
			tabs[i].tabButton.onClick.AddListener(() => SetActive(j));
		}
	}

	void SetActive(int index)
	{
		for (int i = 0; i < tabs.Length; i++)
		{
			if (tabs[i].tab)
				tabs[i].tab.SetActive(i == index);
		}
	}

	private void OnDisable()
	{
		if (tabs.Length > 0)
			SetActive(0);
	}

	[System.Serializable]
	public struct TabStructure
	{
		public Button tabButton;
		public GameObject tab;
	}
}
