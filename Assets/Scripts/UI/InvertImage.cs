using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;

public class InvertImage : Image
{
	// quick inverted mask using https://unitycodemonkey.com/video.php?v=XJJl19N2KFM

	public override Material materialForRendering
	{
		get
		{
			Material mat = new Material(base.materialForRendering);
			mat.SetInt("_StencilComp", (int)CompareFunction.NotEqual);
			return mat;
		}
	}
}
