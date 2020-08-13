using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;

namespace Utils
{
    public class ScreenSpaceShadow : MonoBehaviour
    {
        public Material material;

        public void Init()
        {
            Quad.Create(gameObject, 2, Color.white, Vector3.up, Mathf.Infinity);

            MeshRenderer shadowMR = gameObject.AddComponent<MeshRenderer>();
            material.SetOverrideTag("IgnoreProjector", "True");
            shadowMR.sharedMaterial = material;

            shadowMR.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            shadowMR.receiveShadows = false;
            shadowMR.enabled = true;

            gameObject.layer = (int)Tools.Layer.Local;

        }

        void OnWillRenderObject()
        {
            if (material != null)
            {
                material.SetMatrix("CameraToWorld", Camera.current.cameraToWorldMatrix);
            }
        }
    }
}
