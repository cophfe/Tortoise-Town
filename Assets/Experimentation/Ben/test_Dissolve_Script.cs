using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class test_Dissolve_Script : MonoBehaviour
{
    public List<GameObject> buildingParents;

    public List<MeshRenderer> dissolveMaterials;

    public float cutOffHeight;

    void Start()
    {
        foreach (var parent in buildingParents)
        {
            dissolveMaterials.AddRange(parent.GetComponentsInChildren<MeshRenderer>());
        } 
    }

    // Update is called once per frame
    void Update()
    {
        foreach (var render in dissolveMaterials)
        {
            render.material.SetFloat("_CuttoffHieght", cutOffHeight);
        }
    }
}
