using Utils;
using UnityEngine;
using UnityEngine.Rendering;
using System;
using System.Collections.Generic;
using ShaderLoader;
using static Atmosphere.DeferredRaymarchedVolumetricCloudsRenderer;

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
                    instance.Init();
                }
                return instance;
            }
        }

        private int horizontalResolution = 0;
        private int verticalResolution = 0;           // volume slices of a single direct or ambient volume
        private int mergedVerticalResolution = 0;     // total slices of the combined volume holding both
        private int stepCount = 0;
        private static readonly int maxSlicesInOnePass = 16; // Max slices of a 3d texture the shader can output to in a single pass
                                                             // (capped by using a geometry shader to write to multiple slices of 3d texture)
                                                             // Could get around this by using an instanced draw where every instances creates 16 geom slices

        private int directLightSlicesToUpdateEveryFrame, ambientLightSlicesToUpdateEveryFrame;

        // The first slices are for direct light, and the second half for ambient. The volumes are combined
        // to save a texture slot on Macs which have a hidden 16 texture limit in OpenGL (regardless of samplers)
        private HistoryManager<RenderTexture> lightVolume;

        private ComputeShader reprojectLightVolumeComputeShader = null;
        private uint reprojectLightVolumeComputeShaderXThreads, reprojectLightVolumeComputeShaderYThreads, reprojectLightVolumeComputeShaderZThreads;
        private static Shader reprojectLightVolumeShader = null;
        private static Shader lightVolumeShadowShader = null;
        private Material reprojectLightVolumeMaterial, lightVolumeShadowMaterial;
        private bool readFromFlipLightVolume = true;
        private int nextDirectSliceToUpdate = 0, nextAmbientSliceToUpdate = 0;
        private int ambientUpdateCounter = 0;

        private Vector3 planetLightVolumePosition = Vector3.zero;
        private Vector3 worldLightVolumePosition = Vector3.zero;

        private Matrix4x4 lightVolumeToWorld = Matrix4x4.identity;
        private Matrix4x4 worldToLightVolume = Matrix4x4.identity;

        private float currentLightVolumeRadius;

        private Vector3 lightVolumeDimensions = Vector3.zero;
        private float lightVolumeLowestAltitude = 0f, lightVolumeHighestAltitude = 0f;

        private const float reprojectionThreshold = 0.03f;
        private const float radiusReprojectionThreshold = 1f + reprojectionThreshold;
        private Light sunlight;

        private static Shader ReprojectLightVolumeShader
        {
            get
            {
                if (reprojectLightVolumeShader == null) reprojectLightVolumeShader = ShaderLoaderClass.FindShader("EVE/ReprojectLightVolume");
                return reprojectLightVolumeShader;
            }
        }

        private static Shader LightVolumeShadowShader
        {
            get
            {
                if (lightVolumeShadowShader == null)
                {
                    lightVolumeShadowShader = ShaderLoaderClass.FindShader("EVE/LightVolumeShadow");
                }

                return lightVolumeShadowShader;
            }
        }

        private bool updatedThisFrame = false;
        private bool released = false;
        private bool useMultiSliceUpdate = false;

        public void Init()
        {
            horizontalResolution = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            verticalResolution = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;
            mergedVerticalResolution = verticalResolution * 2;
            stepCount = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.StepCount;
            lightVolumeDimensions = new Vector3(horizontalResolution, verticalResolution, horizontalResolution);

            useMultiSliceUpdate = SystemInfo.graphicsDeviceVersion.Contains("Direct3D");

            bool useComputeShader = SystemInfo.supportsComputeShaders && SystemInfo.graphicsDeviceVersion.Contains("Direct3D");
            
            
            useComputeShader = false;
            //useMultiSliceUpdate = false;


            if (useComputeShader)
            { 
                reprojectLightVolumeComputeShader = ShaderLoaderClass.FindComputeShader("ReprojectLightVolume");
                reprojectLightVolumeComputeShader.GetKernelThreadGroupSizes(0, out reprojectLightVolumeComputeShaderXThreads, out reprojectLightVolumeComputeShaderYThreads, out reprojectLightVolumeComputeShaderZThreads);

                reprojectLightVolumeComputeShader.SetVector("lightVolumeDimensions", lightVolumeDimensions);
            }
            else
            {
                reprojectLightVolumeMaterial = new Material(ReprojectLightVolumeShader);
                reprojectLightVolumeMaterial.SetVector("lightVolumeDimensions", lightVolumeDimensions);
            }

            directLightSlicesToUpdateEveryFrame  = Mathf.Max(horizontalResolution / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.DirectLightTimeSlicing,  1);
            ambientLightSlicesToUpdateEveryFrame = Mathf.Max(horizontalResolution / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.AmbientLightTimeSlicing, 1);

            //lightVolume = RenderTextureUtils.CreateRTHistoryManager(true, false, false, volumeResolution, volumeResolution, RenderTextureFormat.RHalf, FilterMode.Bilinear, TextureDimension.Tex3D, mergedVolumeSlices, useComputeShader, TextureWrapMode.Clamp);
            lightVolume = RenderTextureUtils.CreateRTHistoryManager(true, false, false, horizontalResolution, mergedVerticalResolution, RenderTextureFormat.RHalf, FilterMode.Bilinear, TextureDimension.Tex3D, horizontalResolution, useComputeShader, TextureWrapMode.Clamp);

            lightVolumeShadowMaterial = new Material(LightVolumeShadowShader);
            sunlight = Sun.Instance.GetComponent<Light>();
        }

        public void Update(List<CloudsRaymarchedVolume> volumes, Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix, float maxRadius)
        {
            if (!updatedThisFrame && !released)
            {
                CommandBuffer cb = new CommandBuffer();
                cb.BeginSample("EVE LightVolumeUpdate");
                cb.name = "EVE LightVolumeUpdate";
                Graphics.ExecuteCommandBuffer(cb);

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

                        UpdateLightVolume(volumetricLayer, nextDirectSliceToUpdate, nextAmbientSliceToUpdate);

                        volumetricLayer.RaymarchedCloudMaterial.SetTexture(ShaderProperties.lightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);


                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetVector(ShaderProperties.lightVolumeDimensions_PROPERTY, lightVolumeDimensions);

                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, worldLightVolumePosition);
                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetMatrix(ShaderProperties.paraboloidToWorld_PROPERTY, lightVolumeToWorld); // is this needed?
                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetMatrix(ShaderProperties.worldToParaboloid_PROPERTY, worldToLightVolume);

                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.clearExistingVolume_PROPERTY, firstLayer ? 1f : 0f); // Not needed here

                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetFloat(ShaderProperties.lightVolumeLightMarchSteps_PROPERTY, stepCount);

                        volumetricLayer.ReflectionProbeRaymarchedCloudMaterial.SetTexture(ShaderProperties.lightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);

                        firstLayer = false;
                    }
                }

                BlendNewAmbientRays(nextAmbientSliceToUpdate);

                /*
                nextDirectSliceToUpdate = (nextDirectSliceToUpdate + directLightSlicesToUpdateEveryFrame) % verticalResolution;
                nextAmbientSliceToUpdate = (nextAmbientSliceToUpdate + ambientLightSlicesToUpdateEveryFrame) % verticalResolution;
                */

                nextDirectSliceToUpdate = (nextDirectSliceToUpdate + directLightSlicesToUpdateEveryFrame) % horizontalResolution;
                nextAmbientSliceToUpdate = (nextAmbientSliceToUpdate + ambientLightSlicesToUpdateEveryFrame) % horizontalResolution;

                // temporary: set global params for scatterer for testing
                Shader.SetGlobalVector(ShaderProperties.scattererLightVolumeDimensions_PROPERTY, lightVolumeDimensions);

                Shader.SetGlobalVector(ShaderProperties.scattererParaboloidPosition_PROPERTY, worldLightVolumePosition);
                Shader.SetGlobalMatrix(ShaderProperties.scattererWorldToParaboloid_PROPERTY, worldToLightVolume);

                Shader.SetGlobalFloat(ShaderProperties.scattererInnerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
                Shader.SetGlobalFloat(ShaderProperties.scattererOuterLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

                Shader.SetGlobalTexture(ShaderProperties.scattererDirectLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);

                lightVolumeShadowMaterial.SetVector(ShaderProperties.lightVolumeDimensions_PROPERTY, lightVolumeDimensions);
                lightVolumeShadowMaterial.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, worldLightVolumePosition);
                lightVolumeShadowMaterial.SetMatrix(ShaderProperties.worldToParaboloid_PROPERTY, worldToLightVolume);
                lightVolumeShadowMaterial.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
                lightVolumeShadowMaterial.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);
                lightVolumeShadowMaterial.SetTexture(ShaderProperties.lightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);
                lightVolumeShadowMaterial.SetVector(ShaderProperties.planetCenter_PROPERTY, planetPosition);
                lightVolumeShadowMaterial.SetFloat(ShaderProperties.planetRadius_PROPERTY, planetRadius);
                lightVolumeShadowMaterial.SetVector(ShaderProperties.lightDirection_PROPERTY, Vector3.Normalize(-sunlight.transform.forward));

                ScreenSpaceShadowsManager.Instance.UpdateLightVolumeShadowMaterial(lightVolumeShadowMaterial);

                updatedThisFrame = true;

                CommandBuffer cb2 = new CommandBuffer();
                cb2.EndSample("EVE LightVolumeUpdate");
                cb2.name = "EVE LightVolumeUpdate2";
                Graphics.ExecuteCommandBuffer(cb2);
            }
        }

        private void UpdateLightVolume(CloudsRaymarchedVolume volumetricLayer, int nextDirectSliceToUpdate, int nextAmbientSliceToUpdate)
        {
            if (useMultiSliceUpdate)
            {
                UpdateLightVolumeWithMultiSliceSupport(volumetricLayer, nextDirectSliceToUpdate, nextAmbientSliceToUpdate);
            }
            else
            {
                UpdateLightVolumeWithoutMultiSliceSupport(volumetricLayer, nextDirectSliceToUpdate, nextAmbientSliceToUpdate);
            }
        }

        private void UpdateLightVolumeWithoutMultiSliceSupport(CloudsRaymarchedVolume volumetricLayer, int nextDirectSliceToUpdate, int nextAmbientSliceToUpdate)
        {
            int currentLayerDirectLightVolumeSliceToUpdate = nextDirectSliceToUpdate;

            for (int i = 0; i < directLightSlicesToUpdateEveryFrame; i++)
            {
                /*
                float verticalUV = ((float)currentLayerDirectLightVolumeSliceToUpdate + 0.5f) / (float)(verticalResolution);
                volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.verticalSliceId_PROPERTY, currentLayerDirectLightVolumeSliceToUpdate);
                */

                float horizontalUV = ((float)currentLayerDirectLightVolumeSliceToUpdate + 0.5f) / (float)(horizontalResolution);
                volumetricLayer.RaymarchedCloudMaterial.SetFloat("horizontalUV", horizontalUV);
                volumetricLayer.RaymarchedCloudMaterial.SetInt("horizontalSliceId", currentLayerDirectLightVolumeSliceToUpdate);

                //RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume, false, 0], currentLayerDirectLightVolumeSliceToUpdate, mergedVerticalResolution, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeDirectSingleSlice);
                RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume, false, 0], currentLayerDirectLightVolumeSliceToUpdate, horizontalResolution, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeDirectSingleSlice);

                //currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + 1) % verticalResolution;
                currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + 1) % horizontalResolution;
            }


            
            int currentLayerAmbientLightVolumeSliceToUpdate = nextAmbientSliceToUpdate;

            // For ambient, we first need to render out new rays which are stochastic/random and then blend them with the available history
            // Therefore write to the other buffer as a "scratch" buffer then do the blending separately
            bool ambientWriteToFlip = !readFromFlipLightVolume;

            //int ambientUpdateNumber = Time.frameCount / (verticalResolution / ambientLightSlicesToUpdateEveryFrame);
            int ambientUpdateNumber = Time.frameCount / (horizontalResolution / ambientLightSlicesToUpdateEveryFrame);

            volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.ambientUpdateNumber_PROPERTY, ambientUpdateNumber);   // TODO: check what this is for

            for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i++)
            {
                
                //float verticalUV = ((float)currentLayerAmbientLightVolumeSliceToUpdate + 0.5f) / (float)(verticalResolution);
                //volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.verticalUV_PROPERTY, verticalUV);
                //volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.verticalSliceId_PROPERTY, currentLayerAmbientLightVolumeSliceToUpdate);
                

                float horizontalUV = ((float)currentLayerAmbientLightVolumeSliceToUpdate + 0.5f) / (float)(horizontalResolution);
                volumetricLayer.RaymarchedCloudMaterial.SetFloat("horizontalUV", horizontalUV);
                volumetricLayer.RaymarchedCloudMaterial.SetInt("horizontalSliceId", currentLayerAmbientLightVolumeSliceToUpdate);

                //RenderTextureUtils.Blit3D(lightVolume[ambientWriteToFlip, false, 0], verticalResolution + currentLayerAmbientLightVolumeSliceToUpdate, mergedVerticalResolution, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeAmbientSingleSlice);

                // Note: the slice is the same now but we'll need a different position in the vertex shader
                RenderTextureUtils.Blit3D(lightVolume[ambientWriteToFlip, false, 0], currentLayerAmbientLightVolumeSliceToUpdate, horizontalResolution, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeAmbientSingleSlice);

                //currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % verticalResolution;
                currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % horizontalResolution;
            }
        }

        
        private void UpdateLightVolumeWithMultiSliceSupport(CloudsRaymarchedVolume volumetricLayer, int nextDirectSliceToUpdate, int nextAmbientSliceToUpdate)
        {
            int currentLayerDirectLightVolumeSliceToUpdate = nextDirectSliceToUpdate;

            for (int i = 0; i < directLightSlicesToUpdateEveryFrame; i += maxSlicesInOnePass)
            {
                int slicesToUpdateThisPass = Math.Min(directLightSlicesToUpdateEveryFrame - i, maxSlicesInOnePass);

                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.startSlice_PROPERTY, currentLayerDirectLightVolumeSliceToUpdate);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.slicesToUpdate_PROPERTY, slicesToUpdateThisPass);

                Graphics.SetRenderTarget(lightVolume[readFromFlipLightVolume, false, 0], 0, CubemapFace.Unknown, -1);
                Graphics.Blit(null, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeDirectMultiSlice, -1);

                //currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + maxSlicesInOnePass) % verticalResolution;
                currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + maxSlicesInOnePass) % horizontalResolution;
            }

            int currentLayerAmbientLightVolumeSliceToUpdate = nextAmbientSliceToUpdate;
            // For ambient, we first need to render out new rays which are stochastic/random and then blend them with the available history
            // Therefore write to the other buffer as a "scratch" buffer then do the blending separately
            bool ambientWriteToFlip = !readFromFlipLightVolume;

            // This can create a divide by zero?
            //int ambientUpdateNumber = Time.frameCount / (verticalResolution / ambientLightSlicesToUpdateEveryFrame);
            int ambientUpdateNumber = Time.frameCount / (horizontalResolution / ambientLightSlicesToUpdateEveryFrame);

            volumetricLayer.RaymarchedCloudMaterial.SetFloat(ShaderProperties.ambientUpdateNumber_PROPERTY, ambientUpdateNumber);

            for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i += maxSlicesInOnePass)
            {
                int slicesToUpdateThisPass = Math.Min(ambientLightSlicesToUpdateEveryFrame - i, maxSlicesInOnePass);

                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.startSlice_PROPERTY, currentLayerAmbientLightVolumeSliceToUpdate);
                volumetricLayer.RaymarchedCloudMaterial.SetInt(ShaderProperties.slicesToUpdate_PROPERTY, slicesToUpdateThisPass);

                Graphics.SetRenderTarget(lightVolume[ambientWriteToFlip, false, 0], 0, CubemapFace.Unknown, -1);
                Graphics.Blit(null, volumetricLayer.RaymarchedCloudMaterial, RaymarchedCloudShaderPassName.UpdateLightVolumeAmbientMultiSlice, -1);

                //currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + maxSlicesInOnePass) % verticalResolution;
                currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + maxSlicesInOnePass) % horizontalResolution;
            }
        }

        // New ambient rays are stochastic/random, we now need to blend them with the history
        private void BlendNewAmbientRays(int nextAmbientSliceToUpdate)
        {
            ambientUpdateCounter++;

            //int totalFullAmbientUpdatesDone = ambientUpdateCounter / (verticalResolution / ambientLightSlicesToUpdateEveryFrame);
            int totalFullAmbientUpdatesDone = ambientUpdateCounter / (horizontalResolution / ambientLightSlicesToUpdateEveryFrame);

            float ambientBlendFactor = 1f / Mathf.Max(1f, totalFullAmbientUpdatesDone);
            ambientBlendFactor = Mathf.Clamp(ambientBlendFactor, 0.01f, 0.07f);
            //ambientBlendFactor = 0.5f;

            //ambientBlendFactor = 1f;
            ambientBlendFactor = 0.2f; // to test it works, works perfectly

            /*
            if (reprojectLightVolumeComputeShader != null)
            {
                BlendNewAmbientRaysWithCompute(nextAmbientSliceToUpdate, ambientBlendFactor);
            }
            else
            */
            {
                BlendNewAmbientRaysWithMaterial(nextAmbientSliceToUpdate, ambientBlendFactor);
            }
        }

        /*
        private void BlendNewAmbientRaysWithCompute(int nextAmbientSliceToUpdate, float ambientBlendFactor)
        {
            reprojectLightVolumeComputeShader.SetInt(ShaderProperties.startSlice_PROPERTY, nextAmbientSliceToUpdate);
            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.ambientBlendingFactor_PROPERTY, ambientBlendFactor);

            // Switch the rendertarget otherwise we can't read from it
            Graphics.SetRenderTarget(lightVolume[readFromFlipLightVolume, false, 0], 0, CubemapFace.Unknown, -1);

            reprojectLightVolumeComputeShader.SetTexture(1, ShaderProperties.NewAmbientVolumeRays_PROPERTY, lightVolume[!readFromFlipLightVolume, false, 0]);
            reprojectLightVolumeComputeShader.SetTexture(1, ShaderProperties.Result_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);

            // z contains the number of slices to update
            reprojectLightVolumeComputeShader.Dispatch(1, horizontalResolution / (int)reprojectLightVolumeComputeShaderXThreads, horizontalResolution / (int)reprojectLightVolumeComputeShaderYThreads, ambientLightSlicesToUpdateEveryFrame / (int)reprojectLightVolumeComputeShaderZThreads);
        }
        */

        private void BlendNewAmbientRaysWithMaterial(int nextAmbientSliceToUpdate, float ambientBlendFactor)
        {
            int currentLayerAmbientLightVolumeSliceToUpdate = nextAmbientSliceToUpdate;

            reprojectLightVolumeMaterial.SetFloat(ShaderProperties.ambientBlendingFactor_PROPERTY, ambientBlendFactor);

            // Switch the rendertarget otherwise we can't read from it
            Graphics.SetRenderTarget(lightVolume[readFromFlipLightVolume, false, 0], 0, CubemapFace.Unknown, -1);

            reprojectLightVolumeMaterial.SetTexture(ShaderProperties.NewAmbientVolumeRays_PROPERTY, lightVolume[!readFromFlipLightVolume, false, 0]);

            for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i++)
            {
                //reprojectLightVolumeMaterial.SetInt(ShaderProperties.verticalSliceId_PROPERTY, verticalResolution + currentLayerAmbientLightVolumeSliceToUpdate);

                float horizontalUV = ((float)currentLayerAmbientLightVolumeSliceToUpdate + 0.5f) / (float)(horizontalResolution);
                reprojectLightVolumeMaterial.SetFloat("horizontalUV", horizontalUV);
                reprojectLightVolumeMaterial.SetInt("horizontalSliceId", currentLayerAmbientLightVolumeSliceToUpdate);

                //RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume, false, 0], verticalResolution + currentLayerAmbientLightVolumeSliceToUpdate, mergedVerticalResolution, reprojectLightVolumeMaterial, 1);
                RenderTextureUtils.Blit3D(lightVolume[readFromFlipLightVolume, false, 0], currentLayerAmbientLightVolumeSliceToUpdate, mergedVerticalResolution, reprojectLightVolumeMaterial, 1);

                //currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % verticalResolution;
                currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % horizontalResolution;
            }
        }

        private void UpdateSettings()
        {
            int volumeResolutionSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            int volumeSlicesSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;
            stepCount = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.StepCount;

            if (volumeResolutionSetting != horizontalResolution || volumeSlicesSetting != verticalResolution)
            {
                horizontalResolution = volumeResolutionSetting;
                verticalResolution = volumeSlicesSetting;
                mergedVerticalResolution = 2 * verticalResolution;
                //lightVolumeDimensions = new Vector3(horizontalResolution, horizontalResolution, verticalResolution);
                lightVolumeDimensions = new Vector3(horizontalResolution, verticalResolution, horizontalResolution);

                //RenderTextureUtils.ResizeRTHistoryManager(lightVolume, horizontalResolution, horizontalResolution, mergedVerticalResolution);
                RenderTextureUtils.ResizeRTHistoryManager(lightVolume, horizontalResolution, mergedVerticalResolution, horizontalResolution);

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

            // TODO: make function because this is duplicated with the constructor
            /*
            directLightSlicesToUpdateEveryFrame = Mathf.Max(verticalResolution / (int)directLightTimeSlicingFrames, 1);
            ambientLightSlicesToUpdateEveryFrame = Mathf.Max(verticalResolution / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.AmbientLightTimeSlicing, 1);
            */

            directLightSlicesToUpdateEveryFrame  = Mathf.Max(horizontalResolution / (int)directLightTimeSlicingFrames, 1);
            ambientLightSlicesToUpdateEveryFrame = Mathf.Max(horizontalResolution / (int)RaymarchedCloudsQualityManager.LightVolumeSettings.AmbientLightTimeSlicing, 1);
        }

        public void NotifyRenderingEnded()
        {
            updatedThisFrame = false;
        }

        public void Release()
        {
            if (!released)
            {
                RenderTextureUtils.ReleaseRTHistoryManager(lightVolume);
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

        Vector3 planetPosition;

        private void MoveLightVolumeIfNeeded(Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, float maxRadius)
        {
            planetPosition = planetTransform.position;

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

                // Reset ambient update counter to converge faster
                ambientUpdateCounter = 0;

                // Set new matrices and position as current
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
            /*
            if (reprojectLightVolumeComputeShader != null)
            {
                ReprojectWithCompute(newLightVolumePosition, newLightVolumeToWorld, innerCloudsRadius, outerCloudsRadius, planetPosition);
            }
            else
            */
            {
                ReprojectWithMaterial(newLightVolumePosition, newLightVolumeToWorld, innerCloudsRadius, outerCloudsRadius, planetPosition);
            }
        }

        /*
        private void ReprojectWithCompute(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.sphereCenter_PROPERTY, planetPosition);

            reprojectLightVolumeComputeShader.SetMatrix(ShaderProperties.worldToPreviousParaboloid_PROPERTY, worldToLightVolume);
            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.previousParaboloidPosition_PROPERTY, worldLightVolumePosition);

            reprojectLightVolumeComputeShader.SetMatrix(ShaderProperties.paraboloidToWorld_PROPERTY, newLightVolumeToWorld);
            reprojectLightVolumeComputeShader.SetVector(ShaderProperties.paraboloidPosition_PROPERTY, newLightVolumePosition);

            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.innerLightVolumeRadius_PROPERTY, innerCloudsRadius);
            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.outerLightVolumeRadius_PROPERTY, outerCloudsRadius);

            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.previousInnerLightVolumeRadius_PROPERTY, lightVolumeLowestAltitude);
            reprojectLightVolumeComputeShader.SetFloat(ShaderProperties.previousOuterLightVolumeRadius_PROPERTY, lightVolumeHighestAltitude);

            reprojectLightVolumeComputeShader.SetTexture(0, ShaderProperties.PreviousLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);
            reprojectLightVolumeComputeShader.SetTexture(0, ShaderProperties.Result_PROPERTY, lightVolume[!readFromFlipLightVolume, false, 0]);

            reprojectLightVolumeComputeShader.Dispatch(0, horizontalResolution / (int)reprojectLightVolumeComputeShaderXThreads, horizontalResolution / (int)reprojectLightVolumeComputeShaderYThreads, mergedVerticalResolution / (int)reprojectLightVolumeComputeShaderZThreads);
        }
        */

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

            reprojectLightVolumeMaterial.SetTexture(ShaderProperties.PreviousLightVolume_PROPERTY, lightVolume[readFromFlipLightVolume, false, 0]);
            ReprojectSlices(lightVolume[!readFromFlipLightVolume, false, 0]);
        }

        private void ReprojectSlices(RenderTexture targetRT)
        {
            for (int i = 0; i < horizontalResolution; i++)
            {
                float horizontalUV = ((float)i + 0.5f) / (float)(horizontalResolution);
                reprojectLightVolumeMaterial.SetFloat("horizontalUV", horizontalUV);
                RenderTextureUtils.Blit3D(targetRT, i, horizontalResolution, reprojectLightVolumeMaterial, 0);
            }
        }
    }
}
