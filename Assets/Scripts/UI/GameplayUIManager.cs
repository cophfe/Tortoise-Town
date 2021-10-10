using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameplayUIManager : MonoBehaviour
{
	public Image healthBar;

	void SetHealthBar(float t)
	{
		healthBar.fillAmount = t;
	}
}
