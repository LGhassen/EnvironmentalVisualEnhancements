using Utils;
using UnityEngine;
using UnityEngine.Rendering;
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
        private int volumeSlices = 0;

        private int directLightSlicesToUpdateEveryFrame, ambientLightSlicesToUpdateEveryFrame;

        private FlipFlop<RenderTexture> directLightVolume, ambientLightVolume;

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

        public LightVolume()
        {
            volumeResolution = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            volumeSlices = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;
            lightVolumeDimensions = new Vector3(volumeResolution, volumeResolution, volumeSlices);

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

            directLightVolume  = RenderTextureUtils.CreateFlipFlopRT(volumeResolution, volumeResolution, RenderTextureFormat.RHalf, FilterMode.Bilinear, TextureDimension.Tex3D, volumeSlices, useComputeShader);
            ambientLightVolume = RenderTextureUtils.CreateFlipFlopRT(volumeResolution, volumeResolution, RenderTextureFormat.RHalf, FilterMode.Bilinear, TextureDimension.Tex3D, volumeSlices, useComputeShader);
        }

        public void Update(List<CloudsRaymarchedVolume> volumes, Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix)
        {
            if (!updated && !released)
            {
                UpdateSettings();

                UpdateLightVolume(cameraPosition, planetTransform, planetRadius, innerCloudsRadius, outerCloudsRadius, slowestLayerPlanetFrameDeltaRotationMatrix);

                bool firstLayer = true;

                foreach (var volumetricLayer in volumes)
                {
                    volumetricLayer.RaymarchedCloudMaterial.SetVector("lightVolumeDimensions", lightVolumeDimensions);

                    volumetricLayer.RaymarchedCloudMaterial.SetVector("paraboloidPosition", worldLightVolumePosition);
                    volumetricLayer.RaymarchedCloudMaterial.SetMatrix("paraboloidToWorld", lightVolumeToWorld); // is this needed?
                    volumetricLayer.RaymarchedCloudMaterial.SetMatrix("worldToParaboloid", worldToLightVolume);
                    
                    volumetricLayer.RaymarchedCloudMaterial.SetFloat("innerLightVolumeRadius", lightVolumeLowestAltitude);
                    volumetricLayer.RaymarchedCloudMaterial.SetFloat("outerLightVolumeRadius", lightVolumeHighestAltitude);

                    volumetricLayer.RaymarchedCloudMaterial.SetFloat("clearExistingVolume", firstLayer ? 1f : 0f);

                    int currentLayerDirectLightVolumeSliceToUpdate = nextDirectSliceToUpdate;

                    for (int i = 0; i < directLightSlicesToUpdateEveryFrame; i++)
                    {
                        float verticalUV = ((float)currentLayerDirectLightVolumeSliceToUpdate + 0.5f) / (float)volumeSlices;
                        volumetricLayer.RaymarchedCloudMaterial.SetFloat("verticalUV", verticalUV);
                        volumetricLayer.RaymarchedCloudMaterial.SetInt("verticalSliceId", currentLayerDirectLightVolumeSliceToUpdate);

                        Blit3D(directLightVolume[readFromFlipLightVolume], currentLayerDirectLightVolumeSliceToUpdate, volumeSlices, volumetricLayer.RaymarchedCloudMaterial, 2);

                        currentLayerDirectLightVolumeSliceToUpdate = (currentLayerDirectLightVolumeSliceToUpdate + 1) % volumeSlices;
                    }

                    int currentLayerAmbientLightVolumeSliceToUpdate = nextAmbientSliceToUpdate;

                    for (int i = 0; i < ambientLightSlicesToUpdateEveryFrame; i++)
                    {
                        float verticalUV = ((float)currentLayerAmbientLightVolumeSliceToUpdate + 0.5f) / (float)volumeSlices;
                        volumetricLayer.RaymarchedCloudMaterial.SetFloat("verticalUV", verticalUV);
                        volumetricLayer.RaymarchedCloudMaterial.SetInt("verticalSliceId", currentLayerAmbientLightVolumeSliceToUpdate);

                        Blit3D(ambientLightVolume[readFromFlipLightVolume], currentLayerAmbientLightVolumeSliceToUpdate, volumeSlices, volumetricLayer.RaymarchedCloudMaterial, 3);

                        currentLayerAmbientLightVolumeSliceToUpdate = (currentLayerAmbientLightVolumeSliceToUpdate + 1) % volumeSlices;
                    }

                    volumetricLayer.RaymarchedCloudMaterial.SetTexture("directLightVolume", directLightVolume[readFromFlipLightVolume]);
                    volumetricLayer.RaymarchedCloudMaterial.SetTexture("ambientLightVolume", ambientLightVolume[readFromFlipLightVolume]);

                    firstLayer = false;
                }

                nextDirectSliceToUpdate  = (nextDirectSliceToUpdate + directLightSlicesToUpdateEveryFrame) % volumeSlices;
                nextAmbientSliceToUpdate = (nextAmbientSliceToUpdate + ambientLightSlicesToUpdateEveryFrame) % volumeSlices;

                // temporary: set global params for scatterer for testing
                Shader.SetGlobalVector("scattererLightVolumeDimensions", lightVolumeDimensions);

                Shader.SetGlobalVector("scattererParaboloidPosition", worldLightVolumePosition);
                Shader.SetGlobalMatrix("scattererWorldToParaboloid", worldToLightVolume);

                Shader.SetGlobalFloat("scattererInnerLightVolumeRadius", lightVolumeLowestAltitude);
                Shader.SetGlobalFloat("scattererOuterLightVolumeRadius", lightVolumeHighestAltitude);

                Shader.SetGlobalTexture("scattererDirectLightVolume", directLightVolume[readFromFlipLightVolume]);


                updated = true;
            }
        }

        private void UpdateSettings()
        {
            int volumeResolutionSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.HorizontalResolution;
            int volumeSlicesSetting = (int)RaymarchedCloudsQualityManager.LightVolumeSettings.VerticalResolution;

            if (volumeResolutionSetting != volumeResolution || volumeSlicesSetting != volumeSlices)
            {
                volumeResolution = volumeResolutionSetting;
                volumeSlices = volumeSlicesSetting;
                lightVolumeDimensions = new Vector3(volumeResolution, volumeResolution, volumeSlices);

                RenderTextureUtils.ResizeFlipFlopRT(ref directLightVolume, volumeResolution, volumeResolution, false, volumeSlices);
                RenderTextureUtils.ResizeFlipFlopRT(ref ambientLightVolume, volumeResolution, volumeResolution, false, volumeSlices);

                if (reprojectLightVolumeComputeShader != null)
                {
                    reprojectLightVolumeComputeShader.SetVector("lightVolumeDimensions", lightVolumeDimensions);
                }
                else
                {
                    reprojectLightVolumeMaterial.SetVector("lightVolumeDimensions", lightVolumeDimensions);
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
                RenderTextureUtils.ReleaseFlipFlopRT(ref directLightVolume);
                RenderTextureUtils.ReleaseFlipFlopRT(ref ambientLightVolume);
                released = true;
            }
        }

        private void UpdateLightVolume(Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius, Matrix4x4 slowestLayerPlanetFrameDeltaRotationMatrix)
        {
            UpdateCurrentLightVolumePosition(planetTransform, slowestLayerPlanetFrameDeltaRotationMatrix);

            MoveLightVolumeIfNeeded(cameraPosition, planetTransform, planetRadius, innerCloudsRadius, outerCloudsRadius);
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

        private void MoveLightVolumeIfNeeded(Vector3 cameraPosition, Transform planetTransform, float planetRadius, float innerCloudsRadius, float outerCloudsRadius)
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

            /*
            bool capRadius = false;
            if (capRadius)
            {
                // To cap the radius, have to find the vertical point on a sphere that gives you that horizontal distance
                var targetRadius = 200000f;

                var cosAngleTarget = targetRadius / outerCloudsRadius;
                var sinAngleTarget = Mathf.Sqrt(1f - cosAngleTarget * cosAngleTarget);

                var verticalOffsetTarget = sinAngleTarget * outerCloudsRadius;

                newLightVolumeAltitude = Mathf.Max(verticalOffsetTarget, newLightVolumeAltitude);
            }
            */

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

        // TODO: shader properties
        private void ReprojectWithCompute(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            uint xThreads, yThreads, zThreads; // TODO move these to init?
            reprojectLightVolumeComputeShader.GetKernelThreadGroupSizes(0, out xThreads, out yThreads, out zThreads);

            reprojectLightVolumeComputeShader.SetVector("sphereCenter", planetPosition);

            reprojectLightVolumeComputeShader.SetMatrix("worldToPreviousParaboloid", worldToLightVolume);
            reprojectLightVolumeComputeShader.SetVector("previousParaboloidPosition", worldLightVolumePosition);

            reprojectLightVolumeComputeShader.SetMatrix("paraboloidToWorld", newLightVolumeToWorld);
            reprojectLightVolumeComputeShader.SetVector("paraboloidPosition", newLightVolumePosition);

            reprojectLightVolumeComputeShader.SetFloat("innerLightVolumeRadius", innerCloudsRadius);
            reprojectLightVolumeComputeShader.SetFloat("outerLightVolumeRadius", outerCloudsRadius);

            reprojectLightVolumeComputeShader.SetFloat("previousInnerLightVolumeRadius", lightVolumeLowestAltitude);
            reprojectLightVolumeComputeShader.SetFloat("previousOuterLightVolumeRadius", lightVolumeHighestAltitude);

            reprojectLightVolumeComputeShader.SetTexture(0, "PreviousLightVolume", directLightVolume[readFromFlipLightVolume]);
            reprojectLightVolumeComputeShader.SetTexture(0, "Result", directLightVolume[!readFromFlipLightVolume]);

            reprojectLightVolumeComputeShader.Dispatch(0, volumeResolution / (int)xThreads, volumeResolution / (int)yThreads, volumeSlices / (int)zThreads);


            reprojectLightVolumeComputeShader.SetTexture(0, "PreviousLightVolume", ambientLightVolume[readFromFlipLightVolume]);
            reprojectLightVolumeComputeShader.SetTexture(0, "Result", ambientLightVolume[!readFromFlipLightVolume]);

            reprojectLightVolumeComputeShader.Dispatch(0, volumeResolution / (int)xThreads, volumeResolution / (int)yThreads, volumeSlices / (int)zThreads);
        }

        // TODO: shader properties
        private void ReprojectWithMaterial(Vector3 newLightVolumePosition, Matrix4x4 newLightVolumeToWorld, float innerCloudsRadius, float outerCloudsRadius, Vector3 planetPosition)
        {
            reprojectLightVolumeMaterial.SetVector("sphereCenter", planetPosition);

            reprojectLightVolumeMaterial.SetMatrix("worldToPreviousParaboloid", worldToLightVolume);
            reprojectLightVolumeMaterial.SetVector("previousParaboloidPosition", worldLightVolumePosition);

            reprojectLightVolumeMaterial.SetMatrix("paraboloidToWorld", newLightVolumeToWorld);
            reprojectLightVolumeMaterial.SetVector("paraboloidPosition", newLightVolumePosition);

            reprojectLightVolumeMaterial.SetFloat("innerLightVolumeRadius", innerCloudsRadius);
            reprojectLightVolumeMaterial.SetFloat("outerLightVolumeRadius", outerCloudsRadius);

            reprojectLightVolumeMaterial.SetFloat("previousInnerLightVolumeRadius", lightVolumeLowestAltitude);
            reprojectLightVolumeMaterial.SetFloat("previousOuterLightVolumeRadius", lightVolumeHighestAltitude);

            reprojectLightVolumeMaterial.SetTexture("PreviousLightVolume", directLightVolume[readFromFlipLightVolume]);
            ReprojectSlices(directLightVolume[!readFromFlipLightVolume]);

            reprojectLightVolumeMaterial.SetTexture("PreviousLightVolume", ambientLightVolume[readFromFlipLightVolume]);
            ReprojectSlices(ambientLightVolume[!readFromFlipLightVolume]);
        }

        // TODO: shader properties
        private void ReprojectSlices(RenderTexture targetRT)
        {
            for (int i = 0; i < volumeSlices; i++)
            {
                float verticalUV = ((float)i + 0.5f) / (float)volumeSlices;
                reprojectLightVolumeMaterial.SetFloat("verticalUV", verticalUV);
                reprojectLightVolumeMaterial.SetInt("verticalSliceId", i);

                Blit3D(targetRT, i, volumeSlices, reprojectLightVolumeMaterial, 0);
            }
        }

        // TODO move to utility class
        private void Blit3D(RenderTexture tex, int slice, int size, Material blitMat, int pass)
        {
            GL.PushMatrix();
            GL.LoadOrtho();

            Graphics.SetRenderTarget(tex, 0, CubemapFace.Unknown, slice);

            float z = Mathf.Clamp01(slice / (float)(size - 1));

            blitMat.SetPass(pass);

            GL.Begin(GL.QUADS);

            GL.TexCoord3(0, 0, z);
            GL.Vertex3(0, 0, 0);
            GL.TexCoord3(1, 0, z);
            GL.Vertex3(1, 0, 0);
            GL.TexCoord3(1, 1, z);
            GL.Vertex3(1, 1, 0);
            GL.TexCoord3(0, 1, z);
            GL.Vertex3(0, 1, 0);

            GL.End();

            GL.PopMatrix();
        }
    }
}
