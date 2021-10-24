using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameplayUIManager : MonoBehaviour
{
	public Image healthBar;
	public Image crosshair;

	public void SetHealthBar(float t)
	{
		healthBar.fillAmount = t;
	}

	public void EnableCrossHair(bool enable)
	{
		crosshair.enabled = enable;
	}
}
