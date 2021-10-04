using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

[RequireComponent(typeof(EnemyCombat))] [RequireComponent(typeof(NavMeshAgent))] [RequireComponent(typeof(EnemyHealth))]
public class EnemyController : MonoBehaviour
{
    #region Exposed Variables
    public float spottingDistance = 10f;
    public float attackingDistance = 2f;
    
    public float movementSpeed = 4f;
    public float turnSpeed = 120f;
    public float stoppingDistance = 1f;

    public Color enemyViewDistanceColour;
    public Color enemyAttackingDistanceColour;

    #endregion

    #region Private Variables
    [HideInInspector]
    public bool attack;

    private Transform target;
    private NavMeshAgent nav;


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
        nav.angularSpeed = turnSpeed;
        nav.stoppingDistance = stoppingDistance;
    }
 
    void Update()
    {
        SearchForTarget();
    }

    void SearchForTarget()
    {

        //Check if the player is within the range of the spotting distance
        if (Vector3.Distance(transform.position, target.position) <= spottingDistance)
        {
            MoveToTarget();
        }
        else if (Vector3.Distance(transform.position, target.position) > spottingDistance)
        {
            Debug.Log("Search for target");
            nav.isStopped = true;
        }
    }
    void MoveToTarget()
    {

        //Stop the enemy moving towards the player if with in attacking range
        if(Vector3.Distance(transform.position, target.position) <= attackingDistance)
        {
            Debug.Log("Attack player");

            attack = true;
        }
        else if (Vector3.Distance(transform.position, target.position) > attackingDistance)//Contiune the enemy's path towards the player if not in attacking range
        {
            Debug.Log("Move to target");
            attack = false;
            nav.isStopped = false;
            nav.SetDestination(target.position);
        }
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = enemyViewDistanceColour;
        Gizmos.DrawSphere(transform.position, spottingDistance);
      
        Gizmos.color = enemyAttackingDistanceColour;
        Gizmos.DrawSphere(transform.position, attackingDistance);
    }


}
