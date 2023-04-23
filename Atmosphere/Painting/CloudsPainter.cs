﻿using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.IO;
using System.Collections.Generic;

namespace Atmosphere
{
    public class CloudsPainter
    {
        CloudsObject cloudsObject;
        CloudsRaymarchedVolume layerRaymarchedVolume;
        Clouds2D layer2D;
        string body;
        string layerName;

        GameObject cursorGameObject = null;
        CursorAutoDisable cursorAutoDisable = null;

        public enum EditingMode
        {
            coverageAndCloudType,
            coverage,
            cloudType,
            colorMap,
            flowMapDirectional,
            flowMapVortex,
            flowMapBand,
            scaledFlowMapDirectional,
            scaledFlowMapVortex,
            scaledFlowMapBand
        }

        public enum RotationDirection
        {
            ClockWise,
            CounterClockWise
        }

        public EditingMode editingMode = EditingMode.coverage;

        public float brushSize = 5000f;
        public float hardness = 1f;
        public float opacity = 0.05f;
        public float coverageValue = 1f;

        public string selectedCloudTypeName = "";
        public float selectedCloudTypeValue = 0f;

        public float flowValue = 1f;
        public float upwardsFlowValue = 0f;

        Vector3d lastIntersectPosition = Vector3d.zero;

        public RotationDirection rotationDirection = RotationDirection.ClockWise;

        public Color colorValue = Color.white;

        bool initialized = false;
        bool paintEnabled = true;
        List<EditingMode> editingModes = new List<EditingMode>();

        public RenderTexture cloudCoverage, cloudType, cloudColorMap, cloudFlowMap, cloudScaledFlowMap;
        Material cloudMaterial, scaledCloudMaterial, paintMaterial, cursorMaterial;

        Transform scaledTransform;

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

        private static Shader copyMapShader;

        private static Shader CopyMapShader
        {
            get
            {
                if (copyMapShader == null) copyMapShader = ShaderLoaderClass.FindShader("EVE/CopyMap");
                return copyMapShader;
            }
        }

        public void Init(string body, CloudsObject cloudsObject)
        {
            this.cloudsObject = cloudsObject;
            this.body = body;
            this.layerName = cloudsObject.Name;
            scaledTransform = Tools.GetScaledTransform(body);

            paintMaterial = new Material(PaintShader);

            cursorMaterial = new Material(CursorShader);
            cursorMaterial.SetTexture("_MainTex", GameDatabase.Instance.GetTextureInfo("EnvironmentalVisualEnhancements/PaintCursor")?.texture);
            cursorMaterial.renderQueue = 4000;

            cursorGameObject = GameObject.CreatePrimitive(PrimitiveType.Quad);
            Component.Destroy(cursorGameObject.GetComponent<Collider>());

            cursorGameObject.GetComponent<MeshRenderer>().material = cursorMaterial;
            cursorGameObject.SetActive(false);

            cursorAutoDisable = cursorGameObject.AddComponent<CursorAutoDisable>();

            InitTextures();
        }

        private void InitTextures()
        {
            // only for equirectangular textures for now
            if (cloudsObject.LayerRaymarchedVolume != null)
            {
                layerRaymarchedVolume = cloudsObject.LayerRaymarchedVolume;

                if (layerRaymarchedVolume.CoverageMap != null)   InitTexture(layerRaymarchedVolume.CoverageMap, ref cloudCoverage, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudTypeMap != null)  InitTexture(layerRaymarchedVolume.CloudTypeMap, ref cloudType, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudColorMap != null) InitTexture(layerRaymarchedVolume.CloudColorMap, ref cloudColorMap, RenderTextureFormat.ARGB32);
                if (layerRaymarchedVolume.FlowMap != null && layerRaymarchedVolume.FlowMap.Texture != null)       InitTexture(layerRaymarchedVolume.FlowMap.Texture, ref cloudFlowMap, RenderTextureFormat.ARGB32);

                layer2D = cloudsObject.Layer2D;

                if (layer2D.CloudsMat.FlowMap != null && layer2D.CloudsMat.FlowMap.Texture != null) InitTexture(layer2D.CloudsMat.FlowMap.Texture, ref cloudScaledFlowMap, RenderTextureFormat.ARGB32);

                SetTextureProperties();

                initialized = true;
            }
        }

        private void SetTextureProperties()
        {
            cloudMaterial = layerRaymarchedVolume.RaymarchedCloudMaterial;

            if (cloudCoverage != null)
            {
                cloudMaterial.EnableKeyword("ALPHAMAP_1");
                cloudMaterial.SetVector("alphaMask1", new Vector4(1f, 0f, 0f, 0f));
                cloudMaterial.SetFloat("useAlphaMask1", 1f);
                cloudMaterial.SetTexture("CloudCoverage", cloudCoverage);

                // find other layers which use this for shadows and apply it to them
                var layers = CloudsManager.GetObjectList().Where(x => x.Body == body && x.LayerRaymarchedVolume != null && x.LayerRaymarchedVolume.ReceiveShadowsFromLayer == layerName);

                foreach (var layer in layers)
                {
                    layer.LayerRaymarchedVolume.SetShadowCasterTextureParams(cloudCoverage, true);
                }
            }

            if (cloudType != null)
            {
                cloudMaterial.EnableKeyword("ALPHAMAP_2");
                cloudMaterial.SetVector("alphaMask2", new Vector4(1f, 0f, 0f, 0f));
                cloudMaterial.SetFloat("useAlphaMask2", 1f);
                cloudMaterial.SetTexture("CloudType", cloudType);
            }
            if (cloudColorMap != null) cloudMaterial.SetTexture("CloudColorMap", cloudColorMap);

            if (cloudFlowMap != null) cloudMaterial.SetTexture("_FlowMap", cloudFlowMap);

            scaledCloudMaterial = layer2D?.CloudRenderingMaterial;

            if (scaledCloudMaterial != null && cloudScaledFlowMap != null)
            {
                scaledCloudMaterial.SetTexture("_FlowMap", cloudScaledFlowMap);
            }

            editingModes = new List<EditingMode>();

            if (cloudCoverage != null)
                editingModes.Add(EditingMode.coverage);

            if (cloudType != null)
                editingModes.Add(EditingMode.cloudType);

            if (cloudCoverage != null && cloudType != null)
                editingModes.Add(EditingMode.coverageAndCloudType);

            if (cloudColorMap != null)
                editingModes.Add(EditingMode.colorMap);

            if (cloudFlowMap != null)
            {
                editingModes.Add(EditingMode.flowMapDirectional);
                editingModes.Add(EditingMode.flowMapVortex);
                editingModes.Add(EditingMode.flowMapBand);
            }

            if (cloudScaledFlowMap != null)
            {
                editingModes.Add(EditingMode.scaledFlowMapDirectional);
                editingModes.Add(EditingMode.scaledFlowMapVortex);
                editingModes.Add(EditingMode.scaledFlowMapBand);
            }
        }

        private void InitTexture(TextureWrapper targetWrapper, ref RenderTexture targetRT, RenderTextureFormat format)
        {
            var targetTexture = targetWrapper.GetTexture();

            if (targetTexture != null)
            {
                if (targetRT != null)
                    targetRT.Release();

                targetRT = new RenderTexture(targetTexture.width, targetTexture.height, 0, format);
                targetRT.filterMode = FilterMode.Bilinear;
                targetRT.wrapMode = TextureWrapMode.Repeat;
                targetRT.Create();

                var active = RenderTexture.active;

                var copyMapMaterial = new Material(CopyMapShader);

                targetWrapper.SetAlphaMask(copyMapMaterial, 1);
                copyMapMaterial.SetTexture("textureToCopy", targetTexture);
                Graphics.Blit(null, targetRT, copyMapMaterial);

                RenderTexture.active = active;
            }
        }

        public void Paint()
        {
            if (initialized && paintEnabled && HighLogic.LoadedSceneIsFlight && FlightCamera.fetch != null)
            {
                Vector3d sphereCenter = ScaledSpace.ScaledToLocalSpace(scaledTransform.position);

                var planetRadius = cloudMaterial.GetFloat("planetRadius");
                // TODO: maybe detect if planet has ocean to do this
                float innerSphereRadius = Mathf.Max(planetRadius, cloudMaterial.GetFloat("innerSphereRadius"));
                float outerSphereRadius = Mathf.Max(planetRadius, cloudMaterial.GetFloat("outerSphereRadius"));
                double sphereRadius = innerSphereRadius;

                Vector3d rayDir = Vector3d.one;
                Vector3d cameraPos = Vector3d.zero;

                if (!MapView.MapIsEnabled)
                { 
                    rayDir = GetCursorRayDirection(FlightCamera.fetch.mainCamera);
                    cameraPos = FlightCamera.fetch.mainCamera.transform.position;
                }
                else
                {
                    rayDir = GetCursorRayDirection(ScaledCamera.Instance.cam);
                    cameraPos = ScaledSpace.ScaledToLocalSpace(ScaledCamera.Instance.cam.transform.position);
                }

                double intersectDistance = Mathf.Infinity;

                if (!MapView.MapIsEnabled)
                {
                    intersectDistance = RefineCursorPositionWithRaycast(sphereCenter, innerSphereRadius, outerSphereRadius, rayDir, cameraPos, intersectDistance);
                }

                intersectDistance = Math.Min(intersectDistance, IntersectSphere(cameraPos, rayDir, sphereCenter, innerSphereRadius));

                if (intersectDistance == Mathf.Infinity)
                {
                    intersectDistance = IntersectSphere(cameraPos, rayDir, sphereCenter, outerSphereRadius);
                }

                if (intersectDistance != Mathf.Infinity)
                {
                    Vector3d intersectPosition = cameraPos + rayDir * intersectDistance;

                    Vector3 cursorPosition = intersectPosition;
                    Vector3 upDirection = Vector3.Normalize(intersectPosition - sphereCenter);
                    Quaternion rotation = Quaternion.LookRotation(upDirection);
                    Vector3 scale = new Vector3(brushSize * 2f, brushSize * 2f, brushSize * 2f);
                    cursorGameObject.layer = (int)Tools.Layer.Default;

                    if (MapView.MapIsEnabled)
                    {
                        cursorPosition = ScaledSpace.LocalToScaledSpace(intersectPosition);
                        scale = scale * (1f / 6000f);
                        cursorGameObject.layer = (int)Tools.Layer.Scaled;
                    }

                    if (cursorGameObject != null)
                    {
                        cursorGameObject.SetActive(true);
                        cursorGameObject.transform.position = cursorPosition;
                        cursorGameObject.transform.rotation = rotation;
                        cursorGameObject.transform.localScale = scale;
                        cursorAutoDisable.framesSinceEnabled = 0;
                    }

                    if (Input.GetMouseButton(0) && Input.mousePosition.x != lastDrawnMousePos.x && Input.mousePosition.y != lastDrawnMousePos.y)
                    {
                        lastDrawnMousePos = Input.mousePosition;

                        PaintCurrentMode(intersectPosition, sphereRadius);
                    }

                    if (scaledCloudMaterial != null && cloudScaledFlowMap != null)
                    {
                        scaledCloudMaterial.SetTexture("_FlowMap", cloudScaledFlowMap);
                    }

                    lastIntersectPosition = intersectPosition;
                }
            }
        }

        private static double RefineCursorPositionWithRaycast(Vector3d sphereCenter, float innerSphereRadius, float outerSphereRadius, Vector3d rayDir, Vector3d cameraPos, double intersectDistance)
        {
            RaycastHit hit;
            var hitStatus = Physics.Raycast(cameraPos, rayDir, out hit, Mathf.Infinity, (int)((1 << 15) + (1 << 0)));

            if (hitStatus)
            {
                var hitAltitude = (hit.point - sphereCenter).magnitude;
                if (hitAltitude <= outerSphereRadius && hitAltitude >= innerSphereRadius)
                {
                    var hitDistance = (hit.point - cameraPos).magnitude;
                    intersectDistance = Math.Min(hitDistance, hitDistance);
                }
            }

            return intersectDistance;
        }

        private void PaintCurrentMode(Vector3d intersectPosition, double sphereRadius)
        {
            var cloudRotationMatrix = layer2D != null ? layer2D.MainRotationMatrix * layerRaymarchedVolume.ParentTransform.worldToLocalMatrix : layerRaymarchedVolume.CloudRotationMatrix;

            // feed all info to the shader
            paintMaterial.SetVector("brushPosition", (Vector3)intersectPosition);
            paintMaterial.SetFloat("brushSize", brushSize);
            paintMaterial.SetFloat("hardness", hardness);
            paintMaterial.SetFloat("opacity", opacity);

            paintMaterial.SetFloat("innerSphereRadius", (float) sphereRadius);
            paintMaterial.SetMatrix("cloudRotationMatrix", cloudRotationMatrix);

            var active = RenderTexture.active;

            if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
            {
                paintMaterial.SetVector("paintValue", new Vector3(coverageValue, coverageValue, coverageValue));
                Graphics.Blit(null, cloudCoverage, paintMaterial, 0);
            }
            if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
            {
                paintMaterial.SetVector("paintValue", new Vector3(selectedCloudTypeValue, selectedCloudTypeValue, selectedCloudTypeValue));
                Graphics.Blit(null, cloudType, paintMaterial, 0);
            }
            if (editingMode == EditingMode.colorMap)
            {
                paintMaterial.SetColor("paintValue", colorValue);
                Graphics.Blit(null, cloudColorMap, paintMaterial, 0);
            }
            if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.scaledFlowMapDirectional)
            {
                Vector3 cloudSpaceIntersectPosition = cloudRotationMatrix.MultiplyPoint(intersectPosition);
                Vector3 cloudSpaceLastIntersectPosition = cloudRotationMatrix.MultiplyPoint(lastIntersectPosition);

                Vector3 cloudSpaceFlowDirection = (cloudSpaceLastIntersectPosition - cloudSpaceIntersectPosition).normalized;

                Vector3 normal = cloudSpaceIntersectPosition.normalized;

                Vector3 tangent;
                Vector3 biTangent;
                if (Math.Abs(normal.x) > 0.001f)
                {
                    tangent = Vector3.Cross(new Vector3(0f, 1f, 0f), normal).normalized;
                }
                else
                {
                    tangent = Vector3.Cross(new Vector3(1f, 0f, 0f), normal).normalized;
                }
                biTangent = Vector3.Cross(normal, tangent);
                tangent *= -1f;

                Vector2 tangentOnlyFlow = new Vector2(Vector3.Dot(cloudSpaceFlowDirection, tangent), Vector3.Dot(cloudSpaceFlowDirection, biTangent)).normalized;

                Vector3 tangentSpaceFlow = new Vector3(tangentOnlyFlow.x * flowValue * 0.5f + 0.5f,
                                                        tangentOnlyFlow.y * flowValue * 0.5f + 0.5f,
                                                        upwardsFlowValue * 0.5f + 0.5f);

                paintMaterial.SetVector("paintValue", tangentSpaceFlow);
                Graphics.Blit(null, editingMode == EditingMode.flowMapDirectional ? cloudFlowMap : cloudScaledFlowMap, paintMaterial, 0);
            }
            if (editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.scaledFlowMapVortex)
            {
                paintMaterial.SetFloat("flowValue", flowValue);
                paintMaterial.SetFloat("upwardsFlowValue", upwardsFlowValue);
                paintMaterial.SetFloat("clockWiseRotation", rotationDirection == RotationDirection.ClockWise ? 1f : 0f);
                Graphics.Blit(null, editingMode == EditingMode.flowMapVortex ? cloudFlowMap : cloudScaledFlowMap, paintMaterial, 1);
            }

            RenderTexture.active = active;
        }

        public void RetargetClouds()
        {
            cloudsObject = CloudsManager.GetObjectList().Where(x => x.Body == body && x.Name == layerName).FirstOrDefault();
            layerRaymarchedVolume = cloudsObject?.LayerRaymarchedVolume;
            layer2D = cloudsObject?.Layer2D;

            if (cloudsObject != null && layerRaymarchedVolume != null)
                SetTextureProperties();
        }

        private static Vector3d GetCursorRayDirection(Camera cam)
        {
            // this code is very bad but the built-in Unity ScreenPointToRay jitters
            var viewPortPoint = cam.ScreenToViewportPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, Tools.IsUnifiedCameraMode() ? -10f : 10f));
            viewPortPoint.x = 2.0f * viewPortPoint.x - 1.0f;
            viewPortPoint.x = -viewPortPoint.x;
            viewPortPoint.y = 2.0f * viewPortPoint.y - 1.0f;

            var screenToCamera = GL.GetGPUProjectionMatrix(cam.projectionMatrix, true).inverse;
            var cameraSpacePoint = screenToCamera.MultiplyPoint(viewPortPoint);

            var cameraSpacePointNormalized = cameraSpacePoint.normalized;
            cameraSpacePointNormalized.y = Tools.IsUnifiedCameraMode() ? cameraSpacePointNormalized.y : -cameraSpacePointNormalized.y;

            Vector3d rayDir = cam.transform.TransformDirection(cameraSpacePointNormalized);
            return rayDir;
        }

        private double IntersectSphere(Vector3d origin, Vector3d d, Vector3d sphereCenter, double r)
        {
            double a = Vector3d.Dot(d, d);
            double b = 2.0 * Vector3d.Dot(d, origin - sphereCenter);
            double c = Vector3d.Dot(sphereCenter, sphereCenter) + Vector3d.Dot(origin, origin) - 2.0 * Vector3d.Dot(sphereCenter, origin) - r * r;

            double test = b * b - 4.0 * a * c;

            if (test < 0)
            {
                return Mathf.Infinity;
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

            DrawFloatField(placementBase, ref placement, "Brush size", ref brushSize, 0f);
            DrawFloatField(placementBase, ref placement, "Brush hardness", ref hardness, 0f, 1f, "0.00");
            DrawFloatField(placementBase, ref placement, "Brush opacity", ref opacity, 0f, 1f, "0.00");

            if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
            {
                DrawFloatField(placementBase, ref placement, "Coverage value", ref coverageValue, 0f, 1f, "0.00");
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
            else if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.scaledFlowMapDirectional)
            {
                DrawFloatField(placementBase, ref placement, "Flow ", ref flowValue, -1f, 1f, "0.00");
                DrawFloatField(placementBase, ref placement, "Upwards flow ", ref upwardsFlowValue, -1f, 1f, "0.00");
            }
            else if (editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.scaledFlowMapVortex)
            {
                DrawFloatField(placementBase, ref placement, "Flow ", ref flowValue, -1f, 1f, "0.00");
                DrawFloatField(placementBase, ref placement, "Upwards flow ", ref upwardsFlowValue, -1f, 1f, "0.00");
                rotationDirection = GUIHelper.DrawSelector(Enum.GetValues(typeof(RotationDirection)).Cast<RotationDirection>().ToList(), rotationDirection, 4, placementBase, ref placement);
            }

            paintEnabled = GUI.Toggle(GUIHelper.GetRect(placementBase, ref placement), paintEnabled, "Enable painting");
            placement.y += 1;

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
                InitTexture(layerRaymarchedVolume.CoverageMap, ref cloudCoverage, RenderTextureFormat.R8);
            }
            else if (editingMode == EditingMode.cloudType)
            {
                InitTexture(layerRaymarchedVolume.CloudTypeMap, ref cloudType, RenderTextureFormat.R8);
            }
            else if (editingMode == EditingMode.coverageAndCloudType)
            {
                var cloudTypeTexture = layerRaymarchedVolume.CloudTypeMap.GetTexture();
                var coverageMapTexture = layerRaymarchedVolume.CoverageMap.GetTexture();

                if (coverageMapTexture != null && cloudTypeTexture != null)
                {
                    InitTexture(layerRaymarchedVolume.CoverageMap, ref cloudCoverage, RenderTextureFormat.R8);
                    InitTexture(layerRaymarchedVolume.CloudTypeMap, ref cloudType, RenderTextureFormat.R8);
                }
            }
            else if (editingMode == EditingMode.colorMap)
            {
                InitTexture(layerRaymarchedVolume.CloudColorMap, ref cloudColorMap, RenderTextureFormat.ARGB32);
            }
            else if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.flowMapVortex)
            {
                InitTexture(layerRaymarchedVolume.FlowMap.Texture, ref cloudFlowMap, RenderTextureFormat.ARGB32);
            }

            SetTextureProperties();
        }

        private void SaveCurrentTextures()
        {
            if (editingMode == EditingMode.coverage && cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, "CloudCoverage");
            }
            else if (editingMode == EditingMode.cloudType && cloudType != null)
            {
                SaveRTToFile(cloudType, "CloudType");
            }
            else if (editingMode == EditingMode.coverageAndCloudType && cloudType != null && cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, "CloudCoverage");
                SaveRTToFile(cloudType, "CloudType");
            }
            else if (editingMode == EditingMode.colorMap && cloudColorMap != null)
            {
                SaveRTToFile(cloudColorMap, "CloudColor");
            }
            else if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.flowMapBand)
            {
                SaveRTToFile(cloudFlowMap, "CloudFlowMap");
            }
            else if (editingMode == EditingMode.scaledFlowMapDirectional || editingMode == EditingMode.scaledFlowMapVortex || editingMode == EditingMode.scaledFlowMapBand)
            {
                SaveRTToFile(cloudScaledFlowMap, "CloudScaledFlowMap");
            }
        }

        private void SaveAllTextures()
        {
            if (cloudCoverage != null)
            {
                SaveRTToFile(cloudCoverage, "CloudCoverage");
            }
            if (cloudType != null)
            {
                SaveRTToFile(cloudType, "CloudType");
            }
            if (cloudColorMap != null)
            {
                SaveRTToFile(cloudColorMap, "ColorMap");
            }
            if (cloudFlowMap != null)
            {
                SaveRTToFile(cloudFlowMap, "CloudFlowMap");
            }
            if(cloudScaledFlowMap != null)
            {
                SaveRTToFile(cloudScaledFlowMap, "CloudScaledFlowMap");
            }
        }

        private void DrawFloatField(Rect placementBase, ref Rect placement, string name, ref float field, float? minValue = null, float? maxValue = null, string format = null)
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
                field = Mathf.Min(maxValue.Value, field);

            if (minValue.HasValue)
                field = Mathf.Max(minValue.Value, field);

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

        private void SaveRTToFile(RenderTexture rt, string mapType)
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

            string path = System.IO.Path.Combine("GameData","EVETextureExports", body);

            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);

            path = System.IO.Path.Combine(path, layerName + "_" + mapType + "_" + datetime + ".png");

            System.IO.File.WriteAllBytes(path, bytes);
            Debug.Log("Saved to " + path);
        }
    }

    public class CursorAutoDisable : MonoBehaviour
    {
        public int framesSinceEnabled = 0;

        public void Update()
        {
            framesSinceEnabled++;
            if (framesSinceEnabled > 10)
                gameObject.SetActive(false);
        }
    }
}