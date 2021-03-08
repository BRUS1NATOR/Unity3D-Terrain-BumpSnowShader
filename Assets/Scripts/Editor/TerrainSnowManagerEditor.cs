using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(TerrainSnowManager))]
public class TerrainSnowManagerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        TerrainSnowManager script = (target as TerrainSnowManager);


        if (GUILayout.Button("ReloadTexture"))
        {
            script.ReloadTextures();
        }

        if (GUILayout.Button("Show Snow"))
        {
            script.ShowSnow(true);
        }
        if (GUILayout.Button("Hide Snow"))
        {
            script.ShowSnow(false);
        }
    }
}
