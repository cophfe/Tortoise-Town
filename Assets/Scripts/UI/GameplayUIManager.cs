using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameplayUIManager : MonoBehaviour
{
	public Image crosshair;

	public void EnableCrossHair(bool enable)
	{
		crosshair.enabled = enable;
	}
}
