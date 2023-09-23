using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.IO;
using System.Collections.Generic;

namespace Atmosphere
{
    class PaintCursor
    {
        GameObject dottedCursorGameObject = null;
        CursorAutoDisable dottedCursorAutoDisable = null;

        Material dottedCursorMaterial;

        GameObject opaqueCursorGameObject = null;
        CursorAutoDisable opaqueCursorAutoDisable = null;

        private static Shader dottedCursorShader;

        private static Shader DottedCursorShader
        {
            get
            {
                if (dottedCursorShader == null) dottedCursorShader = ShaderLoaderClass.FindShader("EVE/PaintCursor");
                return dottedCursorShader;
            }
        }

        public PaintCursor()
        {
            InitGameObjects();
        }

        private void InitGameObjects()
        {
            dottedCursorMaterial = new Material(DottedCursorShader);
            dottedCursorMaterial.SetTexture("_MainTex", GameDatabase.Instance.GetTextureInfo("EnvironmentalVisualEnhancements/PaintCursor")?.texture);
            dottedCursorMaterial.renderQueue = 4000;

            dottedCursorGameObject = GameObject.CreatePrimitive(PrimitiveType.Quad);
            Component.Destroy(dottedCursorGameObject.GetComponent<Collider>());
            dottedCursorGameObject.GetComponent<MeshRenderer>().material = dottedCursorMaterial;
            dottedCursorGameObject.SetActive(false);
            dottedCursorAutoDisable = dottedCursorGameObject.AddComponent<CursorAutoDisable>();

            opaqueCursorGameObject = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            Component.Destroy(opaqueCursorGameObject.GetComponent<Collider>());
            opaqueCursorGameObject.SetActive(false);
            opaqueCursorAutoDisable = opaqueCursorGameObject.AddComponent<CursorAutoDisable>();
        }

        public void SetLayer(int layer)
        {
            if (dottedCursorGameObject == null || opaqueCursorGameObject == null)
            {
                InitGameObjects();
            }

            dottedCursorGameObject.layer = layer;
            opaqueCursorGameObject.layer = layer;
        }

        public void SetDrawSettings(Vector3 cursorPosition, Vector3 upDirection, Vector3 scale, float layerHeight)
        {
            if (dottedCursorGameObject != null)
            {
                Quaternion dottedCursorRotation = Quaternion.LookRotation(upDirection);

                dottedCursorGameObject.SetActive(true);
                dottedCursorGameObject.transform.position = cursorPosition;
                dottedCursorGameObject.transform.rotation = dottedCursorRotation;
                dottedCursorGameObject.transform.localScale = scale;
                dottedCursorAutoDisable.framesSinceEnabled = 0;

                Quaternion opaqueCursorRotation = Quaternion.FromToRotation(Vector3.up, upDirection);

                opaqueCursorGameObject.SetActive(true);
                opaqueCursorGameObject.transform.position = cursorPosition + 0.5f* layerHeight * upDirection;
                opaqueCursorGameObject.transform.rotation = opaqueCursorRotation;
                opaqueCursorGameObject.transform.localScale = new Vector3(scale.x * 0.01f, layerHeight,scale.x * 0.01f);
                opaqueCursorAutoDisable.framesSinceEnabled = 0;
            }
        }

        public void Cleanup()
        {
            if (opaqueCursorGameObject != null) GameObject.DestroyImmediate(opaqueCursorGameObject);
            if (dottedCursorAutoDisable != null) GameObject.DestroyImmediate(dottedCursorAutoDisable);
        }
    }
}
