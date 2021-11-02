using System;
using UnityEngine;

[ExecuteAlways]
public class MetaballParticleManager : MonoBehaviour
{
    MeshRenderer _renderer;
    MaterialPropertyBlock _materialPropertyBlock;

    const int _maxPoints = 256;
    int _numPoints;

    public GameObject[] _gameobjectPoints = new GameObject[_maxPoints];



    readonly Vector4[] _particlesPos = new Vector4[_maxPoints];
    readonly float[] _particlesSize = new float[_maxPoints];

    static readonly int NumParticles = Shader.PropertyToID("_NumParticles");
    static readonly int ParticlesSize = Shader.PropertyToID("_ParticlesSize");
    static readonly int ParticlesPos = Shader.PropertyToID("_ParticlesPos");

    void OnEnable()
    {

        _materialPropertyBlock = new MaterialPropertyBlock();
        _materialPropertyBlock.SetInt(NumParticles, 0);

        _renderer = GetComponent<MeshRenderer>();
        _renderer.SetPropertyBlock(_materialPropertyBlock);
    }

    void OnDisable()
    {
        _materialPropertyBlock.Clear();
        _materialPropertyBlock = null;
        _renderer.SetPropertyBlock(null);
    }

    void Update()
    {
        _numPoints = _gameobjectPoints.Length;
        int i = 0;
        foreach (var particle in _gameobjectPoints)
        {
            _particlesPos[i] = particle.transform.position;
            _particlesSize[i] = particle.transform.localScale.y * 10;
            ++i;
            
            if (i >= _numPoints) break;
        }

        _materialPropertyBlock.SetVectorArray(ParticlesPos, _particlesPos);
        _materialPropertyBlock.SetFloatArray(ParticlesSize, _particlesSize);
        _materialPropertyBlock.SetInt(NumParticles, _numPoints);
        _renderer.SetPropertyBlock(_materialPropertyBlock);
    }
}