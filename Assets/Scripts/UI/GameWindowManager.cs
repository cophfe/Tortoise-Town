using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameWindowManager : MonoBehaviour
{
	WindowStack activeWindows;
	public GameWindow backgroundPanel;
	[SerializeField] float windowOpenTime = 1;
	float openTimer = 0;
	int activeWindowIndex = -1;
	bool transitioning = false;

	void Start()
	{
		activeWindows = new WindowStack();
	}

	public GameWindow GetCurrentWindow() { return activeWindows.Peek(); }

	private void Update()
	{
		//if transitioning (removing or adding window to stack)
		if (transitioning)
		{
			//transition timer
			openTimer += Time.unscaledDeltaTime;
			float t = Ease.EaseOutQuad(openTimer / windowOpenTime);
			
			//if halfway through 
			if (openTimer >= windowOpenTime * 0.5f)
			{
				//move the background panel to behind the new gamewindow
				var current = GetCurrentWindow();
				if (current && current.GetState() == GameWindow.TransitionState.OPENING)
					backgroundPanel.transform.SetSiblingIndex(current.transform.GetSiblingIndex() - 1);
			}
			//if finished transitioning
			if (openTimer >= windowOpenTime)
			{
				t = 1;
				transitioning = false;
				var current = GetCurrentWindow();
				if (current != null)
				{
					current.UpdateOpenState(1);
					
					//if window just closed pop window from stack
					if (current.GetState() == GameWindow.TransitionState.CLOSED)
					{
						activeWindows.Pop();
						current = GetCurrentWindow();
						if (current == null)
						{
							GameManager.Instance.IsCursorRestricted = true;
							GameManager.Instance.Player.InputIsEnabled = true;
							Time.timeScale = 1;
						}
						else
						{
							current.SetInteractive(true);
						}
					}
				}

				if (backgroundPanel)
					backgroundPanel.UpdateOpenState(1);
			}
			for (int i = 0; i < gameWindows.Length; i++)
			{
				//transition window
				var current = GetCurrentWindow();
				if (current != null)
					current.UpdateOpenState(t);

				//transition background panel
				if (backgroundPanel)
					backgroundPanel.UpdateOpenState(t);
			}
			backgroundPanel.UpdateOpenState(t);
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
		else
		{
			var current = GetCurrentWindow();
			//if last thing not finished, force it to finish
			if (current.GetState() == GameWindow.TransitionState.CLOSING || current.GetState() == GameWindow.TransitionState.OPENING)
			{
				current.UpdateOpenState(1);
				if (current.GetState() == GameWindow.TransitionState.CLOSED)
					activeWindows.Pop();
			}
			else
			{
				current.SetInteractive(false);
			}
		}

		//add window to stack and initiate transition to it
		activeWindows.Push(window);
		window.OpenWindow(true);
		transitioning = true;
		openTimer = 0;
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

			if (backgroundPanel && activeWindows.Count == 1)
			{
				backgroundPanel.OpenWindow(false);
			}
			else if (activeWindows.Count > 1)
			{
				var secondLastWindow = activeWindows.BreakStackLogicInOrderToGetUnderlyingList()[activeWindows.Count - 2];
				backgroundPanel.transform.SetSiblingIndex(secondLastWindow.transform.GetSiblingIndex() - 1);
			}

		}
		else if (current.name == "Pause")
		{
			CloseActiveWindows();
		}
	}

	public void InstantCloseAll()
	{
		backgroundPanel.OpenWindow(false);
		bool anyWindowsWereOpen = false;
		for (int j = 0; j < gameWindows.Length; j++)
		{
			anyWindowsWereOpen |= gameWindows[j].OpenWindow(false);
		}
		activeWindowIndex = -1;

		OnStartTransition();
		transitioning = true;
		openTimer = windowOpenTime;
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

	class WindowStack
	{
		List<GameWindow> windows;

		public WindowStack()
		{
			windows = new List<GameWindow>();
		}

		public GameWindow Pop()
		{
			if (windows.Count == 0) return null;
			var gW = windows[windows.Count - 1];
			windows.RemoveAt(windows.Count - 1);
			return gW;
		}

		public GameWindow Peek()
		{
			if (windows.Count == 0) return null;
			else
				return windows[windows.Count - 1];
		}

		public void Push(GameWindow window)
		{
			windows.Add(window);
		}

		public List<GameWindow> BreakStackLogicInOrderToGetUnderlyingList()
		{
			return windows;
		}

		public bool Contains(GameWindow window)
		{
			return windows.Contains(window);
		}

		public int Count { get { return windows.Count; } }
	}
}
