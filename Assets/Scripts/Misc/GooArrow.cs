using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooArrow : Arrow
{
	protected override void OnCollide()
	{
		gameObject.SetActive(false);
		ignoredInPool = false;
	}
}
