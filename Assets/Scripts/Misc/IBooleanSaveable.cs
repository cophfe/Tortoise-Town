using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IBooleanSaveable
{
    bool InitialSaveState { get; }
    MonoBehaviour GetMonoBehaviour();

    bool GetCurrentState();

    void SetToState(bool state);
}
