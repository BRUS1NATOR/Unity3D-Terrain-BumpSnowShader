using System;
using UnityEngine;

//------------------------------//
//  Footprints.js               //
//  Written by Alucard Jay      //
//  6/19/2013                   //
//------------------------------//
// 2020 Ported to C# by Alexander Bruslenko

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class FootPrints : MonoBehaviour
{
    public int maxFootprints = 128; // Maximum number of footprints total handled by one instance of the script.
    public Vector2 footprintSize = new Vector2(0.2f, 0.5f); // The size of the footprint. Should match the size of the footprint that it is used for. In meters.
    public float footprintSpacing = 0.2f; // the offset for the left or right footprint. In meters.
    public float groundOffset = 0.02f;    // The distance the footprints are places above the surface it is placed upon. In meters.

    public LayerMask terrainLayer; // the layer of the terrain, so the footprint raycast is not hitting the terrain.


    public Mesh mesh;

    public Vector3[] vertices;
    private Vector3[] normals;
    private Vector2[] uvs;
    private int[] triangles;

    public int footprintCount = 0;

    private bool isLeft = true;


    // Initializes the array holding the footprint sections.
    void Awake()
    {
        // - Initialize Arrays -
        vertices = new Vector3[maxFootprints * 4];
        normals = new Vector3[maxFootprints * 4];
        uvs = new Vector2[maxFootprints * 4];
        triangles = new int[maxFootprints * 6];

        // - Initialize Mesh -

        if (GetComponent<MeshFilter>().mesh == null)
        {
            GetComponent<MeshFilter>().mesh = new Mesh();
        }

        mesh = GetComponent<MeshFilter>().mesh;

        mesh.name = "Footprints_Mesh";
    }


    // Function called by the Player when adding a footprint. 
    // Adds the information needed to create the mesh later. 
    public void AddFootprint(Vector3 pos, Vector3 fwd, Vector3 right)
    {
        // - Calculate the 4 corners -

        // foot offset
        float footOffset = footprintSpacing;

        if (isLeft)
        {
            footOffset = -footprintSpacing;
        }

        Vector3[] corners = new Vector3[4];
        pos.y += 1;

        // corners = position + left/right offset + forward + right
        corners[0] = pos + (right * footOffset) + (fwd * footprintSize.y * 0.5f) + (-right * footprintSize.x * 0.5f); // Upper Left
        corners[1] = pos + (right * footOffset) + (fwd * footprintSize.y * 0.5f) + (right * footprintSize.x * 0.5f); // Upper Right
        corners[2] = pos + (right * footOffset) + (-fwd * footprintSize.y * 0.5f) + (-right * footprintSize.x * 0.5f); // Lower Left
        corners[3] = pos + (right * footOffset) + (-fwd * footprintSize.y * 0.5f) + (right * footprintSize.x * 0.5f); // Lower Right


        // raycast to get the position and normal for each corner
        RaycastHit hit;

        for (int i = 0; i < 4; i++)
        {
            Vector3 rayPos = corners[i];
            rayPos.y = pos.y;

            if (Physics.Raycast(rayPos, Vector3.down, out hit, 2.5f,  terrainLayer)) // not terrain!
            {
                int index = (footprintCount * 4) + i;

                // - Vertex -
                hit.normal = new Vector3(0, 1, 0);
                vertices[index] = hit.point + (hit.normal * groundOffset);

                // - Normal -
                normals[index] = hit.normal;
            }
            else
            {
                return;
            }
        }


        // - UVs -

        // what type of footprint is being placed
        Vector2 uvOffset = new Vector2(0, 1.0f);

        // is this the left foot or the right foot
        switch (isLeft)
        {
            case true:
                uvs[(footprintCount * 4) + 0] = new Vector2(uvOffset.x + 0.5f, uvOffset.y);
                uvs[(footprintCount * 4) + 1] = new Vector2(uvOffset.x, uvOffset.y);
                uvs[(footprintCount * 4) + 2] = new Vector2(uvOffset.x + 0.5f, uvOffset.y - 1f);
                uvs[(footprintCount * 4) + 3] = new Vector2(uvOffset.x, uvOffset.y - 1f);

                isLeft = false;
                break;

            default:
                uvs[(footprintCount * 4) + 0] = new Vector2(uvOffset.x, uvOffset.y);
                uvs[(footprintCount * 4) + 1] = new Vector2(uvOffset.x + 0.5f, uvOffset.y);
                uvs[(footprintCount * 4) + 2] = new Vector2(uvOffset.x, uvOffset.y - 1f);
                uvs[(footprintCount * 4) + 3] = new Vector2(uvOffset.x + 0.5f, uvOffset.y - 1f);

                isLeft = true;
                break;
        }



        // - Triangles -

        triangles[(footprintCount * 6) + 0] = (footprintCount * 4) + 0;
        triangles[(footprintCount * 6) + 1] = (footprintCount * 4) + 1;
        triangles[(footprintCount * 6) + 2] = (footprintCount * 4) + 2;

        triangles[(footprintCount * 6) + 3] = (footprintCount * 4) + 2;
        triangles[(footprintCount * 6) + 4] = (footprintCount * 4) + 1;
        triangles[(footprintCount * 6) + 5] = (footprintCount * 4) + 3;


        // - Increment counter -
        footprintCount++;

        if (footprintCount >= maxFootprints)
        {
            footprintCount = 0;
        }

        // - update mesh with new info -
        ConstructMesh();
    }


    void ConstructMesh()
    {
        mesh.Clear();

        mesh.vertices = vertices;
        mesh.normals = normals;
        mesh.triangles = triangles;
        mesh.uv = uvs;
    }
}