using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

public enum TerrainQuality { HighPoly, LowPoly }

[RequireComponent(typeof(Terrain))]
public class CustomTerrain : MonoBehaviour
{
    public float dist;
    private Terrain terrain;
    public Terrain Terrain
    {
        get
        {
            return terrain;
        }
    }

    private CustomTerrainTextures customTextures;
    private Material terrainMaterial;

    public Vector2Int pos;
    public TerrainQuality quality = TerrainQuality.HighPoly;

    public GameObject lowPolyTerrain;

    private void Awake()
    {
        terrain = GetComponent<Terrain>();
    }

    public void SetQuality(TerrainQuality quality)
    {
        switch (quality)
        {
            case TerrainQuality.HighPoly:
                {
                    terrain.drawHeightmap = true;
                    terrain.drawTreesAndFoliage = true;

                    if (lowPolyTerrain != null)
                    {
                        lowPolyTerrain.SetActive(false);
                    }

                    break;
                }
            case TerrainQuality.LowPoly:
                {
                    terrain.drawHeightmap = false;
                    terrain.drawTreesAndFoliage = false;

                    if (lowPolyTerrain != null)
                    {
                        lowPolyTerrain.SetActive(true);
                    }

                    break;
                }
        }
        this.quality = quality;
    }


    public void Refresh()
    {
        if (terrain == null)
        {
            terrain = GetComponent<Terrain>();
        }

        if (terrainMaterial != null)
        {
            terrain.terrainData.terrainLayers = customTextures.textureArray.Select(x => x.layer).ToArray();

            for (int i = 0; i < customTextures.textureArray.Count; i++)
            {
                terrainMaterial.SetTexture("_Array" + (i + 1), Resources.Load(customTextures.textureArray[i].GetTexturePath()) as Texture2DArray);
            }

            /*SPLATS*/
            if (terrain.terrainData.alphamapTextureCount > 1)
            {
                terrainMaterial.SetTexture("_Control2", terrain.terrainData.alphamapTextures[1]);
            }
            if (terrain.terrainData.alphamapTextureCount > 2)
            {
                terrainMaterial.SetTexture("_Control3", terrain.terrainData.alphamapTextures[2]);
            }
            terrainMaterial.SetFloat("_ControlCount", terrain.terrainData.alphamapTextures.Length);
            /**/

            terrainMaterial.SetFloat("_TWidth", terrain.terrainData.size.x);
            terrainMaterial.SetFloat("_THeight", terrain.terrainData.size.z);

            terrainMaterial.SetFloat("_TPosX", terrain.transform.position.x);
            terrainMaterial.SetFloat("_TPosZ", terrain.transform.position.z);
            terrainMaterial.SetFloatArray("_NormalScaleArray", customTextures.textureArray.Select(n => n.layer.normalScale).ToArray());
            terrainMaterial.SetFloatArray("_BumpScaleArray", customTextures.textureArray.Select(n => n.bumpScale).ToArray());
            terrainMaterial.SetVectorArray("_TileSizeArray", customTextures.textureArray.Select(n => n.Tiling).ToArray());       //x,y = size, z,w = offset

            terrain.materialTemplate = null;
            terrain.materialTemplate = terrainMaterial;
        }
    }

    public void Reload(Shader snowShader, CustomTerrainTextures layers, Vector3 tesselation)
    {
        this.customTextures = layers;
        terrainMaterial = new Material(snowShader);

        terrainMaterial.SetFloat("_TessMultiplier", tesselation.x);
        terrainMaterial.SetFloat("_MinDistTesselation", tesselation.y);
        terrainMaterial.SetFloat("_MaxDistTesselation", tesselation.z);

        Refresh();
    }
}
