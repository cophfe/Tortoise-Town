using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

[RequireComponent(typeof(TextMeshProUGUI))]
public class SliderValueText : MonoBehaviour
{
	public string toStringFormat = "0.0";
	TextMeshProUGUI txt = null;

	public void SetText(float value)
	{
		if (txt == null)
			txt = GetComponent<TextMeshProUGUI>();

		txt.text = value.ToString(toStringFormat);
	}
}
