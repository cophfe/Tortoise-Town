using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class GooShooter : MonoBehaviour
{
	public ArrowData gooShotInfo;
	public Arrow gooShotPrefab;
	public float shootIntervel = 5;
	public LayerMask playerLayer;
	public int arrowCount = 4;
	public Transform arrowTransformPosition;
	bool attackPlayer = false;
	float shootTimer = 0;
	ObjectPool arrowPool;
	Arrow currentArrow;
	public Animator animator;
	bool dead = false;

	protected void Start()
    {
		arrowPool = new ObjectPool(arrowCount, 1, gooShotPrefab, transform);
		shootTimer = shootIntervel;
	}

    void Update()
    {
		if (!dead && attackPlayer)
		{
			UpdateRotation();
			shootTimer -= Time.deltaTime;
			if (shootTimer < 0)
			{
				shootTimer = shootIntervel;
				if (currentArrow == null)
				{
					currentArrow = (Arrow)arrowPool.GetPooledObject(arrowTransformPosition);
					currentArrow.transform.localPosition = Vector3.zero;
					currentArrow.transform.localRotation = Quaternion.identity;

					animator.SetTrigger("Throw");
				}
				
			}
		}
    }

	public void ShootGoo()
	{
		if (currentArrow == null) return;
		float initialSpeed = gooShotInfo.maxInitialSpeed;
		Vector3 velocity = Vector3.zero;
		Vector3 arrowAimPoint = GameManager.Instance.Player.Interpolator.transform.position;

		//convert 3d problem into 2d problem like this:
		//calculate x axis
		Vector3 xAxis = (arrowAimPoint - arrowTransformPosition.position);
		xAxis.y = 0;
		xAxis.Normalize();
		//convert 3d point into 2d point
		Vector2 positionToHit = new Vector2(Vector3.Dot(arrowAimPoint, xAxis)
			- Vector3.Dot(arrowTransformPosition.position, xAxis), arrowAimPoint.y - arrowTransformPosition.position.y);

		//now calculate tan(0) of arrow angle and turns it into direction vector
		//https://en.wikipedia.org/wiki/Projectile_motion#Angle_%CE%B8_required_to_hit_coordinate_(x,_y)
		float v4 = initialSpeed * initialSpeed * initialSpeed * initialSpeed;
		float g2 = gooShotInfo.gravity * gooShotInfo.gravity;
		float possibleNeg = v4 - gooShotInfo.gravity * (gooShotInfo.gravity * positionToHit.x * positionToHit.x + 2 * positionToHit.y * initialSpeed * initialSpeed);

		//if distance is too far away to hit at this speed
		if (possibleNeg < 0)
		{
			//find closest valid point that gives a 0 'possibleNeg' value
			//this is technically wrong sometimes, but not when possibleNeg is less than 0
			//(it is wrong because it uses the cubic formula, which gives multiple results, but it only uses one)
			//here is a visualisation: https://www.desmos.com/calculator/olszi1qcpd

			//this should fix for floating point error by looking not for 0 neg value, but errorfix neg value
			const float errorFix = 1;
			double q = -positionToHit.x * v4 / g2;
			double p = (2 * positionToHit.y * gooShotInfo.gravity * initialSpeed * initialSpeed + v4 + errorFix) / (3 * g2);
			double newSqrt = Math.Sqrt(q * q + p * p * p);
			//since pow cannot handle negative cube rooting we will use some jank to fix
			double newXValue = (-Math.Pow(Math.Abs(q + newSqrt), 1.0f / 3.0f) * Math.Sign(q + newSqrt) - Math.Pow(Math.Abs(q - newSqrt), 1.0f / 3.0f) * Math.Sign(q - newSqrt));
			double newYValue = ((v4 - errorFix) / gooShotInfo.gravity - gooShotInfo.gravity * newXValue * newXValue) / (2 * initialSpeed * initialSpeed);
			positionToHit.x = (float)newXValue;
			positionToHit.y = (float)newYValue;
			possibleNeg = v4 - gooShotInfo.gravity * (gooShotInfo.gravity * positionToHit.x * positionToHit.x + 2 * positionToHit.y * initialSpeed * initialSpeed);
		}
		float sqrt = Mathf.Sqrt(possibleNeg);
		//there are technically two options, but this one is always best
		float tanOfAngle = (initialSpeed * initialSpeed - sqrt) / (gooShotInfo.gravity * positionToHit.x);
		// tanOfAngleOption2 = (initialSpeed * initialSpeed + sqrt) / (arrowData.gravity * positionToHit.x);

		Vector2 v = new Vector3(1, tanOfAngle).normalized * initialSpeed;
		velocity.y = v.y;
		velocity += xAxis * v.x;
		//Debug.Log($"x: {positionToHit.x}, y: {positionToHit.y} v: {initialSpeed}, g: {arrowData.gravity}, sq: {possibleNeg}");
		currentArrow.Shoot(velocity, gooShotInfo);
		currentArrow.transform.parent = null;
		currentArrow = null;
	}
	void UpdateRotation()
	{
		Vector3 pos = GameManager.Instance.Player.Interpolator.transform.position;
		pos.y = transform.position.y;
		transform.LookAt(pos);
	}

	public void Kill()
	{
		dead = true;
	}

	public void Revive()
	{
		dead = false;
	}

	private void OnTriggerEnter(Collider other)
	{
		if ((playerLayer & (1 << other.gameObject.layer)) != 0)
		{
			attackPlayer = true;
		}
	}

	private void OnTriggerExit(Collider other)
	{
		if ((playerLayer & (1 << other.gameObject.layer)) != 0)
		{
			attackPlayer = false;
		}
	}
}
