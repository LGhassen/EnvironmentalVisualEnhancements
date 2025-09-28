using UnityEngine;
using System.Linq;
using ShaderLoader;
using Utils;
using System;
using System.IO;
using System.Collections.Generic;
using EVEManager;

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
            scaledFlowMapBand,
            tile,
            maskedTile
        }

        public enum RotationDirection
        {
            ClockWise,
            CounterClockWise
        }

        public EditingMode editingMode = EditingMode.coverage;

        public int twoDimensionalTextureExportResolution = 16384;
        public int twoDimensionalTextureStepCount = 256;
        public float twoDimensionalTextureExposure = 0.8f;

        public float brushSize = 5000f;
        public float hardness = 0f;
        public float opacity = 1f;
        public float coverageValue = 1f;

        public string selectedCloudTypeName = "";
        public float selectedCloudTypeValue = 0f;

        public string selectedPainterTileName = "";
        public PainterTile selectedPainterTile;
        public Vector2 tileRescaleValue = Vector2.one;
        public float tileRotationValue = 0f; // degrees
        public float tileOffsetX, tileOffsetY;
        TextureWrapper selectedTileCoverageWrapper = null;
        TextureWrapper selectedTileTypeWrapper = null;

        public string selectedPainterTileMaskName = "";
        public PainterTileMask selectedPainterTileMask = null;
        TextureWrapper selectedGuideMaskWrapper = null;

        public float flowValue = 1f;
        public float upwardsFlowValue = 0f;

        Vector3d lastIntersectPosition = Vector3d.zero;

        public RotationDirection vortexRotationDirection = RotationDirection.ClockWise;
        public RotationDirection bandRotationDirection  = RotationDirection.ClockWise;

        public Color colorValue = Color.white;

        bool initialized = false;
        bool paintEnabled = true;
        List<EditingMode> editingModes = new List<EditingMode>();

        public PainterRenderTexture cloudCoverage, cloudType, cloudColorMap, cloudFlowMap, cloudScaledFlowMap;

        Material cloudMaterial, reflectionProbeCloudMaterial, scaledCloudMaterial, paintMaterial, screenSpaceShadowMaterial;

        Transform scaledTransform;

        Vector3 lastDrawnMousePos = Vector3.zero;
        bool lastDrawnIsPreview = true;

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

        public static Shader CopyMapShader
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

            cloudCoverage = new PainterRenderTexture();
            cloudType = new PainterRenderTexture();
            cloudColorMap = new PainterRenderTexture();
            cloudFlowMap = new PainterRenderTexture();
            cloudScaledFlowMap = new PainterRenderTexture();

            return InitTextures();
        }

        public void Unload()
        {
            if (cloudCoverage != null) cloudCoverage.Cleanup();
            if (cloudType != null) cloudType.Cleanup();
            if (cloudColorMap != null) cloudColorMap.Cleanup();
            if (cloudFlowMap != null) cloudFlowMap.Cleanup();
            if (cloudScaledFlowMap != null) cloudScaledFlowMap.Cleanup();

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
                    // TODO: Do I even still use this old shadowCaster texture method?
                    // Remove it to remove complexity and multi_compiles?
                    //layer.LayerRaymarchedVolume.SetShadowCasterTextureParams(cloudCoverage.Preview, true);
                    layer.LayerRaymarchedVolume.SetShadowCasterTextureParams();
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

            if (selectedTileCoverageWrapper != null)
            {
                selectedTileCoverageWrapper.Remove();
            }

            if (selectedTileTypeWrapper != null)
            {
                selectedTileTypeWrapper.Remove();
            }

            if (selectedGuideMaskWrapper != null)
            {
                selectedGuideMaskWrapper.Remove();
            }

            UnstableMaskPosition = Vector4.zero;
        }

        private bool InitTextures()
        {
            // only for equirectangular textures and native cubemaps
            if (cloudsObject.LayerRaymarchedVolume != null)
            {
                layerRaymarchedVolume = cloudsObject.LayerRaymarchedVolume;

                if (layerRaymarchedVolume.CoverageMap != null) cloudCoverage.InitTexture(layerRaymarchedVolume.CoverageMap, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudTypeMap != null) cloudType.InitTexture(layerRaymarchedVolume.CloudTypeMap, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudColorMap != null) cloudColorMap.InitTexture(layerRaymarchedVolume.CloudColorMap, RenderTextureFormat.ARGB32);
                if (layerRaymarchedVolume.FlowMap != null && layerRaymarchedVolume.FlowMap.Texture != null) cloudFlowMap.InitTexture(layerRaymarchedVolume.FlowMap.Texture, RenderTextureFormat.ARGB32);

                layer2D = cloudsObject.Layer2D;

                if (layer2D?.CloudsMat.FlowMap != null && layer2D?.CloudsMat.FlowMap.Texture != null) cloudScaledFlowMap.InitTexture(layer2D.CloudsMat.FlowMap.Texture, RenderTextureFormat.ARGB32);

                SetTextureProperties();

                initialized = true;
            }

            if (editingModes == null || editingModes.Count == 0) return false;

            return true;
        }

        private void SetTextureProperties()
        {
            cloudMaterial = layerRaymarchedVolume.RaymarchedCloudMaterial;
            reflectionProbeCloudMaterial = layerRaymarchedVolume.ReflectionProbeRaymarchedCloudMaterial;
            screenSpaceShadowMaterial = layer2D?.ScreenSpaceShadowMaterial;

            if (cloudCoverage.IsCreated)
            {
                cloudMaterial.EnableKeyword("ALPHAMAP_1");
                cloudMaterial.SetVector("alphaMask1", new Vector4(1f, 0f, 0f, 0f));
                cloudMaterial.SetFloat("useAlphaMask1", 1f);
                SetMaterialTexture(cloudMaterial, "CloudCoverage", cloudCoverage.Preview);

                reflectionProbeCloudMaterial.EnableKeyword("ALPHAMAP_1");
                reflectionProbeCloudMaterial.SetVector("alphaMask1", new Vector4(1f, 0f, 0f, 0f));
                reflectionProbeCloudMaterial.SetFloat("useAlphaMask1", 1f);
                SetMaterialTexture(reflectionProbeCloudMaterial, "CloudCoverage", cloudCoverage.Preview);

                if (screenSpaceShadowMaterial != null)
                {
                    screenSpaceShadowMaterial.EnableKeyword("ALPHAMAP_1");
                    screenSpaceShadowMaterial.SetVector("alphaMask1", new Vector4(1f, 0f, 0f, 0f));
                    screenSpaceShadowMaterial.SetFloat("useAlphaMask1", 1f);
                    SetMaterialTexture(screenSpaceShadowMaterial, "CloudCoverage", cloudCoverage.Preview);
                }

                // find other layers which use this for shadows and apply it to them
                var layers = CloudsManager.GetObjectList().Where(x => x.Body == body && x.LayerRaymarchedVolume != null && x.LayerRaymarchedVolume.ReceiveShadowsFromLayer == layerName);

                foreach (var layer in layers)
                {
                    layer.LayerRaymarchedVolume.SetShadowCasterTextureParams(cloudCoverage.Preview, true);
                }

                cloudMaterial.DisableKeyword("SDF_ON");
                cloudMaterial.EnableKeyword("SDF_OFF");

                reflectionProbeCloudMaterial.DisableKeyword("SDF_ON");
                reflectionProbeCloudMaterial.EnableKeyword("SDF_OFF");
            }

            if (cloudType.IsCreated)
            {
                cloudMaterial.EnableKeyword("ALPHAMAP_2");
                cloudMaterial.SetVector("alphaMask2", new Vector4(1f, 0f, 0f, 0f));
                cloudMaterial.SetFloat("useAlphaMask2", 1f);
                SetMaterialTexture(cloudMaterial, "CloudType", cloudType.Preview);

                reflectionProbeCloudMaterial.EnableKeyword("ALPHAMAP_2");
                reflectionProbeCloudMaterial.SetVector("alphaMask2", new Vector4(1f, 0f, 0f, 0f));
                reflectionProbeCloudMaterial.SetFloat("useAlphaMask2", 1f);
                SetMaterialTexture(reflectionProbeCloudMaterial, "CloudType", cloudType.Preview);

                if (screenSpaceShadowMaterial != null)
                {
                    screenSpaceShadowMaterial.EnableKeyword("ALPHAMAP_2");
                    screenSpaceShadowMaterial.SetVector("alphaMask2", new Vector4(1f, 0f, 0f, 0f));
                    screenSpaceShadowMaterial.SetFloat("useAlphaMask2", 1f);
                    SetMaterialTexture(screenSpaceShadowMaterial, "CloudType", cloudType.Preview);
                }
            }
            if (cloudColorMap.IsCreated)
            { 
                SetMaterialTexture(cloudMaterial, "CloudColorMap", cloudColorMap.Preview);
                SetMaterialTexture(reflectionProbeCloudMaterial, "CloudColorMap", cloudColorMap.Preview);
            }

            if (cloudFlowMap.IsCreated)
            { 
                SetMaterialTexture(cloudMaterial, "_FlowMap", cloudFlowMap.Preview);
                SetMaterialTexture(reflectionProbeCloudMaterial, "_FlowMap", cloudFlowMap.Preview);
            }

            scaledCloudMaterial = layer2D?.CloudRenderingMaterial;

            if (scaledCloudMaterial != null && cloudScaledFlowMap.IsCreated)
            {
                SetMaterialTexture(scaledCloudMaterial, "_FlowMap", cloudScaledFlowMap.Preview);
            }

            editingModes = new List<EditingMode>();

            if (cloudCoverage.IsCreated)
                editingModes.Add(EditingMode.coverage);

            if (cloudType.IsCreated)
                editingModes.Add(EditingMode.cloudType);

            if (cloudCoverage.IsCreated && cloudType.IsCreated)
                editingModes.Add(EditingMode.coverageAndCloudType);

            if (cloudCoverage.IsCreated && layerRaymarchedVolume.PainterTiles != null && layerRaymarchedVolume.PainterTiles.Count > 0)
            {
                editingModes.Add(EditingMode.tile);

                if (layerRaymarchedVolume.PainterTileMasks != null && layerRaymarchedVolume.PainterTileMasks.Count > 0)
                { 
                    editingModes.Add(EditingMode.maskedTile);
                }
            }

            if (cloudColorMap.IsCreated)
                editingModes.Add(EditingMode.colorMap);

            if (cloudFlowMap.IsCreated)
            {
                editingModes.Add(EditingMode.flowMapDirectional);
                editingModes.Add(EditingMode.flowMapVortex);
                editingModes.Add(EditingMode.flowMapBand);
            }

            if (cloudScaledFlowMap.IsCreated)
            {
                editingModes.Add(EditingMode.scaledFlowMapDirectional);
                editingModes.Add(EditingMode.scaledFlowMapVortex);
                editingModes.Add(EditingMode.scaledFlowMapBand);
            }
        }

        bool mouseWasOverWindow = false;

        private void ResetPreview()
        {
            if (editingMode == EditingMode.coverage || editingMode == EditingMode.coverageAndCloudType)
            {
                cloudCoverage.CopyCommittedToPreview();
            }
            if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
            {
                cloudType.CopyCommittedToPreview();
            }
            if (editingMode == EditingMode.colorMap)
            {
                cloudColorMap.CopyCommittedToPreview();
            }
            if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.flowMapBand)
            {
                cloudFlowMap.CopyCommittedToPreview();
            }
            if (editingMode == EditingMode.scaledFlowMapDirectional || editingMode == EditingMode.scaledFlowMapVortex || editingMode == EditingMode.scaledFlowMapBand)
            {
                cloudScaledFlowMap.CopyCommittedToPreview();
            }
            if (editingMode == EditingMode.tile || editingMode == EditingMode.maskedTile)
            {
                if (cloudCoverage.IsCreated)
                {
                    cloudCoverage.CopyCommittedToPreview();
                }
                if (cloudType.IsCreated)
                {
                    cloudType.CopyCommittedToPreview();
                }
            }
        }

        // KSP version doesn't work correctly?
        public Vector3d CorrectedTransformPoint(Matrix4x4D m, Vector3d v)
        {
            return new Vector3d(
                v.x * m.m00 + v.y * m.m01 + v.z * m.m02 + m.m03,
                v.x * m.m10 + v.y * m.m11 + v.z * m.m12 + m.m13,
                v.x * m.m20 + v.y * m.m21 + v.z * m.m22 + m.m23);
        }

        // Publicly accessible for unstable mask in reconstruction shader
        public static Vector4 UnstableMaskPosition = Vector4.zero;

        public void Paint()
        {
            UnstableMaskPosition = Vector4.zero;

            if (GlobalEVEManager.MouseIsOverWindow)
            {
                if (!mouseWasOverWindow)
                {
                    ResetPreview();
                }

                mouseWasOverWindow = true;
                return;
            }

            mouseWasOverWindow = false;

            if (initialized && paintEnabled && HighLogic.LoadedSceneIsFlight && FlightCamera.fetch != null && cloudsObject != null)
            {
                Vector3d sphereCenter = ScaledSpace.ScaledToLocalSpace(scaledTransform.position);

                var planetRadius = cloudMaterial.GetFloat("planetRadius");
                // TODO: maybe detect if planet has ocean to do this
                float innerSphereRadius = Mathf.Max(planetRadius, cloudMaterial.GetFloat("innerSphereRadius"));
                float outerSphereRadius = Mathf.Max(planetRadius, cloudMaterial.GetFloat("outerSphereRadius"));
                double sphereRadius = innerSphereRadius;

                Vector3d rayDir, cameraPos;

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

                var cloudSpaceCameraPos = CorrectedTransformPoint(new Matrix4x4D(layerRaymarchedVolume.CloudRotationMatrix), cameraPos);
                UpdateTilePaintingTangentFrame(cloudSpaceCameraPos, innerSphereRadius);

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

                    bool isPreview = !Input.GetMouseButton(0);

                    // Fit a sphere around our unstable area
                    float unstableRadius = Mathf.Sqrt(brushSize * brushSize + 0.25f * layerHeight * layerHeight);
                    Vector3 unstablePosition = intersectPosition + upDirection * layerHeight * 0.5f;
                    UnstableMaskPosition = new Vector4(unstablePosition.x, unstablePosition.y, unstablePosition.z, unstableRadius);

                    if ((Input.mousePosition.x != lastDrawnMousePos.x && Input.mousePosition.y != lastDrawnMousePos.y) || (isPreview != lastDrawnIsPreview))
                    {
                        lastDrawnMousePos = Input.mousePosition;
                        lastDrawnIsPreview = isPreview;

                        PaintCurrentMode(intersectPosition, sphereRadius, isPreview);
                    }

                    if (scaledCloudMaterial != null && cloudScaledFlowMap.IsCreated)
                    {
                        SetMaterialTexture(scaledCloudMaterial, "_FlowMap", cloudScaledFlowMap.Preview);
                    }

                    lastIntersectPosition = intersectPosition;
                }
            }
        }

        static bool tangentFrameInitialized = false;
        static Vector3d tangentFrameTangent = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameBitangent = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameNormal = new Vector3d(0, 0, 0);
        static Vector3d tangentFrameOrigin = new Vector3d(0, 0, 0);
        static Vector3d cumulatedTangentFrameOffset = new Vector3d(0, 0, 0);

        private void UpdateTilePaintingTangentFrame(Vector3d cameraPositionInCloudSpace, double radius)
        {
            tangentFrameNormal = cameraPositionInCloudSpace.normalized;

            if (tangentFrameInitialized)
            {
                tangentFrameTangent = Vector3d.Cross(tangentFrameBitangent, tangentFrameNormal).normalized;
            }
            else
            {
                var reference = Math.Abs(tangentFrameNormal.y) < 0.99d ? new Vector3d(0d, 1d, 0d) : new Vector3d(1d, 0d, 0d);
                tangentFrameTangent = Vector3d.Cross(reference, tangentFrameNormal).normalized;
                tangentFrameInitialized = true;
            }

            tangentFrameBitangent = Vector3d.Cross(tangentFrameNormal, tangentFrameTangent).normalized;

            var currentFrameOrigin = tangentFrameNormal * radius;

            var frameDelta = currentFrameOrigin - tangentFrameOrigin;
            Vector3d projectedFrameDelta = frameDelta - Vector3d.Dot(frameDelta, tangentFrameNormal) * tangentFrameNormal;  // Remove normal component
            Vector2d frameOffset = new Vector2d(Vector3d.Dot(tangentFrameTangent, projectedFrameDelta), Vector3d.Dot(tangentFrameBitangent, projectedFrameDelta));

            var sinTheta = Vector3d.Cross(tangentFrameOrigin.normalized, currentFrameOrigin.normalized).magnitude;
            var arcAngle = Math.Asin(Math.Max(Math.Min(sinTheta, 1.0), 0.0));
            var arcLength = radius * arcAngle;

            frameOffset = frameOffset.normalized * arcLength;

            if (double.IsNaN(frameOffset.x) || double.IsNaN(frameOffset.y))
            {
                frameOffset = Vector2d.zero;
            }

            cumulatedTangentFrameOffset += frameOffset;

            tangentFrameOrigin = currentFrameOrigin;
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

        private void BlitPaint(PainterRenderTexture painterTexture, bool isPreview, Material paintMat, int pass)
        {
            painterTexture.CopyCommittedToPreview();

            var rtToPaint = isPreview ? painterTexture.Preview : painterTexture.Committed;

            if (rtToPaint.dimension == UnityEngine.Rendering.TextureDimension.Cube)
            {
                paintMat.EnableKeyword("PAINT_CUBEMAP_ON");
                paintMat.DisableKeyword("PAINT_CUBEMAP_OFF");

                for (int i=0; i<6; i++)
                {
                    paintMat.SetInt("cubemapFace", i);
                    RenderTextureUtils.BlitToCubemapFace(rtToPaint, paintMat, i, pass);
                }
            }
            else
            {
                paintMat.EnableKeyword("PAINT_CUBEMAP_OFF");
                paintMat.DisableKeyword("PAINT_CUBEMAP_ON");
                Graphics.Blit(null, rtToPaint, paintMat, pass);
            }
        }

        private void PaintCurrentMode(Vector3d intersectPosition, double sphereRadius, bool isPreview)
        {
            var cloudRotationMatrix = layer2D != null ? layer2D.MainRotationMatrix * layerRaymarchedVolume.ParentTransform.worldToLocalMatrix : layerRaymarchedVolume.CloudRotationMatrix;

            // Feed all info to the shader
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

                BlitPaint(cloudCoverage, isPreview, paintMaterial, 0);
            }
            if (editingMode == EditingMode.cloudType || editingMode == EditingMode.coverageAndCloudType)
            {
                paintMaterial.SetVector("paintValue", new Vector3(selectedCloudTypeValue, selectedCloudTypeValue, selectedCloudTypeValue));
                BlitPaint(cloudType, isPreview, paintMaterial, 0);
            }
            if (editingMode == EditingMode.colorMap)
            {
                paintMaterial.SetColor("paintValue", colorValue);
                BlitPaint(cloudColorMap, isPreview, paintMaterial, 0);
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
                BlitPaint(editingMode == EditingMode.flowMapDirectional ? cloudFlowMap : cloudScaledFlowMap, isPreview, paintMaterial, 0);
            }
            if (editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.scaledFlowMapVortex)
            {
                paintMaterial.SetFloat("flowValue", flowValue);
                paintMaterial.SetFloat("upwardsFlowValue", upwardsFlowValue);
                paintMaterial.SetFloat("clockWiseRotation", vortexRotationDirection == RotationDirection.ClockWise ? 1f : 0f);
                BlitPaint(editingMode == EditingMode.flowMapVortex ? cloudFlowMap : cloudScaledFlowMap, isPreview, paintMaterial, 1);
            }
            if (editingMode == EditingMode.flowMapBand || editingMode == EditingMode.scaledFlowMapBand)
            {
                paintMaterial.SetFloat("flowValue", flowValue);
                paintMaterial.SetFloat("clockWiseRotation", bandRotationDirection == RotationDirection.ClockWise ? 1f : 0f);
                BlitPaint(editingMode == EditingMode.flowMapBand ? cloudFlowMap : cloudScaledFlowMap, isPreview, paintMaterial, 2);
            }
            if (editingMode == EditingMode.tile || editingMode == EditingMode.maskedTile)
            {
                var selectedTileSize = (double)selectedPainterTile.Size;
                var uvOffset = cumulatedTangentFrameOffset / selectedTileSize;
                uvOffset.x /= tileRescaleValue.x;
                uvOffset.y /= tileRescaleValue.y;
                uvOffset = new Vector3d(uvOffset.x - Math.Floor(uvOffset.x), uvOffset.y - Math.Floor(uvOffset.y), 0d);

                paintMaterial.SetVector("tileFrameTangent", (Vector3)tangentFrameTangent);
                paintMaterial.SetVector("tileFrameBitangent", (Vector3)tangentFrameBitangent);
                paintMaterial.SetVector("tileFrameNormal", (Vector3)tangentFrameNormal);
                paintMaterial.SetVector("tileFrameOrigin", (Vector3)tangentFrameOrigin);
                paintMaterial.SetVector("tileFrameUVOffset", (Vector3)uvOffset);
                paintMaterial.SetVector("tileSize", selectedPainterTile.Size * tileRescaleValue);

                paintMaterial.SetFloat("tileRotation", tileRotationValue * Mathf.Deg2Rad);
                paintMaterial.SetVector("tileOffset", new Vector2((float)tileOffsetX, (float)tileOffsetY));

                if (selectedTileCoverageWrapper != selectedPainterTile.CoverageMap)
                {
                    if (selectedPainterTile.CoverageMap!= null)
                        selectedPainterTile.CoverageMap.ApplyTexture(paintMaterial, "inputTile", 2);

                    if (selectedTileCoverageWrapper != null)
                        selectedTileCoverageWrapper.Remove();

                    selectedTileCoverageWrapper = selectedPainterTile.CoverageMap;
                }

                if (selectedTileTypeWrapper != selectedPainterTile.CloudTypeMap)
                {
                    if (selectedPainterTile.CloudTypeMap != null)
                        selectedPainterTile.CloudTypeMap.ApplyTexture(paintMaterial, "inputTypeTile", 3);

                    if (selectedTileTypeWrapper != null)
                        selectedTileTypeWrapper.Remove();

                    selectedTileTypeWrapper = selectedPainterTile.CloudTypeMap;
                }

                if (editingMode == EditingMode.maskedTile)
                {
                    if (selectedGuideMaskWrapper != selectedPainterTileMask.Texture)
                    { 
                        if (selectedPainterTileMask.Texture != null)
                            selectedPainterTileMask.Texture.ApplyTexture(paintMaterial, "inputMask", 1);

                        if (selectedGuideMaskWrapper != null)
                            selectedGuideMaskWrapper.Remove();

                        selectedGuideMaskWrapper = selectedPainterTileMask.Texture;
                    }

                    paintMaterial.SetInt("useGuideMask", 1);
                }
                else
                {
                    paintMaterial.SetInt("useGuideMask", 0);
                }

                paintMaterial.SetVector("remapTile", selectedPainterTile.RemapCoverage);
                paintMaterial.SetInt("readType", 0);
                paintMaterial.SetInt("writingType", 0);
                BlitPaint(cloudCoverage, isPreview, paintMaterial, 3);

                paintMaterial.SetVector("remapTile", selectedPainterTile.RemapType);
                paintMaterial.SetInt("readType", selectedTileTypeWrapper != null ? 1 : 0);
                paintMaterial.SetInt("writingType", 1);
                BlitPaint(cloudType, isPreview, paintMaterial, 3);
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

                if (layerRaymarchedVolume.CoverageMap != null && !cloudCoverage.IsCreated) cloudCoverage.InitTexture(layerRaymarchedVolume.CoverageMap, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudTypeMap != null && !cloudType.IsCreated) cloudType.InitTexture(layerRaymarchedVolume.CloudTypeMap, RenderTextureFormat.R8);
                if (layerRaymarchedVolume.CloudColorMap != null && !cloudColorMap.IsCreated) cloudColorMap.InitTexture(layerRaymarchedVolume.CloudColorMap, RenderTextureFormat.ARGB32);
                if (layerRaymarchedVolume.FlowMap != null && layerRaymarchedVolume.FlowMap.Texture != null && !cloudFlowMap.IsCreated) cloudFlowMap.InitTexture(layerRaymarchedVolume.FlowMap.Texture, RenderTextureFormat.ARGB32);

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
            else if (editingMode == EditingMode.tile || editingMode == EditingMode.maskedTile)
            {
                // Draw tile selector
                var tileList = layerRaymarchedVolume.PainterTiles.Select(x => x.TileName).ToList();
                int selectedIndex = tileList.IndexOf(selectedPainterTileName);
                selectedIndex = selectedIndex < 0 ? 0 : selectedIndex;

                selectedPainterTileName = GUIHelper.DrawSelector<String>(tileList, ref selectedIndex, 4, placementBase, ref placement);
                selectedPainterTile = layerRaymarchedVolume.PainterTiles[selectedIndex];

                // Draw tile rescale and tile rotation fields
                DrawFloatField(placementBase, ref placement, "Rescale X", ref tileRescaleValue.x, 0f, 5f, "0.00");
                DrawFloatField(placementBase, ref placement, "Rescale Y", ref tileRescaleValue.y, 0f, 5f, "0.00");
                DrawFloatField(placementBase, ref placement, "Rotate ", ref tileRotationValue, -360f, 360f, "000");
                DrawFloatField(placementBase, ref placement, "Offset X ", ref tileOffsetX, -1f, 1f, "0.00");
                DrawFloatField(placementBase, ref placement, "Offset Y ", ref tileOffsetY, -1f, 1f, "0.00");

                if (editingMode == EditingMode.maskedTile)
                {
                    // Draw tile mask selector
                    var tileMaskList = layerRaymarchedVolume.PainterTileMasks.Select(x => x.TileMaskName).ToList();
                    int selectedMaskIndex = tileMaskList.IndexOf(selectedPainterTileName);
                    selectedMaskIndex = selectedMaskIndex < 0 ? 0 : selectedMaskIndex;

                    selectedPainterTileMaskName = GUIHelper.DrawSelector<String>(tileMaskList, ref selectedMaskIndex, 4, placementBase, ref placement);
                    selectedPainterTileMask = layerRaymarchedVolume.PainterTileMasks[selectedMaskIndex];
                }
            }

            paintEnabled = GUI.Toggle(GUIHelper.GetRect(placementBase, ref placement), paintEnabled, "Enable painting");
            placement.y += 1;


            Rect resetRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect resetAllRect = new Rect(resetRect);
            GUIHelper.SplitRect(ref resetRect, ref resetAllRect, 0.5f);

            if (GUI.Button(resetRect, "Reset current mode textures"))
            {
                ResetCurrentTextures();
            }

            if (GUI.Button(resetAllRect, "Reset all textures"))
            {
                InitTextures();
            }
            placement.y += 1;


            Rect saveRect = GUIHelper.GetRect(placementBase, ref placement);
            Rect saveAllRect = new Rect(saveRect);
            GUIHelper.SplitRect(ref saveRect, ref saveAllRect, 0.5f);

            if (GUI.Button(saveRect, "Save current mode textures"))
            {
                SaveCurrentTextures();
            }

            if (GUI.Button(saveAllRect, "Save all textures"))
            {
                SaveAllTextures();
            }

            placement.y += 2;

            if (cloudCoverage.IsCreated)
            {
                if (GUI.Button(GUIHelper.GetRect(placementBase, ref placement), "Generate SDF"))
                {
                    GenerateAndSaveSDF();
                }
            }
            
            placement.y += 2;

            if (cloudCoverage.IsCreated)
            {
                Rect button1Rect = GUIHelper.GetRect(placementBase, ref placement);
                Rect button2Rect = new Rect(button1Rect);
                Rect resRect = new Rect(button1Rect);
                Rect stepsRect = new Rect(button1Rect);
                Rect exposureRect = new Rect(button1Rect);
                GUIHelper.SplitRect(ref button1Rect, ref resRect, 1 / 2f);
                GUIHelper.SplitRect(ref button1Rect, ref button2Rect, 1 / 2f);
                GUIHelper.SplitRect(ref resRect, ref stepsRect, 1 / 3f);
                GUIHelper.SplitRect(ref stepsRect, ref exposureRect, 1 / 2f);

                if (GUI.Button(button1Rect, "Generate 2D texture"))
                {
                    Generate2DTexture(false);
                }

                if (GUI.Button(button2Rect, "Generate 2D normals"))
                {
                    Generate2DTexture(true);
                }

                DrawIntFieldInPlace(resRect, "Size", ref twoDimensionalTextureExportResolution, 0);
                DrawIntFieldInPlace(stepsRect, "Samples", ref twoDimensionalTextureStepCount, 0);
                DrawFloatFieldInPlace(exposureRect, "Exposure", ref twoDimensionalTextureExposure, 0);
            }
        }

        private void GenerateAndSaveSDF()
        {
            string path = CreateFileNameAndPath("sdf", "sdf");
            SDFTool.GenerateAndSaveSDFInBackground(cloudCoverage.Committed, path);
        }

        private void Generate2DTexture(bool normals)
        {
            var targetRT = new RenderTexture(twoDimensionalTextureExportResolution,
                twoDimensionalTextureExportResolution / 2, 0, RenderTextureFormat.ARGB32, 0);
            targetRT.Create();

            layerRaymarchedVolume.RaymarchedCloudMaterial.SetMatrix("invCloudRotationMatrix", layerRaymarchedVolume.CloudRotationMatrix.inverse);
            layerRaymarchedVolume.RaymarchedCloudMaterial.SetInt("twoDimensionalTextureStepCount", twoDimensionalTextureStepCount);
            layerRaymarchedVolume.RaymarchedCloudMaterial.SetFloat("twoDimensionalTextureExposure", twoDimensionalTextureExposure);
            layerRaymarchedVolume.RaymarchedCloudMaterial.SetVector("twoDimensionalTextureResolution", new Vector2(twoDimensionalTextureExportResolution, twoDimensionalTextureExportResolution / 2));
            layerRaymarchedVolume.RaymarchedCloudMaterial.SetFloat("generateNormals", normals ? 1.0f : 0.0f);

            Graphics.Blit(null, targetRT, layerRaymarchedVolume.RaymarchedCloudMaterial,
                DeferredRaymarchedVolumetricCloudsRenderer.RaymarchedCloudShaderPassName.Generate2DTexture);

            SaveRTToFile(targetRT, normals ? "2D-normals" : "2D");
            targetRT.Release();
        }

        private void ResetCurrentTextures()
        {
            if (editingMode == EditingMode.coverage)
            {
                cloudCoverage.InitTexture(layerRaymarchedVolume.CoverageMap, RenderTextureFormat.R8);
            }
            else if (editingMode == EditingMode.cloudType)
            {
                cloudType.InitTexture(layerRaymarchedVolume.CloudTypeMap, RenderTextureFormat.R8);
            }
            else if (editingMode == EditingMode.coverageAndCloudType)
            {
                var cloudTypeTexture = layerRaymarchedVolume.CloudTypeMap.GetTexture();
                var coverageMapTexture = layerRaymarchedVolume.CoverageMap.GetTexture();

                if (coverageMapTexture != null && cloudTypeTexture != null)
                {
                    cloudCoverage.InitTexture(layerRaymarchedVolume.CoverageMap, RenderTextureFormat.R8);
                    cloudType.InitTexture(layerRaymarchedVolume.CloudTypeMap, RenderTextureFormat.R8);
                }
            }
            else if (editingMode == EditingMode.colorMap)
            {
                cloudColorMap.InitTexture(layerRaymarchedVolume.CloudColorMap, RenderTextureFormat.ARGB32);
            }
            else if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.flowMapVortex)
            {
                cloudFlowMap.InitTexture(layerRaymarchedVolume.FlowMap.Texture, RenderTextureFormat.ARGB32);
            }

            SetTextureProperties();
        }

        private void SaveCurrentTextures()
        {
            // TODO: change all to committed
            if (editingMode == EditingMode.coverage && cloudCoverage.IsCreated)
            {
                SaveRTToFile(cloudCoverage.Committed, "CloudCoverage");
            }
            else if (editingMode == EditingMode.cloudType && cloudType.IsCreated)
            {
                SaveRTToFile(cloudType.Committed, "CloudType");
            }
            else if ((editingMode == EditingMode.coverageAndCloudType || editingMode == EditingMode.tile || editingMode == EditingMode.maskedTile) && (cloudType.IsCreated || cloudCoverage.IsCreated))
            {
                if (cloudCoverage.IsCreated)
                    SaveRTToFile(cloudCoverage.Committed, "CloudCoverage");
                if (cloudType.IsCreated)
                    SaveRTToFile(cloudType.Committed, "CloudType");
            }
            else if (editingMode == EditingMode.colorMap && cloudColorMap.IsCreated)
            {
                SaveRTToFile(cloudColorMap.Committed, "CloudColor");
            }
            else if (editingMode == EditingMode.flowMapDirectional || editingMode == EditingMode.flowMapVortex || editingMode == EditingMode.flowMapBand)
            {
                SaveRTToFile(cloudFlowMap.Committed, "CloudFlowMap");
            }
            else if (editingMode == EditingMode.scaledFlowMapDirectional || editingMode == EditingMode.scaledFlowMapVortex || editingMode == EditingMode.scaledFlowMapBand)
            {
                SaveRTToFile(cloudScaledFlowMap.Committed, "CloudScaledFlowMap");
            }
        }

        private void SaveAllTextures()
        {
            if (cloudCoverage.IsCreated)
            {
                SaveRTToFile(cloudCoverage.Committed, "CloudCoverage");
            }
            if (cloudType.IsCreated)
            {
                SaveRTToFile(cloudType.Committed, "CloudType");
            }
            if (cloudColorMap.IsCreated)
            {
                SaveRTToFile(cloudColorMap.Committed, "ColorMap");
            }
            if (cloudFlowMap.IsCreated)
            {
                SaveRTToFile(cloudFlowMap.Committed, "CloudFlowMap");
            }
            if(cloudScaledFlowMap.IsCreated)
            {
                SaveRTToFile(cloudScaledFlowMap.Committed, "CloudScaledFlowMap");
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

        private void DrawFloatFieldInPlace(Rect placement, string name, ref float field, float? minValue = null, float? maxValue = null, string format = null)
        {
            Rect labelRect = new Rect(placement);
            Rect fieldRect = new Rect(placement);
            GUIHelper.SplitRect(ref labelRect, ref fieldRect, 0.55f);

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

        private void DrawIntFieldInPlace(Rect placement, string name, ref int field, int? minValue = null, int? maxValue = null)
        {
            Rect labelRect = new Rect(placement);
            Rect fieldRect = new Rect(placement);
            GUIHelper.SplitRect(ref labelRect, ref fieldRect, 0.55f);

            GUI.Label(labelRect, name);

            field = int.Parse(GUI.TextField(fieldRect, field.ToString()));

            if (maxValue.HasValue)
                field = Math.Min(maxValue.Value, field);

            if (minValue.HasValue)
                field = Math.Max(minValue.Value, field);
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

                var copyMapMaterial = new Material(CopyMapShader);
                copyMapMaterial.EnableKeyword("CUBEMAP_MODE_ON");
                copyMapMaterial.SetTexture("textureToCopy", rt);

                for (int i=0;i<6;i++)
                {
                    copyMapMaterial.SetInt("cubemapFace", i);
                    Graphics.Blit(null, cubemapFaceRT, copyMapMaterial);

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

            var singleChannel = rt.format == RenderTextureFormat.R8 || rt.format == RenderTextureFormat.RHalf || rt.format == RenderTextureFormat.R16;

            Texture2D tex = new Texture2D(rt.width, rt.height, singleChannel ? TextureFormat.RGB24 : TextureFormat.ARGB32, false);
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            RenderTexture.active = null;

            if (singleChannel)
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