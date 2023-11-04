﻿using System;
using System.Collections;
using System.Linq;
using UnityEngine;
using Utils;
using PQSManager;

namespace Atmosphere
{
    public class CloudsPQS : MonoBehaviour
    {
        private String body;
        private float altitude;
        CloudsVolume layerVolume = null;
        CloudsRaymarchedVolume layerRaymarchedVolume = null;
        Clouds2D layer2D = null;
        CloudsMaterial cloudsMaterial = null;
        CelestialBody celestialBody = null;
        Transform scaledCelestialTransform = null;

        Transform mainMenuBodyTransform = null;
        Clouds2D mainMenuLayer = null;
        Camera mainMenuCamera = null;

        private bool volumeApplied = false;
        private double radius;

        PQS sphere = null;
        bool scaled = true;
        
        Vector3d detailPeriod;
        Vector3d mainPeriod;
        Vector3 offset;
        Matrix4x4 rotationAxis;

        TimeSettings timeSettings;

        bool killBodyRotation;
        double previousFrameUt = 0.0;
        public new bool enabled
        {
            get
            {
                return base.enabled;
            }
            set
            {
                base.enabled = value;
                if (layer2D != null)
                {
                    layer2D.enabled = value;
                }
                if (layerVolume != null)
                {
                    layerVolume.enabled = value;
                }
                if (layerRaymarchedVolume != null)
                {
                    layerRaymarchedVolume.enabled = value;
                }
            }
        }

        public void OnSphereActive()
        {
            CloudsManager.Log("CloudsPQS: ("+this.name+") OnSphereActive");
            if (layer2D != null)
            {
                layer2D.Scaled = false;
            }
            if (!volumeApplied)
            {
                if (layerVolume != null)
                {
                    // TODO pass timeSettings fadeMode
                    layerVolume.Apply(cloudsMaterial, (float)celestialBody.Radius + altitude, celestialBody.transform);
                }

                volumeApplied = true;
            }

            scaled = false;
        }
        public void OnSphereInactive()
        {
            CloudsManager.Log("CloudsPQS: (" + this.name + ") OnSphereInactive");
            if (layer2D != null)
            {
                layer2D.Scaled = true;
            }
            
            if (!MapView.MapIsEnabled)
            {
                if (layerVolume != null)
                {
                    layerVolume.Remove();
                }

                volumeApplied = false;
            }

            scaled = true;
        }

        protected void ExitMapView()
        {
            StartCoroutine(CheckForDisable());
        }

        IEnumerator CheckForDisable()
        {
            yield return new WaitForFixedUpdate();

            if (!sphere.isActive)
            {
                if (layerVolume != null)
                {
                    layerVolume.Remove();
                }

                volumeApplied = false;
            }
            else
            {
                OnSphereActive();
            }
        }

        private void ApplyToMainMenu()
        {
            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                GameObject go = Tools.GetMainMenuObject(body);

                if (go != null && go.transform != mainMenuBodyTransform)
                {
                    mainMenuCamera = GameObject.FindObjectsOfType<Camera>().First(c => ( c.cullingMask & (1<<go.layer) ) > 0 && c.isActiveAndEnabled);

                    if (layer2D != null)
                    {
                        if (mainMenuLayer != null)
                        {
                            mainMenuLayer.Remove();
                        }
                        mainMenuBodyTransform = go.transform;
                        mainMenuLayer = layer2D.CloneForMainMenu(go);
                        CloudsManager.Log(this.name + " Applying to main menu!");
                    }
                }
                else if (go == null)
                {
                    CloudsManager.Log("Cannot find "+body+" to apply to main Menu!");
                }
                else if (mainMenuBodyTransform == go.transform)
                {
                    CloudsManager.Log("Already Applied to main Menu!");
                }
            }
        }

        protected void Update()
        {
            bool visible = HighLogic.LoadedScene == GameScenes.TRACKSTATION || HighLogic.LoadedScene == GameScenes.FLIGHT || HighLogic.LoadedScene == GameScenes.SPACECENTER || HighLogic.LoadedScene == GameScenes.MAINMENU;

            float currentTimeFade = 1f;

            if (timeSettings!=null)
            {
                visible = visible && timeSettings.IsEnabled(out currentTimeFade);
            }

            if (visible)
            {
                double ut;
                if (HighLogic.LoadedScene == GameScenes.MAINMENU)
                {
                    ut = Time.time;
                }
                else
                {
                    ut = Planetarium.GetUniversalTime();
                }

                Vector3d detailRotation = (ut * detailPeriod);
                detailRotation -= new Vector3d((int)detailRotation.x, (int)detailRotation.y, (int)detailRotation.z);
                detailRotation *= 360;
                detailRotation += offset;
                Vector3d mainRotation = (ut * mainPeriod);
                mainRotation -= new Vector3d((int)mainRotation.x, (int)mainRotation.y, (int)mainRotation.z);
                mainRotation *= 360f;
                mainRotation += offset;

                QuaternionD mainRotationQ = Quaternion.identity;
                if (killBodyRotation)
                {
                    mainRotationQ = QuaternionD.AngleAxis(celestialBody.rotationAngle, Vector3.up);
                }
                mainRotationQ *=
                    QuaternionD.AngleAxis(mainRotation.x, (Vector3)rotationAxis.GetRow(0)) *
                    QuaternionD.AngleAxis(mainRotation.y, (Vector3)rotationAxis.GetRow(1)) *
                    QuaternionD.AngleAxis(mainRotation.z, (Vector3)rotationAxis.GetRow(2));
                Matrix4x4 mainRotationMatrix = Matrix4x4.TRS(Vector3.zero, mainRotationQ, Vector3.one).inverse;

                QuaternionD detailRotationQ = 
                    QuaternionD.AngleAxis(detailRotation.x, Vector3.right) *
                    QuaternionD.AngleAxis(detailRotation.y, Vector3.up) *
                    QuaternionD.AngleAxis(detailRotation.z, Vector3.forward);
                Matrix4x4 detailRotationMatrix = Matrix4x4.TRS(Vector3.zero, detailRotationQ, Vector3.one).inverse;

                if (this.sphere != null)
                {
                    if (sphere.isActive && scaled && !MapView.MapIsEnabled)
                    {
                        OnSphereActive();
                    }
                    
                    if (!scaled && (!sphere.isActive || MapView.MapIsEnabled))
                    {
                        OnSphereInactive();
                    }

                    Matrix4x4 world2SphereMatrix = this.sphere.transform.worldToLocalMatrix;

                    if (layerVolume != null && sphere.isActive)
                    {
                        if (FlightCamera.fetch != null)
                        {
                            var inRange = layer2D == null ? true : Mathf.Abs(FlightCamera.fetch.cameraAlt - layer2D.Altitude()) < layerVolume.VisibleRange();
                            if (inRange != layerVolume.enabled)
                                CloudsManager.Log((inRange ? "Enable" : "Disable")+" clouds when camera: " + FlightCamera.fetch.cameraAlt + " layer: " + (layer2D == null ? "none" : layer2D.Altitude().ToString()));
                            if (inRange) {
                                layerVolume.enabled = true;
                                layerVolume.UpdatePos(FlightCamera.fetch.mainCamera.transform.position,
                                                       world2SphereMatrix,
                                                       mainRotationQ,
                                                       detailRotationQ,
                                                       mainRotationMatrix,
                                                       detailRotationMatrix);
                            } else {
                                layerVolume.enabled = false;
                            }
                        }
                        else
                        {
                            layerVolume.UpdatePos(this.sphere.target.position,
                                                       world2SphereMatrix,
                                                       mainRotationQ,
                                                       detailRotationQ,
                                                       mainRotationMatrix,
                                                       detailRotationMatrix);
                            layerVolume.enabled = true;
                        }
                    }

                    float scaledLayerFade = 1f;

                    if (layerRaymarchedVolume != null)
                    {
                        if (FlightCamera.fetch != null && layerRaymarchedVolume.checkVisible(FlightCamera.fetch.mainCamera.transform.position, out scaledLayerFade))
                        {
                            Vector3d oppositeFrameDeltaRotation = (ut - previousFrameUt) * mainPeriod;
                            oppositeFrameDeltaRotation *= -360f;

                            previousFrameUt = ut;

                            QuaternionD oppositeFrameDeltaRotationQ =
                                QuaternionD.AngleAxis(oppositeFrameDeltaRotation.x, Vector3.right) *
                                QuaternionD.AngleAxis(oppositeFrameDeltaRotation.y, Vector3.up) *
                                QuaternionD.AngleAxis(oppositeFrameDeltaRotation.z, Vector3.forward);
                            Matrix4x4 planetOppositeFrameDeltaRotationMatrix = Matrix4x4.TRS(Vector3.zero, oppositeFrameDeltaRotationQ, Vector3.one);

                            Matrix4x4 sphere2WorldMatrix = this.sphere.transform.localToWorldMatrix;
                            Matrix4x4 worldOppositeFrameDeltaRotationMatrix = sphere2WorldMatrix * planetOppositeFrameDeltaRotationMatrix * world2SphereMatrix;

                            layerRaymarchedVolume.UpdatePos(FlightCamera.fetch.mainCamera.transform.position,
                                                   world2SphereMatrix,
                                                   mainRotationQ,
                                                   detailRotationQ,
                                                   mainRotationMatrix,
                                                   planetOppositeFrameDeltaRotationMatrix,
                                                   worldOppositeFrameDeltaRotationMatrix,
                                                   detailRotationMatrix);

                            if (timeSettings != null)
                            {
                                layerRaymarchedVolume.SetTimeFade(currentTimeFade, timeSettings.GetFadeMode());
                            }

                            layerRaymarchedVolume.enabled = true;
                        }
                        else
                        {
                            layerRaymarchedVolume.enabled = false;
                        }
                    }

                    if (layer2D != null)
                    {
                        if (HighLogic.LoadedScene == GameScenes.SPACECENTER || (HighLogic.LoadedScene == GameScenes.FLIGHT && sphere.isActive && !MapView.MapIsEnabled))
                        {
                            layer2D.UpdateRotation(Quaternion.FromToRotation(Vector3.up, this.sphere.relativeTargetPosition),
                                                   world2SphereMatrix,
                                                   mainRotationMatrix,
                                                   detailRotationMatrix);

                        }
                        else if (HighLogic.LoadedScene == GameScenes.MAINMENU && mainMenuLayer != null)
                        {
                            //mainMenuCamera.transform.position -= 5 * mainMenuCamera.transform.forward; 
                            Transform transform = mainMenuCamera.transform;
                            Vector3 pos = mainMenuBodyTransform.InverseTransformPoint(transform.position);

                            mainMenuLayer.UpdateRotation(Quaternion.FromToRotation(Vector3.up, pos),
                                                       mainMenuBodyTransform.worldToLocalMatrix,
                                                       mainRotationMatrix,
                                                       detailRotationMatrix);
                        }
                        else if (MapView.MapIsEnabled || HighLogic.LoadedScene == GameScenes.TRACKSTATION || (HighLogic.LoadedScene == GameScenes.FLIGHT && !sphere.isActive))
                        {
                            Transform transform = ScaledCamera.Instance.galaxyCamera.transform;
                            Vector3 pos = scaledCelestialTransform.InverseTransformPoint(transform.position);

                            layer2D.UpdateRotation(Quaternion.FromToRotation(Vector3.up, pos),
                                                   scaledCelestialTransform.worldToLocalMatrix,
                                                   mainRotationMatrix,
                                                   detailRotationMatrix);

                        }

                        if (scaledLayerFade > 0f)
                        {
                            layer2D.SetOrbitFade(scaledLayerFade);
                            layer2D.enabled = true;
                        }
                        else
                        {
                            layer2D.enabled = true; // todo merge these two lines 
                            layer2D.setCloudMeshEnabled(false); // only disable the 2d layer, don't disable shadows
                        }

                        if (timeSettings != null)
                        {
                            layer2D.SetTimeFade(currentTimeFade, timeSettings.GetFadeMode());
                        }
                    }
                }
            }
            else
            {
                if (layer2D != null) layer2D.enabled = false; // needed?
                if (layerRaymarchedVolume != null) layerRaymarchedVolume.enabled = false;
            }
        }

        internal void Apply(String body, CloudsMaterial cloudsMaterial, Clouds2D layer2D, CloudsVolume layerVolume, CloudsRaymarchedVolume layerRaymarchedVolume, float altitude, float arc, Vector3d speed, Vector3d detailSpeed, Vector3 offset, Matrix4x4 rotationAxis, bool killBodyRotation, TimeSettings timeSettings)
        {
            this.body = body;
            this.cloudsMaterial = cloudsMaterial;
            this.layer2D = layer2D;
            this.layerVolume = layerVolume;
            this.layerRaymarchedVolume = layerRaymarchedVolume;
            this.altitude = altitude;
            this.offset = -offset;
            this.rotationAxis = rotationAxis;
            this.killBodyRotation = killBodyRotation;
            this.timeSettings = timeSettings;

            celestialBody = Tools.GetCelestialBody(body);
            scaledCelestialTransform = Tools.GetScaledTransform(body);
            PQS pqs = null;
            if (celestialBody != null && celestialBody.pqsController != null)
            {
                pqs = celestialBody.pqsController;
            }
            else
            {
                CloudsManager.Log("No PQS! Instanciating one.");
                pqs = PQSManagerClass.GetPQS(body);
            }
            CloudsManager.Log("PQS Applied");
            if (pqs != null)
            {
                this.sphere = pqs;
                this.transform.parent = pqs.transform;

                this.transform.localPosition = Vector3.zero;
                this.transform.localRotation = Quaternion.identity;
                this.transform.localScale = Vector3.one;
                this.radius = (altitude + celestialBody.Radius);
                
                double circumference = 2f * Mathf.PI * radius;
                mainPeriod = -(speed) / circumference;
                detailPeriod = -(detailSpeed) / circumference;
                
                if (layer2D != null)
                {
                    // TODO pass timeSettings fadeMode
                    this.layer2D.Apply(celestialBody, scaledCelestialTransform, cloudsMaterial, this.name, (float)radius, arc);
                }

                if (layerRaymarchedVolume != null)
                {
                    // TODO pass timeSettings fadeMode
                    layerRaymarchedVolume.Apply(cloudsMaterial, (float)celestialBody.Radius + altitude, celestialBody.transform, (float)celestialBody.Radius, celestialBody, layer2D, (float)speed.magnitude);
                }

                if (!pqs.isActive || HighLogic.LoadedScene == GameScenes.TRACKSTATION)
                {
                    this.OnSphereInactive();
                }
                else
                {
                    this.OnSphereInactive();
                    this.OnSphereActive();
                }
            }
            else
            {
                CloudsManager.Log("PQS is null somehow!?");
            }

            GameEvents.OnMapExited.Add(ExitMapView);
            GameEvents.onGameSceneLoadRequested.Add(SceneLoaded);

            if (HighLogic.LoadedScene == GameScenes.MAINMENU)
            {
                ApplyToMainMenu();
            }
        }

        private void SceneLoaded(GameScenes scene)
        {
            if (scene != GameScenes.SPACECENTER && scene != GameScenes.FLIGHT)
            {
                this.OnSphereInactive();
                sphere.isActive = false;
            }
            if (scene != GameScenes.SPACECENTER && scene != GameScenes.FLIGHT && scene != GameScenes.TRACKSTATION && scene != GameScenes.MAINMENU)
            {
                this.OnSphereInactive();
                sphere.isActive = false;
                this.enabled = false;
            }
            else
            {
                this.enabled = true;
            }

            if (scene == GameScenes.MAINMENU)
            {
                ApplyToMainMenu();
                if (layerRaymarchedVolume != null)
                    layerRaymarchedVolume.enabled = false;
            }
            else
            {
                if (mainMenuLayer != null)
                {
                    mainMenuLayer.Remove();
                }
                mainMenuLayer = null;
            }

            if(scene == GameScenes.SPACECENTER || scene == GameScenes.FLIGHT)
            {
                Camera[] cameras = Camera.allCameras;
                foreach (Camera cam in cameras)
                {
                    if (cam.name == "Camera 01" || cam.name == "Camera 00")
                    {
                        cam.depthTextureMode = DepthTextureMode.Depth;
                    }
                }
                if (ScaledCamera.Instance != null && ScaledCamera.Instance.GetComponent<Camera>() != null)
                {
                    ScaledCamera.Instance.GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
                }
            }

            if (scene == GameScenes.FLIGHT)
            {
                StartCoroutine(DelayedCheckForSphereInactive());
            }
        }

        IEnumerator DelayedCheckForSphereInactive()
        {
            yield return new WaitForFixedUpdate();

            if (!sphere.isActive && layer2D != null && !layer2D.Scaled)
            {
                OnSphereInactive();
            }
        }

        public void Remove()
        {
            if (layer2D != null)
            {
                layer2D.Remove();
            }
            if(mainMenuLayer != null)
            {
                mainMenuLayer.Remove();
            }
            if (layerVolume != null)
            {
                layerVolume.Remove();
            }
            if (layerRaymarchedVolume != null)
            {
                layerRaymarchedVolume.Remove();
            }
            layer2D = null;
            mainMenuLayer = null;
            layerVolume = null;
            layerRaymarchedVolume = null;
            volumeApplied = false;
            this.enabled = false;
            this.sphere = null;
            this.transform.parent = null;
            GameEvents.OnMapExited.Remove(ExitMapView);
            GameEvents.onGameSceneLoadRequested.Remove(SceneLoaded);
        }
    }
}
