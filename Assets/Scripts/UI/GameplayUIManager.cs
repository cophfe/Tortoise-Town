using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameplayUIManager : MonoBehaviour
{
	public Image healthBar;
	public GameObject crosshair;

	public void SetHealthBar(float t)
	{
		healthBar.fillAmount = t;
	}

	public void EnableCrossHair(bool enable)
	{
		crosshair.SetActive(enable);
	}
}
