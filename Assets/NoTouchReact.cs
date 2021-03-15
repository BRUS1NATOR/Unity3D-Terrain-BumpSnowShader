using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// USE THIS SCRIPT IF YOU DONT HAVE Vegetation Studio with TouchReact
/// </summary>

public enum TouchReactQuality
{
    Low = 0,
    Normal = 1,
    High = 2
}

public class NoTouchReact : MonoBehaviour
{
    public Camera TouchReactCamera;
    public Camera mainCamera;

    public TouchReactQuality quality;
    [Range(10,100)]
    public int drawDistance = 24;

    private void Awake()
    {
        UpdateCamera();
    }

    private void OnValidate()
    {
        TouchReactCamera.orthographicSize = drawDistance;
    }

    // Start is called before the first frame update
    private void Update()
    {
        if (TouchReactCamera && mainCamera)
        {
            Vector3 tempCameraPosition = GetCameraPosition();
            var pos = tempCameraPosition;

            pos.x = SnapToPixel(pos.x, TouchReactCamera.targetTexture.width, TouchReactCamera.orthographicSize);
            pos.y = 0;
            pos.z = SnapToPixel(pos.z, TouchReactCamera.targetTexture.height, TouchReactCamera.orthographicSize);

            TouchReactCamera.transform.position = pos;
        }
        UpdateCamera();
    }

    private float SnapToPixel(float v, int textureSize, float orthoSize)
    {
        float worldPixel = orthoSize * 2 / textureSize;

        v = (int)(v / worldPixel);
        v *= worldPixel;

        return v;
    }


    public void UpdateCamera()
    {
        if (TouchReactCamera)
        {
            int textureResolution = GetTouchReactQualityPixelResolution(quality);
            RenderTexture rt =
                new RenderTexture(textureResolution, textureResolution, 24, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear)
                {
                    wrapMode = TextureWrapMode.Clamp,
                    filterMode = FilterMode.Point,
                    autoGenerateMips = false,
                    hideFlags = HideFlags.DontSave
                };

            RenderTexture oldRenderTexture = TouchReactCamera.targetTexture;
            TouchReactCamera.targetTexture = rt;

            if (oldRenderTexture)
            {
                DestroyImmediate(oldRenderTexture);
            }
        }

        Shader.SetGlobalTexture("_TouchReact_Buffer", TouchReactCamera.targetTexture);
        Vector4 pos = TouchReactCamera.transform.position;
        pos.z = -pos.z;
        pos.w = TouchReactCamera.orthographicSize * 2;
        pos.x -= TouchReactCamera.orthographicSize;
        pos.z -= TouchReactCamera.orthographicSize;
        Shader.SetGlobalVector("_TouchReact_Pos", pos);
    }

    public Vector3 GetCameraPosition()
    {
        if (Application.isPlaying)
        {
            if (mainCamera)
            {
                return mainCamera.transform.position;
            }
            else
            {
                return Vector3.zero;
            }
        }
        return Vector3.zero;
    }

    public int GetTouchReactQualityPixelResolution(TouchReactQuality touchReactQuality)
    {
        switch (touchReactQuality)
        {
            case TouchReactQuality.Low:
                return 512;
            case TouchReactQuality.Normal:
                return 1024;
            case TouchReactQuality.High:
                return 2048;
            default:
                return 1024;
        }
    }
}
