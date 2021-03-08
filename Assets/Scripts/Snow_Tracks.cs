using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(TrailRenderer))]
public class Snow_Tracks : MonoBehaviour
{
    [Range(1,10)]
    public float size=1f;
    [Range(0, 1)]
    public float strength = 0.25f;

    public bool leaveTracks = true;
    public float timeToLive = 100f;

    public TrailRenderer trail;
    public Material trailMaterial;

    private void OnValidate()
    {
        if (trailMaterial == null)
        {
            trailMaterial = (Material)Resources.Load("LineBlured", typeof(Material));
        }
    }

    void Start()
    {
        trail = GetComponent<TrailRenderer>();
    //    trail.gameObject.layer = TerrainManager.instance.terrainSnowManager.touchReact.InvisibleLayer;

        trail.sharedMaterial = trailMaterial;

        trail.startWidth = size;
        trail.endWidth = size;
        trail.time = timeToLive;
        trail.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
    }
}
