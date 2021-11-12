using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(PlayerMotor)), RequireComponent(typeof(PlayerHealth)), DefaultExecutionOrder(2)]
public class PlayerController : MonoBehaviour
{
	[SerializeField] CameraController cameraController = null;
	[SerializeField] GameplayUIManager gUI = null;
	[SerializeField] float rollColliderRadius = 0.5f;
	[SerializeField] Vector3 additionalRollColliderOffset = Vector3.zero;
	[SerializeField] float rollCameraYOffset = 0;
	[SerializeField] private Transform rotatableChild = null;
	[SerializeField] InterpolateChild visualInterpolator = null;
	[SerializeField] PlayerAudioData audioData = null;
	[SerializeField] bool drawDebug = false;
	Vector3 rollColliderOffset;

	//INPUT
	public Vector2 inputVector { get; private set; }
	bool jumpPressed;
	bool jumpCancelled;
	bool crouchPressed;
	bool sprintPressed;
	bool attackPressed;

	#region Properties
	public PlayerInput PlayerInput { get; private set; }
	public PlayerMotor Motor { get; private set; }
	public PlayerAnimator Animator { get; private set; }
	public CharacterController CharacterController { get; private set; }
	public PlayerCombat Combat { get; private set; }
	public PlayerHealth Health { get; private set; }
	public CameraController MainCamera { get { return cameraController; }}
	public Transform RotateChild { get { return rotatableChild; } }
	public GameplayUIManager GUI { get { return gUI; } }
	public InterpolateChild Interpolator { get { return visualInterpolator; } }

	public AudioSource PlayerAudio { get; private set; }
	public AudioSource FootstepAudio { get; private set; }
	public PlayerAudioData AudioData { get { return audioData; } }
	public float InitialColliderHeight { get; private set; }
	public float InitialColliderRadius { get; private set; }
	public Vector3 InitialColliderOffset { get; private set; }

	public float RollColliderRadius { get { return rollColliderRadius; } }
	public Vector3 RollColliderOffset { get { return rollColliderOffset + additionalRollColliderOffset; } }
	public float RollCameraOffset { get { return rollCameraYOffset; } }
	public bool DrawDebug { get { return drawDebug; } }
	public bool InputIsEnabled
	{
		set
		{
			cameraController.EnableInput = value;
			PlayerInput.enabled = value;
		}
	}

	public bool InterpolateVisuals {
		get
		{
			return visualInterpolator && !visualInterpolator.disable;
		}
		set
		{
			if (visualInterpolator)
			{
				visualInterpolator.disable = !value;
				MainCamera.movementUpdateType = value ? CameraController.MovementUpdateType.UPDATE : CameraController.MovementUpdateType.FIXEDUPDATE;
			}
		}
	}
	#endregion

	void Awake()
    {
		PlayerInput = GetComponent<PlayerInput>();
		
		Motor = GetComponent<PlayerMotor>();
		Animator = GetComponentInChildren<PlayerAnimator>();
		if (!Animator)
			Animator = FindObjectOfType<PlayerAnimator>();
		CharacterController = GetComponent<CharacterController>();
		Health = GetComponent<PlayerHealth>();
		Combat = GetComponent<PlayerCombat>();
		visualInterpolator = GetComponentInChildren<InterpolateChild>();
		if (!gUI)
			gUI = FindObjectOfType<GameplayUIManager>();
		if (!MainCamera)
			cameraController = FindObjectOfType<CameraController>();
		FootstepAudio = GetComponent<AudioSource>();
		PlayerAudio = Interpolator.GetComponent<AudioSource>();

		if (rotatableChild == null)
		{
			if (transform.childCount > 0)
				rotatableChild = transform.GetChild(0);
			else
			{
				rotatableChild = transform;
			}
		}
			
		InitialColliderHeight = CharacterController.height;
		InitialColliderRadius = CharacterController.radius;
		InitialColliderOffset = CharacterController.center;
		rollColliderOffset = CharacterController.center + new Vector3(0, (rollColliderRadius - CharacterController.height)/2, 0);
	}
	
	public void ResetPlayerToDefault()
	{
		if (!Health) return;

		Health.Revive(10000);
		Animator.transform.rotation = Quaternion.identity;
		Motor.ResetMotor();
		InputIsEnabled = true;
		Animator.AnimateDeath(false);
		Interpolator.ResetPosition();
		//Reset player and camera to default state
	}

	public void PlayAudioOnce(AudioClipList clipList, bool doNotOverlap = false)
	{
		if (doNotOverlap && PlayerAudio.isPlaying) return;
		PlayerAudio.PlayOneShot(clipList.GetRandom());
	}

	#region Evaluate Functions

	public bool EvaluateJumpPressed()
	{
		bool val = jumpPressed;
		jumpPressed = false;
		return val;
	}

	public bool EvaluateCrouchPressed()
	{
		bool val = crouchPressed;
		crouchPressed = false;
		return val;
	}

	public bool EvaluateSprintPressed()
	{
		bool val = sprintPressed;
		sprintPressed = false;
		return val;
	}

	public bool EvaluateJumpCancelled()
	{
		bool val = jumpCancelled;
		jumpCancelled = false;
		return val;
	}

	public bool EvaluateAttackPressed()
	{
		bool val = attackPressed;
		attackPressed = false;
		return val;
	}

	#endregion

	#region Input Functions

	public void OnMoveInput(InputAction.CallbackContext ctx)
	{
		inputVector = ctx.ReadValue<Vector2>();
	}

	public void OnJumpPressed(InputAction.CallbackContext ctx)
	{
		if (ctx.canceled)
			jumpCancelled = true;
		else
			jumpPressed = true;
	}

	public void OnSprintInput(InputAction.CallbackContext ctx)
	{
		if (ctx.performed)
			sprintPressed = true;
	}

	public void OnCrouchInput(InputAction.CallbackContext ctx)
	{
		if (ctx.performed)
			crouchPressed = true;
	}

	public void OnAimPressed(InputAction.CallbackContext ctx)
	{
		if (ctx.canceled)
			Combat.EndChargeUp();
		else
			Combat.StartChargeUp();
	}

	public void OnAttackInput(InputAction.CallbackContext ctx)
	{
		if (ctx.performed)
			attackPressed = true;
	}
	#endregion
}
