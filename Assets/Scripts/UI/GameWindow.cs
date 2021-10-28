using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

[RequireComponent(typeof(RectTransform), typeof(CanvasGroup))]
public class GameWindow : MonoBehaviour
{
	RectTransform rectTransform;
	CanvasGroup alphaGroup;
	TransitionState state = TransitionState.CLOSED;
	Vector3 initialScale;
	Vector3 smallScale;
	enum TransitionState
	{
		OPEN,
		OPENING,
		CLOSED,
		CLOSING,
	}

	private void Awake()
	{
		rectTransform = GetComponent<RectTransform>();
		alphaGroup = GetComponent<CanvasGroup>();
		initialScale = rectTransform.localScale;
		smallScale = initialScale * 0.75f;
		smallScale.z = 1;
	}

	public bool OpenWindow(bool openValue)
	{
		if ((openValue && state == TransitionState.OPEN) || (!openValue && state == TransitionState.CLOSED)) return false;

		if (openValue)
		{
			gameObject.SetActive(true);
			state = TransitionState.OPENING;
			rectTransform.localScale = smallScale;
			alphaGroup.alpha = 0;
		}
		else
		{
			rectTransform.localScale = initialScale;
			alphaGroup.alpha = 1;
			state = TransitionState.CLOSING;
		}
		return true;
	}

	public void UpdateOpenState(float t)
	{
		switch (state)
		{
			case TransitionState.OPENING:
				if (t >= 1)
				{
					//done opening
					rectTransform.localScale = initialScale;
					state = TransitionState.OPEN;
					alphaGroup.alpha = 1;
				}
				else
				{
					rectTransform.localScale = Vector3.Lerp(smallScale, initialScale, t);
					alphaGroup.alpha = t;
				}
				
				break;

			case TransitionState.CLOSING:
				if (t >= 1)
				{
					//done closing
					rectTransform.localScale = smallScale;
					state = TransitionState.CLOSED;
					gameObject.SetActive(false);
					alphaGroup.alpha = 0;
				}
				else
				{
					rectTransform.localScale = Vector3.Lerp(initialScale, smallScale, t);
					alphaGroup.alpha = 1- t;
				}
				break;
		}
		
	}
}
