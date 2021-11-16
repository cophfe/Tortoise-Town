using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class AlignDown : MonoBehaviour
{
    public void alignDown()
    {
        int randomNum = Random.Range(0, 2);
        Debug.Log(randomNum);
        if (randomNum == 1)
        {
            transform.parent.GetComponent<ArrayHandle>().vines.Add(this.gameObject);
        }
        

            /* for (int i = 0; i < 250; i++)
             {
                 RaycastHit hit;
             //    if (Physics.SphereCast(transform.position, 0.1f, Random.onUnitSphere, out hit))
               //  {


                 if (Physics.Raycast(transform.position, Random.onUnitSphere, out hit, Mathf.Infinity))
                 {
                     //transform.forward = hit.normal;
                     transform.rotation = Quaternion.LookRotation(hit.normal, Vector3.up);
                     break;
                     //transform.localRotation = Quaternion.Euler(90, 0, 0);
                 }else
                 {
                     Debug.Log("No surface was found");
                 }
             }
            */

            // transform.rotation = Quaternion.Euler(transform.rotation.x + 90, transform.rotation.y, transform.rotation.z);
        }
}
