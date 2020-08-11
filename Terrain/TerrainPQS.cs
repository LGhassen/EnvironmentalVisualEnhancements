using EVEManager;
using PQSManager;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Utils;

namespace Terrain
{
    public class TerrainPQS : PQSMod
    {
        
        CelestialBody celestialBody = null;
        Shader originalTerrainShader = null;
        Shader originalPlanetShader;
        Shader originalOceanShader;

        GameObject OceanBacking = null;
        Material OceanBackingMaterial;
        Material OceanSurfaceMaterial;
        private Material pqsSurfaceMaterial;

        public override void OnSphereActive()
        {
            if (OceanBacking != null)
            {
                OceanBacking.SetActive(true);
            }
        }
        public override void OnSphereInactive()
        {
            if (OceanBacking != null)
            {
                OceanBacking.SetActive(false);
            }
        }
        
        protected void Update()
        {
            if (this.sphere.isActiveAndEnabled && celestialBody != null)
            {
                Vector3 sunDir = this.celestialBody.transform.InverseTransformDirection(Sun.Instance.sunDirection);
                pqsSurfaceMaterial.SetVector(ShaderProperties.SUNDIR_PROPERTY, sunDir);
                Vector3 planetOrigin = this.celestialBody.transform.position;
                pqsSurfaceMaterial.SetVector(ShaderProperties.PLANET_ORIGIN_PROPERTY, planetOrigin);
                if (OceanBackingMaterial != null)
                {
                    OceanBackingMaterial.SetVector(ShaderProperties.PLANET_ORIGIN_PROPERTY, planetOrigin);
                    OceanSurfaceMaterial.SetVector(ShaderProperties.PLANET_ORIGIN_PROPERTY, planetOrigin);
                }
            }
        }

        

        internal void Apply(string body, TerrainMaterial terrainMaterial, OceanMaterial oceanMaterial)
        {
            celestialBody = Tools.GetCelestialBody(body);
            PQS pqs = null;
            if (celestialBody != null && celestialBody.pqsController != null)
            {
                pqs = celestialBody.pqsController;
                pqsSurfaceMaterial = GetPQSSurfaceMaterial(pqs);
            }
            else
            {
                pqs = PQSManagerClass.GetPQS(body);
            }

            Transform transform = Tools.GetScaledTransform(body);

            if (pqs != null)
            {
                this.sphere = pqs;
                this.transform.parent = pqs.transform;
                this.requirements = PQS.ModiferRequirements.Default;
                this.modEnabled = true;
                this.order += 10;

                this.transform.localPosition = Vector3.zero;
                this.transform.localRotation = Quaternion.identity;
                this.transform.localScale = Vector3.one;

                //Scaled space
                Renderer r = (Renderer)transform.GetComponent(typeof(Renderer));
                if (r != null)
                {
                    terrainMaterial.SaveTextures(r.material);
                    originalPlanetShader = r.material.shader;

                    TerrainManager.Log("planet shader: " + r.material.shader);
                    r.sharedMaterial.shader = TerrainManager.PlanetShader;
                    terrainMaterial.ApplyMaterialProperties(r.sharedMaterial);
					// terrainMaterial doesn't work anyway [1/3]
					if (pqs.ChildSpheres.Length != 0)
					{
						r.sharedMaterial.EnableKeyword("OCEAN_ON");
					} else {
						r.sharedMaterial.DisableKeyword("OCEAN_ON");
					}
                }

				// terrainMaterial doesn't work anyway [2/3]
				//terrainMaterial = null;
				//originalTerrainShader = null;

                terrainMaterial.SaveTextures(pqsSurfaceMaterial);
                originalTerrainShader = pqsSurfaceMaterial.shader;
                TerrainManager.Log("Terrain Shader Name: " + originalTerrainShader.name);
                String[] keywords = pqsSurfaceMaterial.shaderKeywords;
                pqsSurfaceMaterial.shader = TerrainManager.TerrainShader;
            //    foreach (String keyword in keywords)
            //    {
            //        pqs.surfaceMaterial.EnableKeyword(keyword);
            //    }
                terrainMaterial.ApplyMaterialProperties(pqsSurfaceMaterial);

                if (oceanMaterial != null && pqs.ChildSpheres.Length > 0)
                {
                    PQS ocean = pqs.ChildSpheres[0];
                    OceanSurfaceMaterial = GetPQSSurfaceMaterial(ocean);

                    pqsSurfaceMaterial.EnableKeyword("OCEAN_ON");
                    r.sharedMaterial.EnableKeyword("OCEAN_ON");

                    keywords = OceanSurfaceMaterial.shaderKeywords;
                    originalOceanShader = OceanSurfaceMaterial.shader;
                    TerrainManager.Log("Ocean Shader Name: " + originalOceanShader.name);
                    OceanSurfaceMaterial.shader = TerrainManager.OceanShader;
                //    foreach (String keyword in keywords)
                //    {
                //        OceanSurfaceMaterial.EnableKeyword(keyword);
                //    }
                    
                    terrainMaterial.ApplyMaterialProperties(OceanSurfaceMaterial);
                    oceanMaterial.ApplyMaterialProperties(OceanSurfaceMaterial);

                    PQSLandControl landControl = (PQSLandControl)pqs.transform.GetComponentInChildren(typeof(PQSLandControl));
                    if (landControl != null)
                    {
                        PQSLandControl.LandClass[] landClasses = landControl.landClasses;
                        if (landClasses != null)
                        {
                            PQSLandControl.LandClass lcBeach = landClasses.FirstOrDefault(lc => lc.landClassName == "BaseBeach");
                            PQSLandControl.LandClass lcOcean = landClasses.FirstOrDefault(lc => lc.landClassName == "Ocean Bottom");
                            if (lcBeach != null || lcOcean != null)
                            {
                                lcOcean.color = lcBeach.color;
                            }
                        }

                    
            //    PQS ocean =
            //    sphere.ChildSpheres[0];
            //    GameObject go = new GameObject();
            //    FakeOceanPQS fakeOcean = go.AddComponent<FakeOceanPQS>();
            //    fakeOcean.Apply(ocean);


                    }

                    SimpleCube hp = new SimpleCube(2000, ref OceanBackingMaterial, TerrainManager.OceanBackingShader);
                    OceanBacking = hp.GameObject;

                    OceanBacking.transform.parent = FlightCamera.fetch.transform;
                    OceanBacking.transform.localPosition = Vector3.zero;
                    OceanBacking.transform.localScale = Vector3.one;
                    OceanBacking.layer = (int)Tools.Layer.Local;
                    OceanBackingMaterial.SetFloat("_OceanRadius", (float)celestialBody.Radius);
                    terrainMaterial.ApplyMaterialProperties(OceanBackingMaterial);
                }
                else
                {
                    pqsSurfaceMaterial.DisableKeyword("OCEAN_ON");
                    //r.sharedMaterial.DisableKeyword("OCEAN_ON"); // terrainMaterial doesn't work anyway [3/3]
                }


                PQSMod_CelestialBodyTransform cbt = (PQSMod_CelestialBodyTransform)pqs.transform.GetComponentInChildren(typeof(PQSMod_CelestialBodyTransform));
                if (cbt != null)
                {
                    pqsSurfaceMaterial.SetFloat("_MainTexHandoverDist", (float)(1f / cbt.deactivateAltitude));
                    if (oceanMaterial != null && pqs.ChildSpheres.Length > 0)
                    {
                        PQS ocean = pqs.ChildSpheres[0];
                        OceanSurfaceMaterial.SetFloat("_MainTexHandoverDist", (float)(1f / cbt.deactivateAltitude));
                    }
                    pqsSurfaceMaterial.SetFloat("_OceanRadius", (float)celestialBody.Radius);
                }

            }


            this.OnSetup();
            pqs.EnableSphere();
        }

        internal void Remove()
        {
            this.sphere = null;
            this.enabled = false;
            this.transform.parent = null;
            if (OceanBacking != null)
            {
                GameObject.DestroyImmediate(OceanBacking);
                OceanBacking = null;
            }
        }

        private static Material GetPQSSurfaceMaterial(PQS pqs)
        {
            switch (GameSettings.TERRAIN_SHADER_QUALITY)
            {
                case 0:
                    if (pqs.lowQualitySurfaceMaterial != null)
                    {
                        return pqs.lowQualitySurfaceMaterial;
                    }
                    break;
                case 1:
                    if (pqs.mediumQualitySurfaceMaterial != null)
                    {
                        return pqs.mediumQualitySurfaceMaterial;
                    }
                    break;
                case 2:
                    if (pqs.highQualitySurfaceMaterial != null)
                    {
                        return pqs.highQualitySurfaceMaterial;
                    }
                    break;
            }
            return pqs.surfaceMaterial;
        }

    }
}
