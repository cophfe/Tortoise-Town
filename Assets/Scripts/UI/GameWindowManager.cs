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
			var current = GetCurrentWindow();

			//if halfway through 
			if (openTimer >= windowOpenTime * 0.5f && current && current.GetState() == GameWindow.TransitionState.OPENING)
			{
				//move the background panel to behind the new gamewindow
				if (current && current.GetState() == GameWindow.TransitionState.OPENING)
					backgroundPanel.transform.SetSiblingIndex(current.transform.GetSiblingIndex() - 1);
			}

			//if finished transitioning
			if (openTimer >= windowOpenTime)
			{
				transitioning = false;
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
							if (GameManager.Instance)
							{
								GameManager.Instance.IsCursorRestricted = true;
								GameManager.Instance.Player.InputIsEnabled = true;
								Time.timeScale = 1;
							}
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
			else
			{
				//transition window
				if (current != null)
					current.UpdateOpenState(t);

				//transition background panel
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
			if (GameManager.Instance)
			{
				GameManager.Instance.IsCursorRestricted = false;
				GameManager.Instance.Player.InputIsEnabled = false;
				Time.timeScale = 0;
			}
			
			if (backgroundPanel)
				backgroundPanel.OpenWindow(true);
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

	public void RemoveFromQueue(bool overrideClose = false)
	{
		var current = GetCurrentWindow();
		if (current != null)
		{
			if (!current.canBeExited) return;

			if (overrideClose && current.GetState() == GameWindow.TransitionState.CLOSING)
			{
				current.UpdateOpenState(1);

				activeWindows.Pop();
				current = GetCurrentWindow();
				if (current == null)
				{
					if (GameManager.Instance)
					{
						GameManager.Instance.IsCursorRestricted = true;
						GameManager.Instance.Player.InputIsEnabled = true;
						Time.timeScale = 1;
					}
				}
				else
				{
					current.SetInteractive(true);
				}

				current.OpenWindow(false);
				transitioning = true;
				openTimer = 0;

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
			else if (current.GetState() != GameWindow.TransitionState.CLOSING)
			{
				current.OpenWindow(false);
				transitioning = true;
				openTimer = 0;

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
		if (GameManager.Instance)
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
