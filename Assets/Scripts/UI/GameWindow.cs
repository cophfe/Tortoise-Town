using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;

[RequireComponent(typeof(RectTransform))]
public class GameWindow : MonoBehaviour
{
	public bool transitionScale = true;
	RectTransform rectTransform;
	CanvasGroup alphaGroup;
	Image image;
	TransitionState state = TransitionState.CLOSED;
	Vector3 initialScale;
	float initialAlpha;
	Vector3 smallScale;
	public enum TransitionState
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
		image = GetComponent<Image>();
		if (alphaGroup) initialAlpha = alphaGroup.alpha;
		else if (image) initialAlpha = image.color.a;
		else initialAlpha = 1;
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
			if (transitionScale)
				rectTransform.localScale = smallScale;
			SetAlpha(0);
		}
		else
		{
			if (transitionScale)
				rectTransform.localScale = initialScale;
			state = TransitionState.CLOSING;
			SetAlpha(initialAlpha);
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
					if (transitionScale)
						rectTransform.localScale = initialScale;
					state = TransitionState.OPEN;
					SetAlpha(initialAlpha);
				}
				else
				{
					if (transitionScale)
						rectTransform.localScale = Vector3.Lerp(smallScale, initialScale, t);
					SetAlpha(initialAlpha  * t);
				}
				
				break;

			case TransitionState.CLOSING:
				if (t >= 1)
				{
					//done closing
					if (transitionScale)
						rectTransform.localScale = smallScale;
					state = TransitionState.CLOSED;
					gameObject.SetActive(false);
					SetAlpha(0);
				}
				else
				{
					if (transitionScale)
						rectTransform.localScale = Vector3.Lerp(initialScale, smallScale, t);
					SetAlpha(initialAlpha * (1 - t));
				}
				break;
		}
		
	}

	void SetAlpha(float alpha)
	{
		if (alphaGroup)
		{
			alphaGroup.alpha = alpha;
		}
		else if (image)
		{
			var color = image.color;
			color.a = alpha;
			image.color = color;
		}
	}
}
