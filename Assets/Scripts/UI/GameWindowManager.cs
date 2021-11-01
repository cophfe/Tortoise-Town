using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameWindowManager : MonoBehaviour
{
	[SerializeField] GameWindow[] gameWindows = null;
	[SerializeField] GameWindow backgroundPanel = null;
	[SerializeField] float windowOpenTime = 1;
	float openTimer = 0;
	int activeWindowIndex = -1;
	bool transitioning = false;

	void Start()
	{
		for (int i = 0; i < gameWindows.Length; i++)
		{
			gameWindows[i].gameObject.SetActive(false);
		}
		backgroundPanel.gameObject.SetActive(false);
	}

	private void Update()
	{
		if (transitioning)
		{
			openTimer += Time.unscaledDeltaTime;
			float t = Ease.EaseOutQuad(openTimer / windowOpenTime);
			if (openTimer >= windowOpenTime)
			{
				t = 1;
				transitioning = false;
				OnEndTransition();
			}
			for (int i = 0; i < gameWindows.Length; i++)
			{
				gameWindows[i].UpdateOpenState(t);
				backgroundPanel.UpdateOpenState(t);
			}
		}
		
	}

	public void SetCurrentWindow(string windowName)
	{
		if (transitioning) return;
		bool success = false;
		for (int i = 0; i < gameWindows.Length; i++)
		{
			if (gameWindows[i].gameObject.name == windowName)
			{
				if (i == activeWindowIndex || !gameWindows[i].OpenWindow(true)) return;
				if (activeWindowIndex == -1)
					backgroundPanel.OpenWindow(true);
				activeWindowIndex = i;
				for (int j = 0; j < gameWindows.Length; j++)
				{
					if (j == i) continue;
					gameWindows[j].OpenWindow(false);
				}
				success = true;
				transitioning = true;
				OnStartTransition();
				openTimer = 0;
				return;
			}
		}

		//if could not find window, close
		if (!success)
		{
			CloseActiveWindows();
		}

		
	}

	public GameWindow GetCurrentWindow() { if (activeWindowIndex < 0) return null;
		else return gameWindows[activeWindowIndex]; }

	public void CloseActiveWindows()
	{
		backgroundPanel.OpenWindow(false);
		bool anyWindowsWereOpen = false;
		for (int j = 0; j < gameWindows.Length; j++)
		{
			anyWindowsWereOpen |= gameWindows[j].OpenWindow(false);
		}
		activeWindowIndex = -1;

		if (anyWindowsWereOpen)
		{
			OnStartTransition();
			transitioning = true;
			openTimer = 0;
		}
	}

	public void ToggleWindows()
	{
		var current = GetCurrentWindow();
		if (current == null || current.name == "Options")
		{
			GameManager.Instance.IsCursorRestricted = false;
			Time.timeScale = 0;
			GameManager.Instance.Player.InputIsEnabled = false;
			SetCurrentWindow("Pause");
		}
		else if (current.name == "Pause")
		{
			CloseActiveWindows();
		}
	}

	void OnStartTransition()
	{
	}

	void OnEndTransition()
	{
		var current = GetCurrentWindow();
		if (current == null)
		{
			GameManager.Instance.IsCursorRestricted = true;
			GameManager.Instance.Player.InputIsEnabled = true;
			Time.timeScale = 1;
		}
	}
}
