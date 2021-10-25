using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//this is for objects that should have a response to colliding to the player's movement
//the player only calls the first object like this on a gameobject
public abstract class PlayerCollision : MonoBehaviour
{
	/// <summary>
	/// Called by player when it's character controller collides with this gameobject
	/// </summary>
	/// <returns>Whether the player should continue with the collision implementation or not</returns>
	public abstract bool OnCollideWithPlayer(PlayerMotor player, ControllerColliderHit hit);

	/// <summary>
	/// Called by player when it sets this gameobject as the floor
	/// </summary>
	/// <returns>Whether the player should continue with this gameobject as the floor or not</returns>
	public abstract bool OnPlayerGrounded(PlayerMotor player);
}
