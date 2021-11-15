#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class AlignDownEditor
{

    [MenuItem("Tools/Align Objects")]
    private static void AlignObjectsDown()
    {
        AlignDown[] alignScripts = Object.FindObjectsOfType<AlignDown>();

            for (int i = 0; i < alignScripts.Length; i++)
            {
                alignScripts[i].alignDown();
            }
        
    }
}
#endif