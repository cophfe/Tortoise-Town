using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SplineFollower : BooleanSwitch
{
    public Spline spline;
    public float speed = 5;
    public bool rotateWithSpline = false;
    public LoopType loopType = LoopType.ONCE;
    public MovingPlatform.EaseMode easeMode = MovingPlatform.EaseMode.NONE;
    public float stopTime = 0;

    float t = 0;
    int negMultiply = 1;
    float stopTimer = 0;

    public enum LoopType
    {
        PINGPONG,
        RESTART,
        ONCE
    }

    public override void ResetSwitchTo(bool on)
    {
        throw new System.NotImplementedException();
    }

    float iterateAmount = 0;
    private void Update()
    {
        if (!on) return;

        stopTimer -= Time.deltaTime;
        if (stopTimer > 0)
            return;

		t += negMultiply * iterateAmount * Time.deltaTime;
        
        if (loopType == LoopType.PINGPONG)
        {
            if (t >= 1)
            {
                t = 1;
                negMultiply = -1;
                stopTimer = stopTime;
            }
            else if (t < 0)
            {
                stopTimer = stopTime;
                negMultiply = 1;
                t = 0;
            }
        }
        else if (t >= 1)
        {
            stopTimer = stopTime;

            if (loopType == LoopType.ONCE)
                Switch(false);
            else if (loopType == LoopType.RESTART)
            {
                if (spline.CheckLooping())
                    t -= 1;
                else
                    t = 0;
            }
        }

        float easedT;
        switch (easeMode)
        {
            case MovingPlatform.EaseMode.INOUT:
                easedT = Ease.EaseInOutQuad(t);
                break;
            default:
                easedT = t;
                break;
        }

        spline.GetInfoOnSpline(speed, easedT, out Vector3 endPoint, out iterateAmount, out Vector3 direction);

        transform.position = endPoint;

        if (rotateWithSpline)
        {
            transform.forward = direction.normalized;
        }
    }

    public override bool SwitchValue
    {
        get { return on; }
        protected set
        {
            on = value;
        }
    }

}
