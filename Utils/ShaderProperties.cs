using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

namespace Utils
{

    [KSPAddon(KSPAddon.Startup.Instantly, true)]
    public class ShaderProperties : MonoBehaviour
    {

        public static int ROTATION_PROPERTY { get { return _Rotation; } }
        private static int _Rotation;
        public static int _PosRotation_Property { get { return _PosRotation; } }
        private static int _PosRotation;
        public static int INVROTATION_PROPERTY { get { return _InvRotation; } }
        private static int _InvRotation;
        public static int MAIN_ROTATION_PROPERTY { get { return _MainRotation; } }
        private static int _MainRotation;
        public static int DETAIL_ROTATION_PROPERTY { get { return _DetailRotation; } }
        private static int _DetailRotation;
        public static int SHADOWOFFSET_PROPERTY { get { return _ShadowOffset; } }
        private static int _ShadowOffset;
        public static int SUNDIR_PROPERTY { get { return _SunDir; } }
        private static int _SunDir;
        public static int PLANET_ORIGIN_PROPERTY { get { return _PlanetOrigin; } }
        private static int _PlanetOrigin;
        public static int WORLD_2_PLANET_PROPERTY { get { return _World2Planet; } }
        private static int _World2Planet;

        public static int _MainTex_PROPERTY { get { return _MainTex; } }
        private static int _MainTex;
        public static int _BumpMap_PROPERTY { get { return _BumpMap; } }
        private static int _BumpMap;
        public static int _Emissive_PROPERTY { get { return _Emissive; } }
        private static int _Emissive;
        public static int _SunRadius_PROPERTY { get { return _SunRadius; } }
        private static int _SunRadius;
        public static int _SunPos_PROPERTY { get { return _SunPos; } }
        private static int _SunPos;
        public static int _ShadowBodies_PROPERTY { get { return _ShadowBodies; } }
        private static int _ShadowBodies;
        public static int _UniveralTime_PROPERTY { get { return _UniversalTime; } }
        private static int _UniversalTime;

        public static int rendererEnabled_PROPERTY { get { return _rendererEnabled; } }
        private static int _rendererEnabled;

        public static int flowLoopTime_PROPERTY { get { return flowLoopTime; } }
        private static int flowLoopTime;

        public static int scaledCloudFade_PROPERTY { get { return scaledCloudFade; } }
        private static int scaledCloudFade;

        public static int cloudTimeFadeDensity_PROPERTY { get { return cloudTimeFadeDensity; } }
        private static int cloudTimeFadeDensity;

        public static int cloudTimeFadeCoverage_PROPERTY { get { return cloudTimeFadeCoverage; } }
        private static int cloudTimeFadeCoverage;

        public static int timeDelta_PROPERTY { get { return timeDelta; } }
        private static int timeDelta;

        public static int shadowCasterCloudRotation_PROPERTY { get { return shadowCasterCloudRotation; } }
        private static int shadowCasterCloudRotation;

        public static int _ShadowDetailRotation_PROPERTY { get { return _ShadowDetailRotation; } }
        private static int _ShadowDetailRotation;

        public static int shadowCasterTimeFadeDensity_PROPERTY { get { return shadowCasterTimeFadeDensity; } }
        private static int shadowCasterTimeFadeDensity;

        public static int shadowCasterTimeFadeCoverage_PROPERTY { get { return shadowCasterTimeFadeCoverage; } }
        private static int shadowCasterTimeFadeCoverage;

        public static int timeFadeDensity_PROPERTY { get { return timeFadeDensity; } }
        private static int timeFadeDensity;

        public static int timeFadeCoverage_PROPERTY { get { return timeFadeCoverage; } }
        private static int timeFadeCoverage;

        public static int frameNumber_PROPERTY { get { return frameNumber; } }
        private static int frameNumber;

        public static int useOrbitMode_PROPERTY { get { return useOrbitMode; } }
        private static int useOrbitMode;

        public static int useCombinedOpenGLDistanceBuffer_PROPERTY { get { return useCombinedOpenGLDistanceBuffer; } }
        private static int useCombinedOpenGLDistanceBuffer;

        public static int combinedOpenGLDistanceBuffer_PROPERTY { get { return combinedOpenGLDistanceBuffer; } }
        private static int combinedOpenGLDistanceBuffer;

        public static int reconstructedTextureResolution_PROPERTY { get { return reconstructedTextureResolution; } }
        private static int reconstructedTextureResolution;

        public static int invReconstructedTextureResolution_PROPERTY { get { return invReconstructedTextureResolution; } }
        private static int invReconstructedTextureResolution;

        public static int paddedReconstructedTextureResolution_PROPERTY { get { return paddedReconstructedTextureResolution; } }
        private static int paddedReconstructedTextureResolution;
        
        public static int reprojectionXfactor_PROPERTY { get { return reprojectionXfactor; } }
        private static int reprojectionXfactor;

        public static int reprojectionYfactor_PROPERTY { get { return reprojectionYfactor; } }
        private static int reprojectionYfactor;

        public static int CameraToWorld_PROPERTY { get { return CameraToWorld; } }
        private static int CameraToWorld;

        public static int reprojectionUVOffset_PROPERTY { get { return reprojectionUVOffset; } }
        private static int reprojectionUVOffset;

        public static int currentVP_PROPERTY { get { return currentVP; } }
        private static int currentVP;

        public static int previousVP_PROPERTY { get { return previousVP; } }
        private static int previousVP;

        public static int isFirstLayerRendered_PROPERTY { get { return isFirstLayerRendered; } }
        private static int isFirstLayerRendered;

        public static int isFirstLightningLayerRendered_PROPERTY { get { return isFirstLightningLayerRendered; } }
        private static int isFirstLightningLayerRendered;

        public static int renderSecondLayerIntersect_PROPERTY { get { return renderSecondLayerIntersect; } }
        private static int renderSecondLayerIntersect;

        public static int PreviousLayerRays_PROPERTY { get { return PreviousLayerRays; } }
        private static int PreviousLayerRays;

        public static int PreviousLayerLightningOcclusion_PROPERTY { get { return PreviousLayerLightningOcclusion; } }
        private static int PreviousLayerLightningOcclusion;

        public static int scattererReconstructedCloud_PROPERTY { get { return scattererReconstructedCloud; } }
        private static int scattererReconstructedCloud;

        public static int scattererCloudLightVolumeEnabled_PROPERTY { get { return scattererCloudLightVolumeEnabled; } }
        private static int scattererCloudLightVolumeEnabled;

        public static int historyBuffer_PROPERTY { get { return historyBuffer; } }
        private static int historyBuffer;

        public static int historyMotionVectors_PROPERTY { get { return historyMotionVectors; } }
        private static int historyMotionVectors;

        public static int newRaysBuffer_PROPERTY { get { return newRaysBuffer; } }
        private static int newRaysBuffer;

        public static int newRaysBufferBilinear_PROPERTY { get { return newRaysBufferBilinear; } }
        private static int newRaysBufferBilinear;

        public static int newRaysMotionVectors_PROPERTY { get { return newRaysMotionVectors; } }
        private static int newRaysMotionVectors;

        public static int innerSphereRadius_PROPERTY { get { return innerSphereRadius; } }
        private static int innerSphereRadius;

        public static int outerSphereRadius_PROPERTY { get { return outerSphereRadius; } }
        private static int outerSphereRadius;

        public static int outerLayerRadius_PROPERTY { get { return outerLayerRadius; } }
        private static int outerLayerRadius;

        public static int planetRadius_PROPERTY { get { return planetRadius; } }
        private static int planetRadius;

        public static int sphereCenter_PROPERTY { get { return sphereCenter; } }
        private static int sphereCenter;

        public static int colorBuffer_PROPERTY { get { return colorBuffer; } }
        private static int colorBuffer;

        public static int lightningOcclusion_PROPERTY { get { return lightningOcclusion; } }
        private static int lightningOcclusion;

        public static int cloudFade_PROPERTY { get { return cloudFade; } }
        private static int cloudFade;

        public static int maxConcurrentLightning_PROPERTY { get { return maxConcurrentLightning; } }
        private static int maxConcurrentLightning;

        public static int lightningIndex_PROPERTY { get { return lightningIndex; } }
        private static int lightningIndex;

        public static int lightningCount_PROPERTY { get { return lightningCount; } }
        private static int lightningCount;

        public static int lightningArray_PROPERTY { get { return lightningArray; } }
        private static int lightningArray;

        public static int lightningColorsArray_PROPERTY { get { return lightningColorsArray; } }
        private static int lightningColorsArray;

        public static int lightningTransformsArray_PROPERTY { get { return lightningTransformsArray; } }
        private static int lightningTransformsArray;

        public static int alpha_PROPERTY { get { return alpha; } }
        private static int alpha;

        public static int color_PROPERTY { get { return color; } }
        private static int color;

        public static int randomIndexes_PROPERTY { get { return randomIndexes; } }
        private static int randomIndexes;

        public static int lightningSheetCount_PROPERTY { get { return lightningSheetCount; } }
        private static int lightningSheetCount;

        public static int gravityVector_PROPERTY { get { return gravityVector; } }
        private static int gravityVector;

        public static int rotationMatrix_PROPERTY { get { return rotationMatrix; } }
        private static int rotationMatrix;

        public static int offset_PROPERTY { get { return offset; } }
        private static int offset;

        public static int fade_PROPERTY { get { return fade; } }
        private static int fade;

        public static int coverage_PROPERTY { get { return coverage; } }
        private static int coverage;

        public static int cameraToWorldMatrix_PROPERTY { get { return cameraToWorldMatrix; } }
        private static int cameraToWorldMatrix;

        public static int worldSpaceCameraForwardDirection_PROPERTY { get { return worldSpaceCameraForwardDirection; } }
        private static int worldSpaceCameraForwardDirection;

        public static int baseNoiseOffsets_PROPERTY { get { return baseNoiseOffsets; } }
        private static int baseNoiseOffsets;

        public static int noTileNoiseOffsets_PROPERTY { get { return noTileNoiseOffsets; } }
        private static int noTileNoiseOffsets;

        public static int detailOffset_PROPERTY { get { return detailOffset; } }
        private static int detailOffset;

        public static int noTileNoiseDetailOffset_PROPERTY { get { return noTileNoiseDetailOffset; } }
        private static int noTileNoiseDetailOffset;

        public static int curlNoiseOffset_PROPERTY { get { return curlNoiseOffset; } }
        private static int curlNoiseOffset;

        public static int cloudRotation_PROPERTY { get { return cloudRotation; } }
        private static int cloudRotation;

        public static int cloudDetailRotation_PROPERTY { get { return cloudDetailRotation; } }
        private static int cloudDetailRotation;

        public static int reprojectionCurrentPixel_PROPERTY { get { return reprojectionCurrentPixel; } }
        private static int reprojectionCurrentPixel;

        public static int lightVolumeDimensions_PROPERTY { get { return lightVolumeDimensions; } }
        private static int lightVolumeDimensions;

        public static int paraboloidPosition_PROPERTY { get { return paraboloidPosition; } }
        private static int paraboloidPosition;

        public static int paraboloidToWorld_PROPERTY { get { return paraboloidToWorld; } }
        private static int paraboloidToWorld;

        public static int worldToParaboloid_PROPERTY { get { return worldToParaboloid; } }
        private static int worldToParaboloid;

        public static int innerLightVolumeRadius_PROPERTY { get { return innerLightVolumeRadius; } }
        private static int innerLightVolumeRadius;

        public static int outerLightVolumeRadius_PROPERTY { get { return outerLightVolumeRadius; } }
        private static int outerLightVolumeRadius;

        public static int clearExistingVolume_PROPERTY { get { return clearExistingVolume; } }
        private static int clearExistingVolume;

        public static int verticalUV_PROPERTY { get { return verticalUV; } }
        private static int verticalUV;

        public static int verticalSliceId_PROPERTY { get { return verticalSliceId; } }
        private static int verticalSliceId;

        public static int lightVolume_PROPERTY { get { return lightVolume; } }
        private static int lightVolume;

        public static int directLightVolume_PROPERTY { get { return directLightVolume; } }
        private static int directLightVolume;

        public static int ambientLightVolume_PROPERTY { get { return ambientLightVolume; } }
        private static int ambientLightVolume;

        public static int scattererLightVolumeDimensions_PROPERTY { get { return scattererLightVolumeDimensions; } }
        private static int scattererLightVolumeDimensions;

        public static int scattererParaboloidPosition_PROPERTY { get { return scattererParaboloidPosition; } }
        private static int scattererParaboloidPosition;

        public static int scattererWorldToParaboloid_PROPERTY { get { return scattererWorldToParaboloid; } }
        private static int scattererWorldToParaboloid;

        public static int scattererInnerLightVolumeRadius_PROPERTY { get { return scattererInnerLightVolumeRadius; } }
        private static int scattererInnerLightVolumeRadius;

        public static int scattererOuterLightVolumeRadius_PROPERTY { get { return scattererOuterLightVolumeRadius; } }
        private static int scattererOuterLightVolumeRadius;

        public static int scattererDirectLightVolume_PROPERTY { get { return scattererDirectLightVolume; } }
        private static int scattererDirectLightVolume;

        public static int worldToPreviousParaboloid_PROPERTY { get { return worldToPreviousParaboloid; } }
        private static int worldToPreviousParaboloid;

        public static int previousParaboloidPosition_PROPERTY { get { return previousParaboloidPosition; } }
        private static int previousParaboloidPosition;

        public static int previousInnerLightVolumeRadius_PROPERTY { get { return previousInnerLightVolumeRadius; } }
        private static int previousInnerLightVolumeRadius;

        public static int previousOuterLightVolumeRadius_PROPERTY { get { return previousOuterLightVolumeRadius; } }
        private static int previousOuterLightVolumeRadius;

        public static int PreviousLightVolume_PROPERTY { get { return PreviousLightVolume; } }
        private static int PreviousLightVolume;

        public static int Result_PROPERTY { get { return Result; } }
        private static int Result;

        public static int lightVolumeLightMarchSteps_PROPERTY { get { return lightVolumeLightMarchSteps; } }
        private static int lightVolumeLightMarchSteps;

        private void Awake()
        {
            _PosRotation = Shader.PropertyToID("_PosRotation");
            _Rotation = Shader.PropertyToID("_Rotation");
            _InvRotation = Shader.PropertyToID("_InvRotation");
            _MainRotation = Shader.PropertyToID("_MainRotation");
            _DetailRotation = Shader.PropertyToID("_DetailRotation");
            _ShadowOffset = Shader.PropertyToID("_ShadowOffset");
            _SunDir = Shader.PropertyToID("_SunDir");
            _PlanetOrigin = Shader.PropertyToID("_PlanetOrigin");
            _World2Planet = Shader.PropertyToID("_World2Planet");

            _MainTex = Shader.PropertyToID("_MainTex");
            _BumpMap = Shader.PropertyToID("_BumpMap");
            _Emissive = Shader.PropertyToID("_Emissive");


            _SunRadius = Shader.PropertyToID("_SunRadius");
            _SunPos = Shader.PropertyToID("_SunPos");
            _ShadowBodies = Shader.PropertyToID("_ShadowBodies");

            _UniversalTime = Shader.PropertyToID("_UniversalTime");

            _rendererEnabled = Shader.PropertyToID("rendererEnabled");

            flowLoopTime = Shader.PropertyToID("flowLoopTime");
            scaledCloudFade = Shader.PropertyToID("scaledCloudFade");
            cloudTimeFadeDensity = Shader.PropertyToID("cloudTimeFadeDensity");
            cloudTimeFadeCoverage = Shader.PropertyToID("cloudTimeFadeCoverage");
            timeDelta = Shader.PropertyToID("timeDelta");
            shadowCasterCloudRotation = Shader.PropertyToID("shadowCasterCloudRotation");
            _ShadowDetailRotation = Shader.PropertyToID("_ShadowDetailRotation");
            shadowCasterTimeFadeDensity = Shader.PropertyToID("shadowCasterTimeFadeDensity");
            shadowCasterTimeFadeCoverage = Shader.PropertyToID("shadowCasterTimeFadeCoverage");
            timeFadeDensity = Shader.PropertyToID("timeFadeDensity");
            timeFadeCoverage = Shader.PropertyToID("timeFadeCoverage");
            frameNumber = Shader.PropertyToID("frameNumber");
            useOrbitMode = Shader.PropertyToID("useOrbitMode");
            useCombinedOpenGLDistanceBuffer = Shader.PropertyToID("useCombinedOpenGLDistanceBuffer");
            combinedOpenGLDistanceBuffer = Shader.PropertyToID("combinedOpenGLDistanceBuffer");
            reconstructedTextureResolution = Shader.PropertyToID("reconstructedTextureResolution");
            invReconstructedTextureResolution = Shader.PropertyToID("invReconstructedTextureResolution");
            paddedReconstructedTextureResolution = Shader.PropertyToID("paddedReconstructedTextureResolution");
            reprojectionXfactor = Shader.PropertyToID("reprojectionXfactor");
            reprojectionYfactor = Shader.PropertyToID("reprojectionYfactor");
            CameraToWorld = Shader.PropertyToID("CameraToWorld");
            reprojectionUVOffset = Shader.PropertyToID("reprojectionUVOffset");
            currentVP = Shader.PropertyToID("currentVP");
            previousVP = Shader.PropertyToID("previousVP");
            isFirstLayerRendered = Shader.PropertyToID("isFirstLayerRendered");
            isFirstLightningLayerRendered = Shader.PropertyToID("isFirstLightningLayerRendered");
            renderSecondLayerIntersect = Shader.PropertyToID("renderSecondLayerIntersect");
            PreviousLayerRays = Shader.PropertyToID("PreviousLayerRays");
            PreviousLayerLightningOcclusion = Shader.PropertyToID("PreviousLayerLightningOcclusion");
            scattererReconstructedCloud = Shader.PropertyToID("scattererReconstructedCloud");
            scattererCloudLightVolumeEnabled = Shader.PropertyToID("scattererCloudLightVolumeEnabled");
            historyBuffer = Shader.PropertyToID("historyBuffer");
            historyMotionVectors = Shader.PropertyToID("historyMotionVectors");
            newRaysBuffer = Shader.PropertyToID("newRaysBuffer");
            newRaysBufferBilinear = Shader.PropertyToID("newRaysBufferBilinear");
            newRaysMotionVectors = Shader.PropertyToID("newRaysMotionVectors");
            innerSphereRadius = Shader.PropertyToID("innerSphereRadius");
            outerSphereRadius = Shader.PropertyToID("outerSphereRadius");
            outerLayerRadius = Shader.PropertyToID("outerLayerRadius");
            planetRadius = Shader.PropertyToID("planetRadius");
            sphereCenter = Shader.PropertyToID("sphereCenter");
            colorBuffer = Shader.PropertyToID("colorBuffer");
            lightningOcclusion = Shader.PropertyToID("lightningOcclusion");
            cloudFade = Shader.PropertyToID("cloudFade");
            maxConcurrentLightning = Shader.PropertyToID("maxConcurrentLightning");
            lightningIndex = Shader.PropertyToID("lightningIndex");
            lightningCount = Shader.PropertyToID("lightningCount");
            lightningArray = Shader.PropertyToID("lightningArray");
            lightningColorsArray = Shader.PropertyToID("lightningColorsArray");
            lightningTransformsArray = Shader.PropertyToID("lightningTransformsArray");
            alpha = Shader.PropertyToID("alpha");
            color = Shader.PropertyToID("color");
            randomIndexes = Shader.PropertyToID("randomIndexes");
            lightningSheetCount = Shader.PropertyToID("lightningSheetCount");
            gravityVector = Shader.PropertyToID("gravityVector");
            rotationMatrix = Shader.PropertyToID("rotationMatrix");
            offset = Shader.PropertyToID("offset");
            fade = Shader.PropertyToID("fade");
            coverage = Shader.PropertyToID("coverage");
            cameraToWorldMatrix = Shader.PropertyToID("cameraToWorldMatrix");
            worldSpaceCameraForwardDirection = Shader.PropertyToID("worldSpaceCameraForwardDirection");

            baseNoiseOffsets = Shader.PropertyToID("baseNoiseOffsets");
            noTileNoiseOffsets = Shader.PropertyToID("noTileNoiseOffsets");
            detailOffset = Shader.PropertyToID("detailOffset");
            noTileNoiseDetailOffset = Shader.PropertyToID("noTileNoiseDetailOffset");
            curlNoiseOffset = Shader.PropertyToID("curlNoiseOffset");
            cloudRotation = Shader.PropertyToID("cloudRotation");
            cloudDetailRotation = Shader.PropertyToID("cloudDetailRotation");
            reprojectionCurrentPixel = Shader.PropertyToID("reprojectionCurrentPixel");

            lightVolumeDimensions = Shader.PropertyToID("lightVolumeDimensions");
            paraboloidPosition = Shader.PropertyToID("paraboloidPosition");
            paraboloidToWorld = Shader.PropertyToID("paraboloidToWorld");
            worldToParaboloid = Shader.PropertyToID("worldToParaboloid");
            innerLightVolumeRadius = Shader.PropertyToID("innerLightVolumeRadius");
            outerLightVolumeRadius = Shader.PropertyToID("outerLightVolumeRadius");
            clearExistingVolume = Shader.PropertyToID("clearExistingVolume");
            verticalUV = Shader.PropertyToID("verticalUV");
            verticalSliceId = Shader.PropertyToID("verticalSliceId");
            lightVolume = Shader.PropertyToID("lightVolume");
            directLightVolume = Shader.PropertyToID("directLightVolume");
            ambientLightVolume = Shader.PropertyToID("ambientLightVolume");
            scattererLightVolumeDimensions = Shader.PropertyToID("scattererLightVolumeDimensions");
            scattererParaboloidPosition = Shader.PropertyToID("scattererParaboloidPosition");
            scattererWorldToParaboloid = Shader.PropertyToID("scattererWorldToParaboloid");
            scattererInnerLightVolumeRadius = Shader.PropertyToID("scattererInnerLightVolumeRadius");
            scattererOuterLightVolumeRadius = Shader.PropertyToID("scattererOuterLightVolumeRadius");
            scattererDirectLightVolume = Shader.PropertyToID("scattererDirectLightVolume");
            worldToPreviousParaboloid = Shader.PropertyToID("worldToPreviousParaboloid");
            previousParaboloidPosition = Shader.PropertyToID("previousParaboloidPosition");
            previousInnerLightVolumeRadius = Shader.PropertyToID("previousInnerLightVolumeRadius");
            previousOuterLightVolumeRadius = Shader.PropertyToID("previousOuterLightVolumeRadius");
            PreviousLightVolume = Shader.PropertyToID("PreviousLightVolume");
            Result = Shader.PropertyToID("Result");
            lightVolumeLightMarchSteps = Shader.PropertyToID("lightVolumeLightMarchSteps");
        }
    }
}
