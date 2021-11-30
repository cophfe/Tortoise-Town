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
	float turnSpeed = 10;
	ObjectPool arrowPool;
	Arrow currentArrow;
	public Animator animator;
	bool dead = false;
	AudioSource attachedAudio;

	protected void Start()
    {
		arrowPool = new ObjectPool(arrowCount, 1, gooShotPrefab, transform);
		attachedAudio = GetComponent<AudioSource>();
		shootTimer = shootIntervel * UnityEngine.Random.Range(0.0f, 0.5f);

	}

	void Update()
    {
		if (!dead && attackPlayer)
		{
			UpdateRotation();
			shootTimer -= Time.deltaTime;
			if (shootTimer < 0)
			{
				shootTimer = shootIntervel * UnityEngine.Random.Range(0.4f, 1.0f);
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
		if (attachedAudio != null)
			attachedAudio.Play();
		float initialSpeed = gooShotInfo.maxInitialSpeed;
		Vector3 velocity = Vector3.zero;
		Vector3 arrowAimPoint = PredictShotPosition(arrowTransformPosition.position);// GameManager.Instance.Player.Interpolator.transform.position;

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
		Quaternion target = Quaternion.LookRotation(pos - transform.position, Vector3.up);
		transform.rotation = Quaternion.RotateTowards(transform.rotation, target, Quaternion.Angle(target, transform.rotation) * turnSpeed * Time.deltaTime);
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

	public Vector3 PredictShotPosition(Vector3 startPosition)
	{
		var player = GameManager.Instance.Player;
		Vector3 endPoint = player.Interpolator.transform.position;
		Vector3 delta = endPoint - startPosition;
		

		float time = delta.magnitude / gooShotInfo.maxInitialSpeed;
		endPoint += player.Motor.TotalVelocity * time;
		
		return endPoint;
	}
}
