using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FinalGooDissolve : GooDissolve
{
	protected override void Awake()
	{
		requiredForWin = false;
		base.Awake();
	}

	protected override void StartDissolving()
	{
		GameManager.Instance.InitiateFinalCutscene();
		base.StartDissolving();
	}
}