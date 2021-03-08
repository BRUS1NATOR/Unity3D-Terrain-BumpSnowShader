using UnityEngine;

public class GlobalSnow : MonoBehaviour
{
    [Range(0.1f, 1f)]
    public float globalSnowAmount = 0.5f;

    [Range(0.1f, 1f)]
    public float snowBlendStrength;

    public void Start()
    {
        SetValues();
    }

    public void OnValidate()
    {
        SetValues();
    }

    private void FixedUpdate()
    {
        SetValues();
    }

    private void SetValues()
    {
        Shader.SetGlobalFloat("_GlobalSnowAmount", globalSnowAmount);
        Shader.SetGlobalFloat("_TerrainSnowBlendStrength", snowBlendStrength);
    }
}