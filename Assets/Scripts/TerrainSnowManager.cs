using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.CompilerServices;
using System.IO;
using System;
using System.Linq;

[Serializable]
public class Step
{
    public Vector3 pos;
    public float size;
    public float strength;

    public Step(Vector3 position, float size, float strength)
    {
        pos = position;
        this.size = size;
        this.strength = strength;
    }
}

[ExecuteAlways]
public class TerrainSnowManager : MonoBehaviour
{
    //  public TouchReactSystem touchReact;

    public Terrain[] terrains;

    public CustomTerrainTextures customTextures;

    [Range(1, 20)]
    public float tesselation = 10;
    [Range(10, 50)]
    public float MinTesDist = 20;
    [Range(10, 100)]
    public float MaxTesDist = 60;

    public Shader terrainShader;

    public List<CustomTerrain> customTerrains = new List<CustomTerrain>();

    public void Start()
    {
        ShowSnow(true);
    }

    public void ShowSnow(bool show)
    {
        if (show)
        {
            ReloadTextures();
        }
        else
        {
            foreach (var t in terrains)
            {
                t.materialTemplate = new Material(Shader.Find("Nature/Terrain/Diffuse"));
            }
        }
    }

    private void OnValidate()
    {
        foreach (var t in customTerrains)
        {
            t.Refresh();
        }
    }

    public void ReloadTextures()
    {
        customTerrains.Clear();

        foreach (Terrain terrain in terrains)
        {
            CustomTerrain terrainTracks = terrain.GetComponent<CustomTerrain>();
            if (terrainTracks == null)
            {
                terrainTracks = terrain.gameObject.AddComponent<CustomTerrain>();
            }
            customTerrains.Add(terrainTracks);

            terrainTracks.Reload(terrainShader, customTextures, new Vector3(tesselation, MinTesDist, MaxTesDist)); ;
        }
    }

    private void OnEnable()
    {
        ReloadTextures();
    }
}