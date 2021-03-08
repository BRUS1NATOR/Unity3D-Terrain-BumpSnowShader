using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

[CreateAssetMenu(menuName = "CustomTerrainTextures")]
public class CustomTerrainTextures : ScriptableObject
{
    [SerializeField]
    public List<CustomTextureArray> textureArray;
}

[Serializable]
public class CustomTextureArray
{
    public TerrainLayer layer;
    public Texture2D bumpTexture;
    [Range(0, 1)]
    public float bumpScale = 0.5f;

    public Texture2DArray texture2DArray;

    public Vector4 Tiling
    {
        get
        {
            return new Vector4(layer.tileSize.x, layer.tileSize.y, layer.tileOffset.x, layer.tileOffset.y);
        }
    }

    private string CreateTextureArray()
    {
        Debug.Log("NO TEXTURE, CREATING..");
        try
        {
            // Create Texture2DArray
            texture2DArray = new Texture2DArray(layer.diffuseTexture.width, layer.diffuseTexture.height, 4, TextureFormat.RGBA32, true, false);
            // Apply settings
            texture2DArray.filterMode = FilterMode.Bilinear;
            texture2DArray.wrapMode = TextureWrapMode.Repeat;

            // Copy pixels to the Texture2DArray
            texture2DArray.SetPixels(layer.diffuseTexture.GetPixels(0), 0, 0);
            if (layer.normalMapTexture != null)
            {
                texture2DArray.SetPixels(layer.normalMapTexture.GetPixels(0), 1, 0);
            }
            if (layer.maskMapTexture != null)
            {
                texture2DArray.SetPixels(layer.maskMapTexture.GetPixels(0), 2, 0);
            }
            if (bumpTexture != null)
            {
                texture2DArray.SetPixels(bumpTexture.GetPixels(0), 3, 0);
            }

            // Apply our changes
            texture2DArray.Apply();
        }
        catch(Exception e)
        {
            Debug.LogError(e.Message);
            texture2DArray = null;
            return "";
        }

        string path = SaveTextureArrayAsAsset(texture2DArray, layer.name + "_Array");

        texture2DArray = Resources.Load(path) as Texture2DArray;

        return path;
    }

    public Texture2DArray GetTextureArray()
    {
        if (texture2DArray == null)
        {
            CreateTextureArray();
        }

        return texture2DArray;
    }

    public string GetTexturePath()
    {
        if (texture2DArray == null)
        {
            CreateTextureArray();
        }
        return "CustomTerrainShaderTextures/" + layer.name + "_Array";
    }


    public string SaveTextureArrayAsAsset(Texture2DArray _texture, string name)
    {
#if UNITY_EDITOR
        var dirPath = Application.dataPath + "/Resources/CustomTerrainShaderTextures/";
        if (!Directory.Exists(dirPath))
        {
            Directory.CreateDirectory(dirPath);
        }

        UnityEditor.AssetDatabase.CreateAsset(_texture, "Assets/Resources/CustomTerrainShaderTextures/" + name + ".asset");
#endif
        return "CustomTerrainShaderTextures/" + name;
    }
}
