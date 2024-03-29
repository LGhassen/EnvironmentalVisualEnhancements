﻿using Utils;
using UnityEngine;
using UnityEngine.Rendering;
using System;
using System.Collections.Generic;
using ShaderLoader;

namespace Atmosphere
{
    class LightVolume
    {
        private static LightVolume instance;

        public static LightVolume Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new LightVolume();
                }
                return instance;
            }
        }

        private int volumeResolution = 0;
        private int volumeSlices = 0;           // volume slices of a single direct or ambient volume
        private int mergedVolumeSlices = 0;     // total slices of the combined volume holding both
        private int stepCount = 0;
        private static readonly int maxSlicesInOnePass = 16; // Max slices of a 3d texture the shader can output to in a single pass
                                                             // (capped by using a geometry shader to write to multiple slices of 3d texture)

        private int directLightSlicesToUpdateEveryFrame, ambientLightSlicesToUpdateEveryFrame;

        // The first slices are for direct light, and the second half for ambient. The volumes are combined
        // to save a texture slot on Macs which have a hidden 16 texture limit in OpenGL (regardless of samplers)
        private FlipFlop<RenderTexture> lightVolume;

        private ComputeShader reprojectLightVolumeComputeShader = null;
        private static Shader reprojectLightVolumeShader = null;
        private Material reprojectLightVolumeMaterial;
        private bool readFromFlipLightVolume = true;
        private int nextDirectSliceToUpdate = 0, nextAmbientSliceToUpdate = 0;

        private Vector3 planetLightVolumePosition = Vector3.zero;
        private Vector3 worldLightVolumePosition = Vector3.zero;

        private Matrix4x4 lightVolumeToWorld = Matrix4x4.identity;
        private Matrix4x4 worldToLightVolume = Matrix4x4.identity;

        private float currentLightVolumeRadius;

        private Vector3 lightVolumeDimensions = Vector3.zero;
        private float lightVolumeLowestAltitude = 0f, lightVolumeHighestAltitude = 0f;

        private const float reprojectionThreshold = 0.03f;
        private const float radiusReprojectionThreshold = 1f + reprojectionThreshold;
        private static Shader ReprojectLightVolumeShader
        {
            get
            {
                if (reprojectLightVolumeShader == null) reprojectLightVolumeShader = ShaderLoaderClass.FindShader("EVE/ReprojectLightVolume");
                return reprojectLightVolumeShader;
            }
        }

        private bool updated = false;
        private bool released = false;
        private bool useMultiSliceUpdate = false;

        public LightVolume()
        {
            volumeResolution = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            volumeSlices = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;
            mergedVolumeSlices = volumeSlices * 2;
            stepCount = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.StepCount;
            lightVolumeDimensions = new Vector3(volumeResolution, volumeResolution, volumeSlices);

            useMultiSliceUpdate = SystemInfo.graphicsDeviceVersion.Contains("Direct3D");

            bool useComputeShader = SystemInfo.supportsComputeShaders;

            if (useComputeShader)
            { 
                reprojectLightVolumeComputeShader = ShaderLoaderClass.FindComputeShader("ReprojectLightVolume");
                reprojectLightVolumeComputeShader.SetVector("lightVolumeDimensions", lightVolumeDimensions);
            }
            else
            {
                reprojectLightVolumeMaterial = new Material(ReprojectLightVolumeShader);
                reprojectLightVolumeMaterial.SetVector("lightVolumeDimensions", lightVolumeDimensions);
            }

            directLightSlicesToUpdateEveryFrame  = Mathf.Max(volumeSlices / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.DirectLightTimeSlicing,  1);
            ambientLightSlicesToUpdateEveryFrame = Mathf.Max(volumeSlices / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.AmbientLightTimeSlicing, 1);

            lightVolume  = RenderTextureUtils.CreateFlipFlopRT(volumeResolution, volumeResolution, RenderTextureFormat.RHalf, FilterMode.Bilinear, TextureDimension.Tex3D, mergedVolumeSlices, useComputeShader, TextureWrapMode.Clamp);
        }

        public void Update(List<CloudsRaymarchedVolume> volumes, Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix, float maxRadius)
        {
            if (!updated && !released)
            {
                UpdateSettings();

                UpdateLightVolume(cameraPosition, planetTransform, planetRadius, innerCloudsRadius, outerCloudsRadius, slowestLayerPlanetFrameDeltaRotationMatrix, maxRadius);

                bool firstLayer = true;

                foreach (var volumetricLayer in volumes)
                {
                    if (volumetricLayer.LightVolumeSettings.UseLightVolume)
                    {
                        volumetricLayer.RaymarchedCloudMaterial.SetVector(ShaderProperties.lightVolumeDimensions_PROPERTY, lightVolumeDimensions);

                        volumetricLayer.RaymarchedCloudMaterial.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, worldLightVolumePosition);
                        volumetricLayer.RaymarchedCloudMaterial.SetMatrix(ShaderProperties.paraboloidToWorld_PROPERTY, lightVolumeToWorld); // is this needed?
                        volumetricLayer.RaymarchedCloudMaterial.SetMatrix(ShaderProperties.worldToParaboloid_PROPERTY, worldToLightVolume);

                        volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
                        volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

                        volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.clearExistingVolume_PROPERTY, firstLayer ? 1f : 0f);

                        volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.lightVolumeLightMarchSteps_PROPERTY, stepCount);

                        int currentLayerDirectLightVolumeSliceToUpdate = nextDirectSliceToUpdate;
                        int currentLayerAmbientLightVolumeSliceToUpdate = nextAmbientSliceToUpdate;

                        if (useMultiSliceUpdate)
                        {
                            UpdateLightVolumeWithMultiSliceSupport(volumetricLayer, ref currentLayerDirectLightVolumeSliceToUpdate, ref currentLayerAmbientLightVolumeSliceToUpdate);
                        }
                        else
                        {
                            UpdateLightVolumeWithoutMultiSliceSupport(volumetricLayer, ref currentLayerDirectLightVolumeSliceToUpdate, ref currentLayerAmbientLightVolumeSliceToUpdate);
                        }

                        volumetricLayer.RaymarchedCloudMaterial.SetTexture(ShaderProperties.lightVolume_PROPERTY, lightVolume[readFromFlipLightVolume]);

                        firstLayer = false;
                    }
                }

                nextDirectSliceToUpdate  = (nextDirectSliceToUpdate + directLightSlicesToUpdateEveryFrame) % volumeSlices;
                nextAmbientSliceToUpdate = (nextAmbientSliceToUpdate + ambientLightSlicesToUpdateEveryFrame) % volumeSlices;

                // temporary: set global params for scatterer for testing
                Shader.SetGlobalVector(ShaderProperties.scattererLightVolumeDimensions_PROPERTY, lightVolumeDimensions);

                Shader.SetGlobalVector(ShaderProperties.scattererParaboloidPosition_PROPERTY, worldLightVolumePosition);
                Shader.SetGlobalMatrix(ShaderProperties.scattererWorldToParaboloid_PROPERTY, worldToLightVolume);

                Shader.SetGlobalFloat(ShaderProperties.scattererInnerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
                Shader.SetGlobalFloat(ShaderProperties.scattererOuterLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

                Shader.SetGlobalTexture(ShaderProperties.scattererDirectLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume]);

                updated = true;
            }
        }

        private void UpdateLightVolumeWithoutMultiSliceSupport(CloudsRaymarchedVolume volumetricLayer, ref int currentLayerDirectLightVolumeSliceToUpdate, ref int currentLayerAmbientLightVolumeSliceToUpdate)
        {
            for (int i = 0; i < directLightSlicesToUpdateEveryFrame; i++)
            {
                float verticalUV = ((float)currentLayerDirectLightVolumeSliceToUpdate + 0.5f) / (float)(volumeSlices);
                volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.verticalSliceId_PROPERTY, currentLayerDirectLightVolumeSliceToUpdate);

                RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume], currentLayerDirectLightVolumeSliceToUpdate, mergedVolumeSlices, volumetricLayer.RaymarchedCloudMaterial, 2);

                currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + 1) % volumeSlices;
            }

            for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i++)
            {
                float verticalUV = ((float)currentLayerAmbientLightVolumeSliceToUpdate + 0.5f) / (float)(volumeSlices);
                volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.verticalSliceId_PROPERTY, currentLayerAmbientLightVolumeSliceToUpdate);

                RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume], volumeSlices + currentLayerAmbientLightVolumeSliceToUpdate, mergedVolumeSlices, volumetricLayer.RaymarchedCloudMaterial, 3);

                currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % volumeSlices;
            }
        }

        private void UpdateLightVolumeWithMultiSliceSupport(CloudsRaymarchedVolume volumetricLayer, ref int currentLayerDirectLightVolumeSliceToUpdate, ref int currentLayerAmbientLightVolumeSliceToUpdate)
        {
            for (int i = 0; i < directLightSlicesToUpdateEveryFrame; i += maxSlicesInOnePass)
            {
                int slicesToUpdateThisPass = Math.Min(directLightSlicesToUpdateEveryFrame - i, maxSlicesInOnePass);

                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.startSlice_PROPERTY, currentLayerDirectLightVolumeSliceToUpdate);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.slicesToUpdate_PROPERTY, slicesToUpdateThisPass);

                Graphics.SetRenderTarget(lightVolume[readFromFlipLightVolume], 0, CubemapFace.Unknown, -1);
                Graphics.Blit(null, volumetricLayer.RaymarchedCloudMaterial, 4, -1);

                currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + maxSlicesInOnePass) % volumeSlices;
            }

            for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i += maxSlicesInOnePass)
            {
                int slicesToUpdateThisPass = Math.Min(ambientLightSlicesToUpdateEveryFrame - i, maxSlicesInOnePass);

                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.startSlice_PROPERTY, currentLayerAmbientLightVolumeSliceToUpdate);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.slicesToUpdate_PROPERTY, slicesToUpdateThisPass);

                Graphics.SetRenderTarget(lightVolume[readFromFlipLightVolume], 0, CubemapFace.Unknown, -1);
                Graphics.Blit(null, volumetricLayer.RaymarchedCloudMaterial, 5, -1);

                currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + maxSlicesInOnePass) % volumeSlices;
            }
        }

        private void UpdateSettings()
        {
            int volumeResolutionSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            int volumeSlicesSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;
            stepCount = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.StepCount;

            if (volumeResolutionSetting != volumeResolution || volumeSlicesSetting != volumeSlices)
            {
                volumeResolution = volumeResolutionSetting;
                volumeSlices = volumeSlicesSetting;
                mergedVolumeSlices = 2 * volumeSlices;
                lightVolumeDimensions = new Vector3(volumeResolution, volumeResolution, volumeSlices);

                RenderTextureUtils.ResizeFlipFlopRT(ref lightVolume, volumeResolution, volumeResolution, mergedVolumeSlices);

                if (reprojectLightVolumeComputeShader != null)
                {
                    reprojectLightVolumeComputeShader.SetVector(ShaderProperties.lightVolumeDimensions_PROPERTY, lightVolumeDimensions);
                }
                else
                {
                    reprojectLightVolumeMaterial.SetVector(ShaderProperties.lightVolumeDimensions_PROPERTY, lightVolumeDimensions);
                }
            }

            float directLightTimeSlicingFrames = RaymarchedCloudsQualityManager.LightVolumeSettings.DirectLightTimeSlicing;

            if (TimeWarp.CurrentRate > 2f)
            {
                directLightTimeSlicingFrames /= Mathf.Min(TimeWarp.CurrentRate * 0.5f, RaymarchedCloudsQualityManager.LightVolumeSettings.TimewarpRateMultiplier);
            }

            directLightSlicesToUpdateEveryFrame = Mathf.Max(volumeSlices / (int)directLightTimeSlicingFrames, 1);
            ambientLightSlicesToUpdateEveryFrame = Mathf.Max(volumeSlices / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.AmbientLightTimeSlicing, 1);
        }

        public void NotifyRenderingEnded()
        {
            updated = false;
        }

        public void Release()
        {
            if (!released)
            {
                RenderTextureUtils.ReleaseFlipFlopRT(ref lightVolume);
                released = true;
            }
        }

        private void UpdateLightVolume(Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix, float maxRadius)
        {
            UpdateCurrentLightVolumePosition(planetTransform, slowestLayerPlanetFrameDeltaRotationMatrix);

            MoveLightVolumeIfNeeded(cameraPosition, planetTransform, planetRadius, innerCloudsRadius, outerCloudsRadius, maxRadius);
        }
        private void UpdateCurrentLightVolumePosition(Transform planetTransform, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix)
        {
            // Always rotate light volume to match slowest rotating layer, kind of a hack but gives good enough results in most cases
            planetLightVolumePosition = slowestLayerPlanetFrameDeltaRotationMatrix.MultiplyPoint(planetLightVolumePosition);

            Vector3 planetPosition = planetTransform.position;

            worldLightVolumePosition = planetTransform.localToWorldMatrix.MultiplyPoint(planetLightVolumePosition);

            lightVolumeToWorld = Matrix4x4.TRS(worldLightVolumePosition, Quaternion.LookRotation((worldLightVolumePosition - planetPosition).normalized), Vector3.one);
            worldToLightVolume = Matrix4x4.Inverse(lightVolumeToWorld);
        }

        private void MoveLightVolumeIfNeeded(Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, float maxRadius)
        {
            Vector3 planetPosition = planetTransform.position;

            Vector3 cameraUpVector = cameraPosition - planetPosition;
            float cameraAltitude = cameraUpVector.magnitude;
            cameraUpVector = cameraUpVector / cameraAltitude;

            cameraAltitude = Mathf.Max(cameraAltitude, planetRadius + 2500f); // Completely arbitrary but it helps keep a certain level of detail in the distance
            planetRadius = Mathf.Min(planetRadius, innerCloudsRadius);

            // To compute paraboloid position, we have to make sure it covers everything visible until the horizon
            // Paraboloid oriented up from the planet will cover everything up to a horizontal line
            // Therefore find the vertical position ensuring said horizontal line goes as far as we can see on the horizon
            // To do that find ray angle from camera to the planet horizon, follow it to cloud sphere intersect then find the vertical offset from that intersect
            float distanceToPlanetHorizon = Mathf.Sqrt(cameraAltitude * cameraAltitude - planetRadius * planetRadius);
            float cosAngle = distanceToPlanetHorizon / cameraAltitude;

            float distanceToCloudSphereIntersect = distanceToPlanetHorizon + Mathf.Sqrt(Mathf.Max(outerCloudsRadius * outerCloudsRadius - planetRadius * planetRadius, 0f));

            // Project result to find vertical distance
            float projectedDistanceFromCameraToParaboloid = cosAngle * distanceToCloudSphereIntersect;

            float newLightVolumeAltitude = cameraAltitude - projectedDistanceFromCameraToParaboloid;

            // The effective covered radius is the horizontal line from paraboloid to sphere, which can be computed using a right triangle
            float newLightVolumeRadius = Mathf.Sqrt(distanceToCloudSphereIntersect * distanceToCloudSphereIntersect - projectedDistanceFromCameraToParaboloid * projectedDistanceFromCameraToParaboloid);

            if (maxRadius < Mathf.Infinity)
            {
                // To cap the radius, have to find the vertical point on a sphere that gives you that horizontal distance
                var cosAngleTarget = maxRadius / outerCloudsRadius;
                var sinAngleTarget = Mathf.Sqrt(1f - cosAngleTarget * cosAngleTarget);

                var verticalOffsetTarget = sinAngleTarget * outerCloudsRadius;

                // Cap it by the lower clouds radius otherwise we don't render anything
                verticalOffsetTarget = Mathf.Min(verticalOffsetTarget, innerCloudsRadius);

                newLightVolumeAltitude = Mathf.Max(verticalOffsetTarget, newLightVolumeAltitude);
            }

            Vector3 newWorldLightVolumePosition = planetPosition + cameraUpVector * newLightVolumeAltitude;

            float magnitudeMoved = (newWorldLightVolumePosition - worldLightVolumePosition).magnitude;

            if (magnitudeMoved > reprojectionThreshold * currentLightVolumeRadius || magnitudeMoved > reprojectionThreshold * newLightVolumeRadius ||
                newLightVolumeRadius > radiusReprojectionThreshold * currentLightVolumeRadius || currentLightVolumeRadius > radiusReprojectionThreshold * newLightVolumeRadius ||
                innerCloudsRadius != lightVolumeLowestAltitude || outerCloudsRadius != lightVolumeHighestAltitude)
            {
                var newLightVolumeToWorld = Matrix4x4.TRS(newWorldLightVolumePosition, Quaternion.LookRotation(cameraUpVector), Vector3.one);
                var newWorldToLightVolume = Matrix4x4.Inverse(newLightVolumeToWorld);

                ReprojectLightVolume(newWorldLightVolumePosition, newLightVolumeToWorld, innerCloudsRadius, outerCloudsRadius, planetPosition);

                // set new matrices and position as current
                readFromFlipLightVolume = !readFromFlipLightVolume;

                worldLightVolumePosition = newWorldLightVolumePosition;
                planetLightVolumePosition = planetTransform.worldToLocalMatrix.MultiplyPoint(newWorldLightVolumePosition);

                lightVolumeToWorld = newLightVolumeToWorld;
                worldToLightVolume = newWorldToLightVolume;

                currentLightVolumeRadius = newLightVolumeRadius;
                lightVolumeLowestAltitude = innerCloudsRadius;
                lightVolumeHighestAltitude = outerCloudsRadius;
            }
        }

        private void ReprojectLightVolume(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            if (reprojectLightVolumeComputeShader != null)
            {
                ReprojectWithCompute(newLightVolumePosition, newLightVolumeToWorld, innerCloudsRadius, outerCloudsRadius, planetPosition);
            }
            else
            {
                ReprojectWithMaterial(newLightVolumePosition, newLightVolumeToWorld, innerCloudsRadius, outerCloudsRadius, planetPosition);
            }
        }

        private void ReprojectWithCompute(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            uint xThreads, yThreads, zThreads; // TODO move these to init?
            reprojectLightVolumeComputeShader.GetKernelThreadGroupSizes(0, out xThreads, out yThreads, out zThreads);

            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.sphereCenter_PROPERTY, planetPosition);

            reprojectLightVolumeComputeShader.SetMatrix(ShaderProperties.worldToPreviousParaboloid_PROPERTY, worldToLightVolume);
            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.previousParaboloidPosition_PROPERTY, worldLightVolumePosition);

            reprojectLightVolumeComputeShader.SetMatrix(ShaderProperties.paraboloidToWorld_PROPERTY, newLightVolumeToWorld);
            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, newLightVolumePosition);

            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, innerCloudsRadius);
            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, outerCloudsRadius);

            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.previousInnerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.previousOuterLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

            reprojectLightVolumeComputeShader.SetTexture(0, ShaderProperties.PreviousLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume]);
            reprojectLightVolumeComputeShader.SetTexture(0, ShaderProperties.Result_PROPERTY, lightVolume[!readFromFlipLightVolume]);

            reprojectLightVolumeComputeShader.Dispatch(0, volumeResolution / (int)xThreads, volumeResolution / (int)yThreads, mergedVolumeSlices / (int)zThreads);
        }

        private void ReprojectWithMaterial(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            reprojectLightVolumeMaterial.SetVector(ShaderProperties.sphereCenter_PROPERTY, planetPosition);

            reprojectLightVolumeMaterial.SetMatrix(ShaderProperties.worldToPreviousParaboloid_PROPERTY, worldToLightVolume);
            reprojectLightVolumeMaterial.SetVector(ShaderProperties.previousParaboloidPosition_PROPERTY, worldLightVolumePosition);

            reprojectLightVolumeMaterial.SetMatrix(ShaderProperties.paraboloidToWorld_PROPERTY, newLightVolumeToWorld);
            reprojectLightVolumeMaterial.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, newLightVolumePosition);

            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, innerCloudsRadius);
            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, outerCloudsRadius);

            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.previousInnerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.previousOuterLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

            reprojectLightVolumeMaterial.SetTexture(ShaderProperties.PreviousLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume]);
            ReprojectSlices(lightVolume[!readFromFlipLightVolume]);
        }

        private void ReprojectSlices(RenderTexture targetRT)
        {
            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.ambientLightVolume_PROPERTY, 0f);

            for (int i = 0; i < volumeSlices; i++)
            {
                float verticalUV = ((float)i + 0.5f) / (float)(volumeSlices);
                reprojectLightVolumeMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);

                RenderTextureUtils.Blit3D(targetRT, i, mergedVolumeSlices, reprojectLightVolumeMaterial, 0);
            }

            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.ambientLightVolume_PROPERTY, 1f);

            for (int i = 0; i < volumeSlices; i++)
            {
                float verticalUV = ((float)i + 0.5f) / (float)(volumeSlices);
                reprojectLightVolumeMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);

                RenderTextureUtils.Blit3D(targetRT, volumeSlices + i, mergedVolumeSlices, reprojectLightVolumeMaterial, 0);
            }
        }
    }
}
