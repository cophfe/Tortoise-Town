using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(RectTransform))]
public class UISineFloat : MonoBehaviour
{
	public float floatMagnitude = 10;
	public float floatSpeed = 1;
	public float timeOffset = 0;

	RectTransform rectTransform;
	float initialY;
	// Start is called before the first frame update
	void Start()
    {
		rectTransform = GetComponent<RectTransform>();
		initialY = rectTransform.anchoredPosition.y;
	}

    // Update is called once per frame
    void Update()
    {
		Vector2 vec = rectTransform.anchoredPosition;
		vec.y = initialY + Mathf.Sin(floatSpeed * Time.time + timeOffset) * floatMagnitude;
		rectTransform.anchoredPosition = vec;
    }
}
