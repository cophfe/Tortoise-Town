using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Ease
{
    public static float EaseInQuad(float t)
	{
		return t * t;
	}

	public static float EaseOutQuad(float t)
	{
		return 1 - (1 - t) * (1 - t);
	}

	public static float EaseInOutQuad(float t)
	{
		float val = -2 * t + 2;
		return t < 0.5 ? 2 * t * t : 1 - val*val / 2;
	}

	public static float EaseInPower(float t, int power)
	{
		return Mathf.Pow(t, power);
	}

	public static float EaseOutPower(float t, int power)
	{
		return 1 - Mathf.Pow(1 - t, power);
	}

	public static float EaseInOutPower (float t, int power)
	{
		return t < 0.5 ? Mathf.Pow(2, power) * Mathf.Pow(t, power): 1 - Mathf.Pow(-2 * t + 2, 5) / 2;
	}
}
