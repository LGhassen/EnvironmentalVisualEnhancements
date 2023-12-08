using UnityEngine;
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

        PaintCursor paintCursor;

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
        public float hardness = 0f;
        public float opacity = 0.05f;
        public float coverageValue = 1f;

        public string selectedCloudTypeName = "";
        public float selectedCloudTypeValue = 0f;

        public float flowValue = 1f;
        public float upwardsFlowValue = 0f;

        Vector3d lastIntersectPosition = Vector3d.zero;

        public RotationDirection vortexRotationDirection = RotationDirection.ClockWise;
        public RotationDirection bandRotationDirection  = RotationDirection.ClockWise;

        public Color colorValue = Color.white;

        bool initialized = false;
        bool paintEnabled = true;
        List<EditingMode> editingModes = new List<EditingMode>();

        public RenderTexture cloudCoverage, cloudType, cloudColorMap, cloudFlowMap, cloudScaledFlowMap;
        Material cloudMaterial, scaledCloudMaterial, paintMaterial;

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

        private static Shader copyMapShader;

        private static Shader CopyMapShader
        {
            get
            {
                if (copyMapShader == null) copyMapShader = ShaderLoaderClass.FindShader("EVE/CopyMap");
                return copyMapShader;
            }
        }

        public bool Init(string body, CloudsObject cloudsObject)
        {
            this.cloudsObject = cloudsObject;
            this.body = body;
            this.layerName = cloudsObject.Name;
            scaledTransform = Tools.GetScaledTransform(body);

            paintMaterial = new Material(PaintShader);

            paintCursor = new PaintCursor();

            return InitTextures();
        }

        public void Unload()
        {
            if (cloudCoverage != null) cloudCoverage.Release();
            if (cloudType != null) cloudType.Release();
            if (cloudColorMap != null) cloudColorMap.Release();
            if (cloudFlowMap != null) cloudFlowMap.Release();

            if (cloudScaledFlowMap != null) cloudScaledFlowMap.Release();

            if (paintCursor != null)
            {
                paintCursor.Cleanup();
                paintCursor = null;
            }

            // Set back original textures on 2d and layerRaymarchedVolume
            if (layerRaymarchedVolume != null)
            {
                layerRaymarchedVolume.ApplyShaderParams();
                layerRaymarchedVolume.SetShadowCasterTextureParams();

                // find other layers which use this layer for shadows and apply it to them
                var layers = CloudsManager.GetObjectList().Where(x => x.Body == body && x.LayerRaymarchedVolume != null && x.LayerRaymarchedVolume.ReceiveShadowsFromLayer == layerName);

                foreach (var layer in layers)
                {
                    layer.LayerRaymarchedVolume.SetShadowCasterTextureParams(cloudCoverage, true);
                }
            }

            if (layer2D != null)
            {
                scaledCloudMaterial = layer2D.CloudRenderingMaterial;

                if (scaledCloudMaterial != null)
                {
                    layer2D.CloudsMat.ApplyMaterialProperties(scaledCloudMaterial);
                }
            }
            
        }

        private bool InitTextures()
        {
            // only for equirectangular textures and native cubemaps
            if (cloudsObject.LayerRaymarchedVolume != null)
            {
                layerRaymarchedVolume = cloudsObject.LayerRaymarchedVolume;

                if (layerRaymarchedVolume.CoverageMap != null)   InitTexture(layerRaymarchedVolume.CoverageMap, ref cloudCoverage, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudTypeMap != null)  InitTexture(layerRaymarchedVolume.CloudTypeMap, ref cloudType, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudColorMap != null) InitTexture(layerRaymarchedVolume.CloudColorMap, ref cloudColorMap, RenderTextureFormat.ARGB32);
                if (layerRaymarchedVolume.FlowMap != null && layerRaymarchedVolume.FlowMap.Texture != null) InitTexture(layerRaymarchedVolume.FlowMap.Texture, ref cloudFlowMap, RenderTextureFormat.ARGB32);

                layer2D = cloudsObject.Layer2D;

                if (layer2D?.CloudsMat.FlowMap != null && layer2D?.CloudsMat.FlowMap.Texture != null) InitTexture(layer2D.CloudsMat.FlowMap.Texture, ref cloudScaledFlowMap, RenderTextureFormat.ARGB32);

                SetTextureProperties();

                initialized = true;
            }

            if (editingModes == null || editingModes.Count == 0) return false;

            return true;
        }

        private void SetTextureProperties()
        {
            cloudMaterial = layerRaymarchedVolume.RaymarchedCloudMaterial;

            if (cloudCoverage != null)
            {
                cloudMaterial.EnableKeyword("ALPHAMAP_1");
                cloudMaterial.SetVector("alphaMask1", new Vector4(1f, 0f, 0f, 0f));
                cloudMaterial.SetFloat("useAlphaMask1", 1f);
                SetMaterialTexture(cloudMaterial, "CloudCoverage", cloudCoverage);

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
                SetMaterialTexture(cloudMaterial, "CloudType", cloudType);
            }
            if (cloudColorMap != null) SetMaterialTexture(cloudMaterial, "CloudColorMap", cloudColorMap);

            if (cloudFlowMap != null) SetMaterialTexture(cloudMaterial, "_FlowMap", cloudFlowMap);

            scaledCloudMaterial = layer2D?.CloudRenderingMaterial;

            if (scaledCloudMaterial != null && cloudScaledFlowMap != null)
            {
                SetMaterialTexture(scaledCloudMaterial, "_FlowMap", cloudScaledFlowMap);
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

                targetRT = new RenderTexture(targetTexture.width, targetTexture.height, 0, format, 0);
                targetRT.filterMode = FilterMode.Bilinear;
                targetRT.wrapMode = TextureWrapMode.Repeat;
                targetRT.useMipMap = false;
                
                if (targetTexture.dimension == UnityEngine.Rendering.TextureDimension.Cube)
                    targetRT.dimension = UnityEngine.Rendering.TextureDimension.Cube;

                targetRT.Create();

                var active = RenderTexture.active;

                var copyMapMaterial = new Material(CopyMapShader);

                targetWrapper.SetAlphaMask(copyMapMaterial, 1);

                if (targetRT.dimension == UnityEngine.Rendering.TextureDimension.Cube)
                {
                    CopyCubemapToRT(targetTexture, targetRT, copyMapMaterial);
                }
                else
                {
                    copyMapMaterial.SetTexture("textureToCopy", targetTexture);
                    Graphics.Blit(null, targetRT, copyMapMaterial);
                }

                RenderTexture.active = active;
            }
        }

        // There's no built in unity blit method to blit into a RT cubemap, or from a cubemap face, so implement my own
        private void CopyCubemapToRT(Texture sourceTexture, RenderTexture targetRT, Material copyMapMaterial)
        {
            // Unity doesn't provide a way to blit from a cubemap face to another with a custom material, we have to use Graphics.CopyTexture on a temporary RT and later copy manually to R8 or color texture with the custom material
            RenderTexture cubemapFaceRT = new RenderTexture(sourceTexture.width, sourceTexture.height, 0, RenderTextureFormat.ARGB32, 0);
            cubemapFaceRT.filterMode = FilterMode.Bilinear;
            cubemapFaceRT.wrapMode = TextureWrapMode.Clamp;
            cubemapFaceRT.useMipMap = false;
            cubemapFaceRT.Create();

            for (int i = 0; i < 6; i++)
            {
                Graphics.CopyTexture(sourceTexture, i, 0, cubemapFaceRT, 0, 0);

                // Blit from RT face to full cubemap RT face, using our material, there's no blit method for this, use custom blit
                copyMapMaterial.SetTexture("textureToCopy", cubemapFaceRT);
                RenderTextureUtils.BlitToCubemapFace(targetRT, copyMapMaterial, i);
            }

            cubemapFaceRT.Release();
        }


        public void Paint()
        {
            if (initialized && paintEnabled && HighLogic.LoadedSceneIsFlight && FlightCamera.fetch != null && cloudsObject != null)
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
                    Vector3 scale = new Vector3(brushSize * 2f, brushSize * 2f, brushSize * 2f);
                    float layerHeight = layerRaymarchedVolume != null ? layerRaymarchedVolume.OuterSphereRadius - layerRaymarchedVolume.InnerSphereRadius : 0f;

                    paintCursor.SetLayer((int)Tools.Layer.Default);

                    if (MapView.MapIsEnabled)
                    {
                        cursorPosition = ScaledSpace.LocalToScaledSpace(intersectPosition);
                        scale = scale * (1f / 6000f);
                        paintCursor.SetLayer((int)Tools.Layer.Scaled);
                        layerHeight = layerHeight * (1f / 6000f);
                    }

                    if (paintCursor != null)
                    {
                        paintCursor.SetDrawSettings(cursorPosition, upDirection, scale, layerHeight);
                    }

                    if (Input.GetMouseButton(0) && Input.mousePosition.x != lastDrawnMousePos.x && Input.mousePosition.y != lastDrawnMousePos.y)
                    {
                        lastDrawnMousePos = Input.mousePosition;

                        PaintCurrentMode(intersectPosition, sphereRadius);
                    }

                    if (scaledCloudMaterial != null && cloudScaledFlowMap != null)
                    {
                        SetMaterialTexture(scaledCloudMaterial, "_FlowMap", cloudScaledFlowMap);
                    }

                    lastIntersectPosition = intersectPosition;
                }
            }
        }

        private void SetMaterialTexture(Material mat, string name, Texture tex)
        {
            if (tex.dimension == UnityEngine.Rendering.TextureDimension.Cube)
                mat.SetTexture("cube" + name, tex);
            else
                mat.SetTexture(name, tex);
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

        private void BlitPaint(RenderTexture rt, Material paintMat, int pass)
        {
            if (rt.dimension == UnityEngine.Rendering.TextureDimension.Cube)
            {
                paintMat.EnableKeyword("PAINT_CUBEMAP_ON");
                paintMat.DisableKeyword("PAINT_CUBEMAP_OFF");

                for (int i=0; i<6; i++)
                {
                    paintMat.SetInt("cubemapFace", i);
                    RenderTextureUtils.BlitToCubemapFace(rt, paintMat, i, pass);
                }
            }
            else
            {
                paintMat.EnableKeyword("PAINT_CUBEMAP_OFF");
                paintMat.DisableKeyword("PAINT_CUBEMAP_ON");
                Graphics.Blit(null, rt, paintMat, pass);
            }
        }

        private void PaintCurrentMode(Vector3d intersectPosition, double sphereRadius)
        {
            var cloudRotationMatrix = layer2D != null ? layer2D.MainRotationMatrix * layerRaymarchedVolume.ParentTransform.worldToLocalMatrix : layerRaymarchedVolume.CloudRotationMatrix;

            // feed all info to the shader
            paintMaterial.SetVector("brushPosition", (Vector3)intersectPosition);
            paintMaterial.SetFloat("brushSize", brushSize);
            paintMaterial.SetFloat("hardness", 1f - hardness);
            paintMaterial.SetFloat("opacity", opacity);

            paintMaterial.SetFloat("innerSphereRadius", (float) sphereRadius);
            paintMaterial.SetMatrix("cloudRotationMatrix", cloudRotationMatrix);

            var active = RenderTexture.active;

            if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
            {
                paintMaterial.SetVector("paintValue", new Vector3(coverageValue, coverageValue, coverageValue));

                BlitPaint(cloudCoverage, paintMaterial, 0);
            }
            if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
            {
                paintMaterial.SetVector("paintValue", new Vector3(selectedCloudTypeValue, selectedCloudTypeValue, selectedCloudTypeValue));
                BlitPaint(cloudType, paintMaterial, 0);
            }
            if (editingMode == EditingMode.colorMap)
            {
                paintMaterial.SetColor("paintValue", colorValue);
                BlitPaint(cloudColorMap, paintMaterial, 0);
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

                Vector3 tangentSpaceFlow = new Vector3(tangentOnlyFlow.x * flowValue * 0.5f + 0.5f, tangentOnlyFlow.y * flowValue * 0.5f + 0.5f, upwardsFlowValue * 0.5f + 0.5f);

                paintMaterial.SetVector("paintValue", tangentSpaceFlow);
                BlitPaint(editingMode == EditingMode.flowMapDirectional ? cloudFlowMap : cloudScaledFlowMap, paintMaterial, 0);
            }
            if (editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.scaledFlowMapVortex)
            {
                paintMaterial.SetFloat("flowValue", flowValue);
                paintMaterial.SetFloat("upwardsFlowValue", upwardsFlowValue);
                paintMaterial.SetFloat("clockWiseRotation", vortexRotationDirection == RotationDirection.ClockWise ? 1f : 0f);
                BlitPaint(editingMode == EditingMode.flowMapVortex ? cloudFlowMap : cloudScaledFlowMap, paintMaterial, 1);
            }
            if (editingMode == EditingMode.flowMapBand || editingMode == EditingMode.scaledFlowMapBand)
            {
                paintMaterial.SetFloat("flowValue", flowValue);
                paintMaterial.SetFloat("clockWiseRotation", bandRotationDirection == RotationDirection.ClockWise ? 1f : 0f);
                BlitPaint(editingMode == EditingMode.flowMapBand ? cloudFlowMap : cloudScaledFlowMap, paintMaterial, 2);
            }

            RenderTexture.active = active;
        }

        public void RetargetClouds()
        {
            cloudsObject = CloudsManager.GetObjectList().Where(x => x.Body == body && x.Name == layerName).FirstOrDefault();

            if (cloudsObject != null)
            {
                layerRaymarchedVolume = cloudsObject?.LayerRaymarchedVolume;
                layer2D = cloudsObject?.Layer2D;

                if (layerRaymarchedVolume.CoverageMap != null && cloudCoverage == null) InitTexture(layerRaymarchedVolume.CoverageMap, ref cloudCoverage, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudTypeMap != null && cloudType == null) InitTexture(layerRaymarchedVolume.CloudTypeMap, ref cloudType, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudColorMap != null && cloudColorMap == null) InitTexture(layerRaymarchedVolume.CloudColorMap, ref cloudColorMap, RenderTextureFormat.ARGB32);
                if (layerRaymarchedVolume.FlowMap != null && layerRaymarchedVolume.FlowMap.Texture != null && cloudFlowMap == null) InitTexture(layerRaymarchedVolume.FlowMap.Texture, ref cloudFlowMap, RenderTextureFormat.ARGB32);

                if (cloudsObject != null && layerRaymarchedVolume != null)
                    SetTextureProperties();
            }
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
                vortexRotationDirection = GUIHelper.DrawSelector(Enum.GetValues(typeof(RotationDirection)).Cast<RotationDirection>().ToList(), vortexRotationDirection, 4, placementBase, ref placement);
            }
            else if (editingMode == EditingMode.scaledFlowMapBand || editingMode == EditingMode.scaledFlowMapBand)
            {
                DrawFloatField(placementBase, ref placement, "Flow ", ref flowValue, -1f, 1f, "0.00");
                bandRotationDirection = GUIHelper.DrawSelector(Enum.GetValues(typeof(RotationDirection)).Cast<RotationDirection>().ToList(), bandRotationDirection, 4, placementBase, ref placement);
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

            placement.y += 2;

            if (cloudCoverage != null)
            {
                if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Generate SDF"))
                {
                    var sdfRT = SDFUtils.GenerateSDF(cloudCoverage);

                    string path = CreateFileNameAndPath("sdf", "sdf");

                    SDFUtils.SaveSDFToFile(sdfRT, path);
                    sdfRT.Release();

                    Debug.Log("Saved to " + path);
                    ScreenMessages.PostScreenMessage("Saved to " + path);
                }
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

        private void DrawIntField(Rect placementBase, ref Rect placement, string name, ref int field, int? minValue = null, int? maxValue = null)
        {
            Rect labelRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect fieldRect = GUIHelper.GetRect(placementBase, ref placement);
            GUIHelper.SplitRect(ref labelRect, ref fieldRect, GUIHelper.valueRatio);

            GUI.Label(labelRect, name);

            field = int.Parse(GUI.TextField(fieldRect, field.ToString()));

            if (maxValue.HasValue)
                field = Math.Min(maxValue.Value, field);

            if (minValue.HasValue)
                field = Math.Max(minValue.Value, field);

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
            if (rt.dimension == UnityEngine.Rendering.TextureDimension.Cube)
            {
                RenderTexture cubemapFaceRT = new RenderTexture(rt.width, rt.height, 0, rt.format, 0);
                cubemapFaceRT.filterMode = FilterMode.Bilinear;
                cubemapFaceRT.wrapMode = TextureWrapMode.Clamp;
                cubemapFaceRT.useMipMap = false;
                cubemapFaceRT.Create();

                for (int i=0;i<6;i++)
                {
                    Graphics.CopyTexture(rt, i, cubemapFaceRT, 0);
                    SaveSimpleRTToPNGFile(cubemapFaceRT, mapType+"_"+((CubemapFace)(i)).ToString());
                }

                cubemapFaceRT.Release();
            }
            else
            {
                SaveSimpleRTToPNGFile(rt, mapType);
            }
        }

        private void SaveSimpleRTToPNGFile(RenderTexture rt, string name)
        {
            RenderTexture.active = rt;

            Texture2D tex = new Texture2D(rt.width, rt.height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            RenderTexture.active = null;

            if (rt.format == RenderTextureFormat.R8 || rt.format == RenderTextureFormat.RHalf || rt.format == RenderTextureFormat.R16)
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
            bytes = tex.EncodeToPNG(); // this is leaking memory

            UnityEngine.Object.DestroyImmediate(tex);

            string path = CreateFileNameAndPath(name, "png");

            System.IO.File.WriteAllBytes(path, bytes);
            Debug.Log("Saved to " + path);
            ScreenMessages.PostScreenMessage("Saved to " + path);
        }

        private string CreateFileNameAndPath(string name, string extension)
        {
            string datetime = DateTime.Now.ToString("yyyy-MM-dd\\THH-mm-ss\\Z");

            var gameDataPath = System.IO.Path.Combine(KSPUtil.ApplicationRootPath, "GameData");
            string path = System.IO.Path.Combine(gameDataPath, "EVETextureExports", "PluginData", body);

            if (!Directory.Exists(path))
                Directory.CreateDirectory(path);

            path = System.IO.Path.Combine(path, layerName + "_" + name + "_" + datetime + "." + extension);
            return path;
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