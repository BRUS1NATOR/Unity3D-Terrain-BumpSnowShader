using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//------------------------------//
//  Footprints.js               //
//  Written by Alucard Jay      //
//  6/19/2013                   //
//------------------------------//
// 2020 Ported to C# by Alexander Bruslenko

public class PlayerFootPrints : MonoBehaviour
{
    public FootPrints footPrintsPrefab;
    private FootPrints footPrints;

    public float footprintSpacing = 2.0f; // distance between each footprint

    private Vector3 lastPos = Vector3.zero;

    public Rigidbody rb;


    void Start()
    {
        lastPos = transform.position;

        if (footPrintsPrefab != null)
        {
            footPrints = Instantiate(footPrintsPrefab, Vector3.zero, Quaternion.identity, null);
        }
    }


    void FixedUpdate()
    {
        float distFromLastFootprint = (lastPos - transform.position).sqrMagnitude;

        if (distFromLastFootprint > footprintSpacing * footprintSpacing)
        {
            if (rb != null)
            {
                footPrints.AddFootprint(transform.position, transform.forward, transform.right);
            }
            else
            {
                footPrints.AddFootprint(transform.position, transform.forward, transform.right);
            }
            lastPos = transform.position;
        }
    }
}
