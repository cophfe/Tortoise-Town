using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameWindowManager : MonoBehaviour
{
	[SerializeField] GameWindow[] gameWindows;
	[SerializeField] Image backgroundPanel;

	[SerializeField] float windowOpenTime = 1;
	float openTimer = 0;
	int activeWindowIndex = -1;
	bool transitioning = false;

	void Start()
	{

	}

	private void Update()
	{
		if (transitioning)
		{
			openTimer += Time.deltaTime;
			float t = Ease.EaseOutQuad(openTimer / windowOpenTime);

			for (int i = 0; i < gameWindows.Length; i++)
			{
				gameWindows[i].UpdateOpenState(t);
			}
			if (t >= 1)
			{
				transitioning = false;
			}
		}
		
	}

	public void SetCurrentWindow(string windowName)
	{
		bool success = false;
		for (int i = 0; i < gameWindows.Length; i++)
		{
			if (gameWindows[i].gameObject.name == windowName)
			{
				if (i == activeWindowIndex) return;

				gameWindows[i].OpenWindow(true);
				activeWindowIndex = i;
				for (int j = 0; j < gameWindows.Length; j++)
				{
					if (j == i) continue;
					gameWindows[j].OpenWindow(false);
				}
				success = true;
				break;
			}
		}

		//if could not find window, close
		if (!success)
		{
			for (int j = 0; j < gameWindows.Length; j++)
			{
				gameWindows[j].OpenWindow(false);
			}
			activeWindowIndex = -1;
		}

		openTimer = 0;
	}

	public void CloseActiveWindows()
	{
		bool anyWindowsWereOpen = false;
		for (int j = 0; j < gameWindows.Length; j++)
		{
			anyWindowsWereOpen |= gameWindows[j].OpenWindow(false);
		}
		activeWindowIndex = -1;

		if (anyWindowsWereOpen)
			openTimer = 0;
	}
}
