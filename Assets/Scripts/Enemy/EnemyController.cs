using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

[RequireComponent(typeof(EnemyCombat))] [RequireComponent(typeof(NavMeshAgent))] [RequireComponent(typeof(EnemyHealth))]
public class EnemyController : MonoBehaviour
{
    #region Exposed Variables
    public float spottingDistance = 10f;
    [Space(5)]
    [Header("Movement variables")]
    public float movementSpeed = 4f;
    public float turnSpeed = 120f;
    public float stoppingDistance = 1f;

    [Space(5)]
    [Header("Attacking variables")]
    public float attackingDistance = 2f;
    public float attackRate;
    public GameObject projectile;
    public Transform firepoint;
    public LayerMask dontIgnoreLayers;

    [Space(5)]
    [Header("Gizmo")]
    public Color enemyViewDistanceColour;
    public Color enemyAttackingDistanceColour;
    #endregion

    #region Private Variables
    [HideInInspector]
    public bool canAttack;

    private Transform target;
    private NavMeshAgent nav;
    private EnemyCombat enemyCombat;

    #endregion
    void Start()
    {
        //Set Variables
        //find the player
        target = GameObject.FindGameObjectWithTag("Player").transform;
        
        //retrieve the nav mesh agent of the enemy
        nav = GetComponent<NavMeshAgent>();
        //set the nav mesh variable to the controller variables
        nav.speed = movementSpeed;
        nav.angularSpeed = 0;
        nav.stoppingDistance = stoppingDistance;
        enemyCombat = GetComponent<EnemyCombat>();
    }
 
    void Update()
    {
        SearchForTarget();
    }

    void SearchForTarget()
    {
        if (!enemyCombat.isAttacking)
        {

            //Check if the player is within the range of the spotting distance
            if (Vector3.Distance(transform.position, target.position) <= spottingDistance)
            {
                RaycastHit hit;
                if (Physics.Raycast(transform.GetChild(1).GetChild(0).position, target.position - transform.position, out hit, Mathf.Infinity, dontIgnoreLayers))
                {
                    Debug.Log(hit.transform.name);
                    if (hit.transform.tag == "Player")
                    {
                        MoveToTarget();
                    }
                    else
                    {
                        //  Debug.Log("Search for target");
                        nav.isStopped = true;
                        canAttack = false;

                    }
                }
                else
                {
                    //  Debug.Log("Search for target");
                    nav.isStopped = true;
                    canAttack = false;

                }

            }
            else if (Vector3.Distance(transform.position, target.position) > spottingDistance)
            {
              //  Debug.Log("Search for target");
                nav.isStopped = true;
                canAttack = false;

            }
        }
        else
            nav.isStopped = true;
    }
    void MoveToTarget()
    {
        var lookPos = target.position - transform.position;
        lookPos.y = 0;
        var rotation = Quaternion.LookRotation(lookPos);
        transform.rotation = Quaternion.Slerp(transform.rotation, rotation, Time.deltaTime * turnSpeed);

        //Stop the enemy moving towards the player if with in attacking range
        if (Vector3.Distance(transform.position, target.position) <= attackingDistance)
        {
           // Debug.Log("Attack player");

            canAttack = true;
        }
        else if (Vector3.Distance(transform.position, target.position) > attackingDistance)//Contiune the enemy's path towards the player if not in attacking range
        {
          //  Debug.Log("Move to target");
            canAttack = false;
            nav.isStopped = false;
            nav.SetDestination(target.position);
        }
    }

    private void OnDrawGizmosSelected()
    {
        if (target)
        {
            Gizmos.DrawRay(transform.GetChild(1).GetChild(0).position, target.position - transform.position);
        }

        Gizmos.color = enemyViewDistanceColour;
        Gizmos.DrawSphere(transform.position, spottingDistance);
      
        Gizmos.color = enemyAttackingDistanceColour;
        Gizmos.DrawSphere(transform.position, attackingDistance);

    }


}
