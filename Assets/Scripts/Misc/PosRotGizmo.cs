using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PosRotGizmo : MonoBehaviour
{
    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawRay(transform.position, Vector3.ProjectOnPlane(transform.forward, Vector3.up).normalized);
        Gizmos.color = Color.red;
        Gizmos.DrawRay(transform.position, Vector3.up);
    }
}
