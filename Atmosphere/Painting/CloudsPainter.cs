﻿using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.Collections.Generic;

namespace Atmosphere
{
    public class CloudsPainter
    {
        CloudsObject cloudsObject;
        CloudsRaymarchedVolume layerRaymarchedVolume;
        string body;
        string layerName;

        public enum EditingMode
        {
            coverageAndCloudType,
            coverage,
            cloudType,
            colorMap
        }

        public EditingMode editingMode = EditingMode.coverage;

        public float brushSize = 5000f;

        public float hardness = 1f;

        public float opacity = 0.05f;

        public float coverageValue = 1f;

        public string selectedCloudTypeName = "";
        public float selectedCloudTypeValue = 0f;

        public Color colorValue = Color.white;

        bool initialized = false;
        List<EditingMode> editingModes = new List<EditingMode>();

        public RenderTexture cloudCoverage, cloudType, cloudColorMap;
        public string cloudCoveragePath, cloudTypePath, cloudColorMapPath;
        Material cloudMaterial, paintMaterial, cursorMaterial;
        Mesh cursorMesh;

        Vector3 lastDrawnMousePos = Vector3.zero;

        private static Shader paintShader;

        private static Shader PaintShader
        {
            get
            {
                if (paintShader == null) paintShader = ShaderLoaderClass.FindShader("EVE/PaintCloudMap");
                return paintShader;
            }
        }

        private static Shader cursorShader;

        private static Shader CursorShader
        {
            get
            {
                if (cursorShader == null) cursorShader = ShaderLoaderClass.FindShader("EVE/PaintCursor");
                return cursorShader;
            }
        }

        public void Init(string body, string layerName)
        {
            cloudsObject = CloudsManager.GetObjectList().Where(x => x.Body == body && x.Name == layerName).FirstOrDefault();
            this.body = body;
            this.layerName = layerName;

            InitTextures();
        }

        public void Init(string body, CloudsObject cloudsObject)
        {
            this.cloudsObject = cloudsObject;
            this.body = body;
            this.layerName = cloudsObject.Name;

            paintMaterial = new Material(PaintShader);

            cursorMaterial = new Material(CursorShader);
            cursorMaterial.SetTexture("_MainTex", GameDatabase.Instance.GetTextureInfo("EnvironmentalVisualEnhancements/PaintCursor")?.texture);
            cursorMaterial.renderQueue = 4000;

            GameObject obj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            cursorMesh = GameObject.Instantiate(obj.GetComponent<MeshFilter>().mesh);
            GameObject.Destroy(obj);

            InitTextures();
        }

        private void InitTextures()
        {
            // only for raymarched volumetrics for now
            // only for equirectangular textures as well

            if (cloudsObject.LayerRaymarchedVolume != null)
            {
                layerRaymarchedVolume = cloudsObject.LayerRaymarchedVolume;

                if (layerRaymarchedVolume.CoverageMap != null)
                {
                    var coverageMapTexture = layerRaymarchedVolume.CoverageMap.GetTexture();

                    // TODO: handle alphamaps as the target here is R8
                    if (coverageMapTexture != null)
                    {
                        InitTexture(ref cloudCoverage, ref coverageMapTexture, RenderTextureFormat.R8);
                    }
                }

                if (layerRaymarchedVolume.CloudTypeMap != null)
                {
                    var cloudTypeTexture = layerRaymarchedVolume.CloudTypeMap.GetTexture();

                    // TODO: handle alphamaps as the target here is R8
                    if (cloudTypeTexture != null)
                    {
                        InitTexture(ref cloudType, ref cloudTypeTexture, RenderTextureFormat.R8);
                    }
                }

                if (layerRaymarchedVolume.CloudColorMap != null)
                {
                    var cloudColorMapTexture = layerRaymarchedVolume.CloudColorMap.GetTexture();

                    // this one shouldn't need alphamaps
                    if (cloudColorMapTexture != null)
                    {
                        InitTexture(ref cloudColorMap, ref cloudColorMapTexture, RenderTextureFormat.ARGB32);
                    }
                }

                SetTextureProperties();

                initialized = true;

            }
        }

        private void SetTextureProperties()
        {
            cloudMaterial = layerRaymarchedVolume.RaymarchedCloudMaterial;

            if (cloudCoverage != null)
            {
                cloudMaterial.SetTexture("CloudCoverage", cloudCoverage);

                // now find other layers which use this for shadows and apply it to them
                var layers = CloudsManager.GetObjectList().Where(x => x.Body == body && x.LayerRaymarchedVolume != null && x.LayerRaymarchedVolume.ReceiveShadowsFromLayer == layerName);

                foreach (var layer in layers)
                {
                    layer.LayerRaymarchedVolume.SetShadowCasterTextureParams(cloudCoverage);
                }
            }

            if (cloudType != null)
                cloudMaterial.SetTexture("CloudType", cloudType);

            if (cloudColorMap != null)
                cloudMaterial.SetTexture("CloudColorMap", cloudColorMap);

            editingModes = new List<EditingMode>();

            if (cloudCoverage != null)
                editingModes.Add(EditingMode.coverage);
            if (cloudType != null)
                editingModes.Add(EditingMode.cloudType);
            if (cloudCoverage != null && cloudType != null)
                editingModes.Add(EditingMode.coverageAndCloudType);
            if (cloudColorMap != null)
                editingModes.Add(EditingMode.colorMap);
        }

        public void Paint()
        {
            if (initialized && HighLogic.LoadedSceneIsFlight && FlightCamera.fetch != null)
            {
                Vector3d sphereCenter = layerRaymarchedVolume.ParentTransform.position;
                Vector3d cameraPos = FlightCamera.fetch.mainCamera.transform.position;

                double sphereRadius = cloudMaterial.GetFloat("innerSphereRadius");

                // Ray ray = FlightCamera.fetch.mainCamera.ScreenPointToRay(Input.mousePosition); // inaccurate due to using the low near plane so calculate it by ourselves
                var viewPortPoint = FlightCamera.fetch.mainCamera.ScreenToViewportPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, -10f));
                viewPortPoint.x = 2.0f * viewPortPoint.x - 1.0f;
                viewPortPoint.x = -viewPortPoint.x;
                viewPortPoint.y = 2.0f * viewPortPoint.y - 1.0f;

                var screenToCamera = GL.GetGPUProjectionMatrix(FlightCamera.fetch.mainCamera.projectionMatrix, true).inverse;
                var cameraSpacePoint = screenToCamera.MultiplyPoint(viewPortPoint);

                Vector3d rayDir = FlightCamera.fetch.mainCamera.transform.TransformDirection(cameraSpacePoint.normalized);

                double intersectDistance = IntersectSphere(cameraPos, rayDir, sphereCenter, sphereRadius);

                if (intersectDistance < 0f)
                {
                    sphereRadius = cloudMaterial.GetFloat("outerSphereRadius");
                    intersectDistance = IntersectSphere(cameraPos, rayDir, sphereCenter, sphereRadius);
                }

                if (intersectDistance > 0f)
                {
                    Vector3d intersectPosition = cameraPos + rayDir * intersectDistance;

                    Quaternion rotation = Quaternion.LookRotation(Vector3.Normalize(intersectPosition - sphereCenter));
                    Vector3 scale = new Vector3(brushSize * 2f, brushSize * 2f, brushSize * 2f);
                    Matrix4x4 matrix = Matrix4x4.TRS(intersectPosition, rotation, scale);
                    Graphics.DrawMesh(cursorMesh, matrix, cursorMaterial, 0, FlightCamera.fetch.mainCamera);

                    if (Input.GetMouseButton(0) && Input.mousePosition.x != lastDrawnMousePos.x && Input.mousePosition.y != lastDrawnMousePos.y)
                    {
                        lastDrawnMousePos = Input.mousePosition;

                        // feed all info to the shader
                        paintMaterial.SetVector("brushPosition", (Vector3)intersectPosition);
                        paintMaterial.SetFloat("brushSize", brushSize);
                        paintMaterial.SetFloat("hardness", hardness);
                        //paintMaterial.SetFloat("opacity", opacity * Time.deltaTime * 5f);
                        paintMaterial.SetFloat("opacity", opacity);

                        paintMaterial.SetFloat("innerSphereRadius", (float)sphereRadius);
                        paintMaterial.SetMatrix("cloudRotationMatrix", layerRaymarchedVolume.CloudRotationMatrix);

                        if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
                        {
                            paintMaterial.SetVector("paintValue", new Vector3(coverageValue, coverageValue, coverageValue));
                            Graphics.Blit(null, cloudCoverage, paintMaterial);
                        }
                        if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
                        {
                            paintMaterial.SetVector("paintValue", new Vector3(selectedCloudTypeValue, selectedCloudTypeValue, selectedCloudTypeValue));
                            Graphics.Blit(null, cloudType, paintMaterial);
                        }
                        if (editingMode == EditingMode.colorMap)
                        {
                            paintMaterial.SetColor("paintValue", colorValue);
                            Graphics.Blit(null, cloudColorMap, paintMaterial);
                        }
                    }
                }
            }
        }

        public void RetargetClouds()
        {
            cloudsObject = CloudsManager.GetObjectList().Where(x => x.Body == body && x.Name == layerName).FirstOrDefault();
            layerRaymarchedVolume = cloudsObject?.LayerRaymarchedVolume;

            if (cloudsObject != null && layerRaymarchedVolume != null)
                SetTextureProperties();
        }

        // TODO: handle alphamaps
        private void InitTexture(ref RenderTexture targetRT, ref Texture2D targetTexture2D, RenderTextureFormat format)
        {
            if (targetRT != null)
                targetRT.Release();

            targetRT = new RenderTexture(targetTexture2D.width, targetTexture2D.height, 0, format);
            targetRT.filterMode = FilterMode.Bilinear;
            targetRT.wrapMode = TextureWrapMode.Repeat;
            targetRT.Create();

            Graphics.Blit(targetTexture2D, targetRT);
        }

        private double IntersectSphere(Vector3d origin, Vector3d d, Vector3d sphereCenter, double r)
        {
            double a = Vector3d.Dot(d, d);
            double b = 2.0 * Vector3d.Dot(d, origin - sphereCenter);
            double c = Vector3d.Dot(sphereCenter, sphereCenter) + Vector3d.Dot(origin, origin) - 2.0 * Vector3d.Dot(sphereCenter, origin) - r * r;

            double test = b * b - 4.0 * a * c;

            if (test < 0)
            {
                return -1.0;
            }

            double u = (-b - Math.Sqrt(test)) / (2.0 * a);

            u = (u < 0) ? (-b + Math.Sqrt(test)) / (2.0 * a) : u;

            return u;
        }

        public void DrawGUI(Rect placementBase, ref Rect placement)
        {
            // TODO: add button to unload
            placement.height = 1;

            Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);
            GUI.Label(labelRect, "Editing mode");
            placement.y += 1;

            editingMode = GUIHelper.DrawSelector<EditingMode>(editingModes, editingMode, 4, placementBase, ref placement);
            placement.y += 1;

            DrawFloatField(placementBase, ref placement, "Brush size", ref brushSize, null);
            DrawFloatField(placementBase, ref placement, "Brush hardness", ref hardness, 1f, "0.00");
            DrawFloatField(placementBase, ref placement, "Brush opacity", ref opacity, 1f, "0.00");

            if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
            {
                DrawFloatField(placementBase, ref placement, "Coverage value", ref coverageValue, 1f, "0.00");
            }
            if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
            {
                var cloudTypeList = layerRaymarchedVolume.CloudTypes.Select(x => x.TypeName).ToList();
                int selectedIndex = cloudTypeList.IndexOf(selectedCloudTypeName);
                selectedIndex = selectedIndex < 0 ? 0 : selectedIndex;

                selectedCloudTypeName = GUIHelper.DrawSelector<String>(cloudTypeList, ref selectedIndex, 4, placementBase, ref placement);
                if (cloudTypeList.Count >= 2)
                    selectedCloudTypeValue = (float)selectedIndex / ((float)cloudTypeList.Count - 1f);
            }
            else if (editingMode == EditingMode.colorMap)
            {
                DrawColorField(placementBase, ref placement, "Color ", ref colorValue);
            }

            if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Reset current mode textures"))
            {
                ResetCurrentTextures();
            }
            placement.y += 1;

            if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Reset all textures"))
            {
                InitTextures();
            }
            placement.y += 1;

            if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Save current mode textures"))
            {
                SaveCurrentTextures();
            }
            placement.y += 1;

            if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Save all textures"))
            {
                SaveAllTextures();
            }
            placement.y += 1;
        }

        private void ResetCurrentTextures()
        {
            if (editingMode == EditingMode.coverage)
            {
                var coverageMapTexture = layerRaymarchedVolume.CoverageMap.GetTexture();

                // TODO: handle alphamaps as the target here is R8
                if (coverageMapTexture != null)
                {
                    InitTexture(ref cloudCoverage, ref coverageMapTexture, RenderTextureFormat.R8);
                }
            }
            else if (editingMode == EditingMode.cloudType)
            {
                var cloudTypeTexture = layerRaymarchedVolume.CloudTypeMap.GetTexture();

                // TODO: handle alphamaps as the target here is R8
                if (cloudTypeTexture != null)
                {
                    InitTexture(ref cloudType, ref cloudTypeTexture, RenderTextureFormat.R8);
                }
            }
            else if (editingMode == EditingMode.coverageAndCloudType)
            {
                var cloudTypeTexture = layerRaymarchedVolume.CloudTypeMap.GetTexture();
                var coverageMapTexture = layerRaymarchedVolume.CoverageMap.GetTexture();

                // TODO: handle alphamaps as the target here is R8
                if (coverageMapTexture != null && cloudTypeTexture != null)
                {
                    InitTexture(ref cloudCoverage, ref coverageMapTexture, RenderTextureFormat.R8);
                    InitTexture(ref cloudType, ref cloudTypeTexture, RenderTextureFormat.R8);
                }
            }
            else if (editingMode == EditingMode.colorMap)
            {
                var cloudColorMapTexture = layerRaymarchedVolume.CloudColorMap.GetTexture();

                if (cloudColorMapTexture != null)
                {
                    InitTexture(ref cloudColorMap, ref cloudColorMapTexture, RenderTextureFormat.ARGB32);
                }
            }

            SetTextureProperties();
        }

        private void SaveCurrentTextures()
        {
            if (editingMode == EditingMode.coverage && cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, layerRaymarchedVolume.CoverageMap.Name);
            }
            else if (editingMode == EditingMode.cloudType && cloudType != null)
            {
                SaveRTToFile(cloudType, layerRaymarchedVolume.CloudTypeMap.Name);
            }
            else if (editingMode == EditingMode.coverageAndCloudType && cloudType != null && cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, layerRaymarchedVolume.CoverageMap.Name);
                SaveRTToFile(cloudType, layerRaymarchedVolume.CloudTypeMap.Name);
            }
            else if (editingMode == EditingMode.colorMap && cloudColorMap != null)
            {
                SaveRTToFile(cloudColorMap, layerRaymarchedVolume.CloudColorMap.Name);
            }
        }

        private void SaveAllTextures()
        {
            if (cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, layerRaymarchedVolume.CoverageMap.Name);
            }
            if (cloudType != null)
            {
                SaveRTToFile(cloudType, layerRaymarchedVolume.CloudTypeMap.Name);
            }
            if (cloudColorMap != null)
            {
                SaveRTToFile(cloudColorMap, layerRaymarchedVolume.CloudColorMap.Name);
            }
        }

        private void DrawFloatField(Rect placementBase, ref Rect placement, string name, ref float field, float? maxValue, string format = null)
        {
            Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect fieldRect = GUIHelper.GetRect(placementBase, ref placement);
            GUIHelper.SplitRect(ref labelRect, ref fieldRect, GUIHelper.valueRatio);

            GUI.Label(labelRect, name);

            if (!string.IsNullOrEmpty(format))
                field = float.Parse(GUI.TextField(fieldRect, field.ToString(format)));
            else
                field = float.Parse(GUI.TextField(fieldRect, field.ToString()));

            if (maxValue.HasValue)
                field = Mathf.Clamp(field, 0f, maxValue.Value);
            placement.y += 1;
        }

        private void DrawColorField(Rect placementBase, ref Rect placement, string name, ref Color field)
        {
            Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);

            Rect fieldRect = GUIHelper.GetRect(placementBase, ref placement);
            GUIHelper.SplitRect(ref labelRect, ref fieldRect, GUIHelper.valueRatio);

            Rect labelRectR = fieldRect;
            Rect labelRectG = fieldRect;
            Rect labelRectB = fieldRect;

            GUIHelper.SplitRect(ref labelRectR, ref labelRectG, 1f/3f);
            GUIHelper.SplitRect(ref labelRectG, ref labelRectB, 1f/2f);

            GUI.Label(labelRect, name);

            field.r = float.Parse(GUI.TextField(labelRectR, field.r.ToString("0.00")));
            field.g = float.Parse(GUI.TextField(labelRectG, field.g.ToString("0.00")));
            field.b = float.Parse(GUI.TextField(labelRectB, field.b.ToString("0.00")));

            placement.y += 1;
        }

        private void SaveRTToFile(RenderTexture rt, string name)
        {
            RenderTexture.active = rt;

            Texture2D tex = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            RenderTexture.active = null;

            if (rt.format == RenderTextureFormat.R8)
            {
                var pixels = tex.GetPixels();

                for (int i = 0; i < pixels.Length; i++)
                {
                    pixels[i].g = pixels[i].r;
                    pixels[i].b = pixels[i].r;
                    pixels[i].a = pixels[i].r;
                }

                tex.SetPixels(pixels);
                tex.Apply();
            }

            byte[] bytes;
            bytes = tex.EncodeToPNG();

            string datetime = DateTime.Now.ToString("yyyy-MM-dd\\THH-mm-ss\\Z");

            string path = System.IO.Path.Combine("GameData", name + datetime + ".png");
            System.IO.File.WriteAllBytes(path, bytes);
            Debug.Log("Saved to " + path);
        }
    }
}