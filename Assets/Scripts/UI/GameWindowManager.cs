using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameWindowManager : MonoBehaviour
{
	Stack<GameWindow> activeWindows;
	public GameWindow backgroundPanel;

	[SerializeField] float windowOpenTime = 1;
	float openTimer = 0;
	bool transitioning = false;

	void Start()
	{
		activeWindows = new Stack<GameWindow>();
	}

	public GameWindow GetCurrentWindow() { return activeWindows.Count == 0 ? null : activeWindows.Peek(); }

	private void Update()
	{
		//if (transitioning)
		//{
		//	openTimer += Time.unscaledDeltaTime;
		//	float t = Ease.EaseOutQuad(openTimer / windowOpenTime);
		//	if (openTimer >= windowOpenTime)
		//	{
		//		t = 1;
		//		transitioning = false;
		//		OnEndTransition();
		//	}
		//	for (int i = 0; i < gameWindows.Length; i++)
		//	{
		//		gameWindows[i].UpdateOpenState(t);
		//	}
		//	backgroundPanel.UpdateOpenState(t);
		//}
		if (transitioning)
		{
			openTimer += Time.unscaledDeltaTime;
			float t = Ease.EaseOutQuad(openTimer / windowOpenTime);
			if (openTimer >= windowOpenTime)
			{
				transitioning = false;
				var current = GetCurrentWindow();
				if (current != null)
				{
					current.UpdateOpenState(1);
					if (current.GetState() == GameWindow.TransitionState.CLOSED)
					{
						activeWindows.Pop();
						if (GetCurrentWindow() == null)
						{
							GameManager.Instance.IsCursorRestricted = true;
							GameManager.Instance.Player.InputIsEnabled = true;
							Time.timeScale = 1;
						}
					}
				}
				
				if (backgroundPanel)
					backgroundPanel.UpdateOpenState(1);
			}
			else
			{
				var current = GetCurrentWindow();
				if (current != null)
					current.UpdateOpenState(t);
				if (backgroundPanel)
					backgroundPanel.UpdateOpenState(t);
			}
		}
	}

	public void AddToQueue(GameWindow window)
	{
		if (window == null || activeWindows.Contains(window)) return;

		if (activeWindows.Count == 0)
		{
			GameManager.Instance.IsCursorRestricted = false;
			GameManager.Instance.Player.InputIsEnabled = false;
			Time.timeScale = 0;
			if (backgroundPanel)
				backgroundPanel.OpenWindow(true);
		}

		//if last thing not finished, force it to finish
		var current = GetCurrentWindow();
		if (current != null && (current.GetState() == GameWindow.TransitionState.CLOSING || current.GetState() == GameWindow.TransitionState.OPENING))
		{
			current.UpdateOpenState(1);
			if (current.GetState() == GameWindow.TransitionState.CLOSED)
				activeWindows.Pop();
		}

		activeWindows.Push(window);
		window.OpenWindow(true);
		transitioning = true;
		openTimer = 0;
	}

	public void RemoveFromQueue()
	{
		var current = GetCurrentWindow();
		if (current != null && current.GetState() != GameWindow.TransitionState.CLOSING)
		{
			current.OpenWindow(false);
			transitioning = true;
			openTimer = 0;

			if (backgroundPanel && activeWindows.Count == 1)
			{
				backgroundPanel.OpenWindow(false);
			}
		}
	}

	public void InstantCloseAll()
	{
		var current = GetCurrentWindow();
		while (current != null)
		{
			activeWindows.Peek().OpenWindow(false);
			activeWindows.Peek().UpdateOpenState(1);
			activeWindows.Pop();
			current = GetCurrentWindow();
		}
		if (backgroundPanel)
		{
			backgroundPanel.OpenWindow(false);
			backgroundPanel.UpdateOpenState(1);
		}
		GameManager.Instance.IsCursorRestricted = true;
		GameManager.Instance.Player.InputIsEnabled = true;
		Time.timeScale = 1;
	}
}
