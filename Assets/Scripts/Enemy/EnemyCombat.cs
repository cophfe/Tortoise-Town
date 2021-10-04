using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyCombat : MonoBehaviour
{
    public enum CombatType { Melee, Ranged }
    public CombatType combatType;
    
    public bool isAttacking;

    private float attackRate;
    private float attackRateTimer;
    private float attackRange;
    private bool canAttack;

    private GameObject projectile;
    private Transform firepoint;



    void Update()
    {
        RetrieveVariables();
        PreAttack();
    }

    void RetrieveVariables()
    {
        attackRate = GetComponent<EnemyController>().attackRate;
        canAttack = GetComponent<EnemyController>().canAttack;
        projectile = GetComponent<EnemyController>().projectile;
        firepoint = GetComponent<EnemyController>().firepoint;
        attackRange = GetComponent<EnemyController>().attackingDistance;
    }

    void PreAttack()
    {
        attackRateTimer += Time.deltaTime;

        if (canAttack)
        {
            isAttacking = true;

            if (attackRateTimer > attackRate)
            {
                if (combatType == CombatType.Melee)
                {
                    MeleeAttack();
                }
                else
                {
                    RangedAttack();
                }
                attackRateTimer = 0;
            }
        }
        else
        {
            isAttacking = false;
        }
    }

    void MeleeAttack()
    {
      //  Debug.Log("Melee Attack");

        RaycastHit hit;
        if(Physics.Raycast(firepoint.position, firepoint.forward, out hit, attackRange))
        {
            Debug.Log(hit.transform.name);
        }

        isAttacking = false;
    }

    void RangedAttack()
    {
        //  Debug.Log("Ramged Attack");

        GameObject bullet = Instantiate(projectile, firepoint.position, transform.rotation);

        isAttacking = false;
    }

    private void OnDrawGizmosSelected()
    {
        if(firepoint)
            Gizmos.DrawRay(firepoint.position, firepoint.forward);
    }

}
