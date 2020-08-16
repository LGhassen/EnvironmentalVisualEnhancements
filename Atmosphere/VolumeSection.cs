using Utils;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using EVEManager;
using ShaderLoader;

namespace Atmosphere
{
    class CloudParticle
    {
        private static System.Random Random = new System.Random();

        GameObject particle;
        public CloudParticle(Material cloudParticleMaterial, Vector2 size, Transform parent, Vector3 pos, float magnitude)
        {
            particle = new GameObject();

            particle.transform.parent = parent;

            particle.transform.localPosition = pos;

            Vector3 bodyPoint = parent.parent.InverseTransformPoint(particle.transform.position).normalized*magnitude;
            particle.transform.position = parent.parent.TransformPoint(bodyPoint);

            particle.transform.localPosition += Vector3.zero;

            Vector3 worldUp = particle.transform.position - parent.parent.position;
            particle.transform.up = worldUp.normalized;

            particle.transform.localRotation = Quaternion.Euler(0, 0, 0);

            particle.transform.localScale = Vector3.one;
            particle.layer = (int)Tools.Layer.Local;

            Vector3 up = particle.transform.InverseTransformDirection(worldUp);
            Quad.Create(particle, (int)size.x, Color.white, up, size.y);

            MeshRenderer mr = particle.AddComponent<MeshRenderer>();
            mr.sharedMaterial = cloudParticleMaterial;

            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            mr.receiveShadows = false;
            mr.enabled = true;
        }


        internal void Destroy()
        {
            GameObject.DestroyImmediate(particle);
        }

        
    }

    //removes the need for individual particles/meshrenderers etc
    //creates one mesh with all the particle positions which then gets passed to a geometry shader which then generates particle quads from the vertices
    class CloudMesh
    {
        GameObject cloudMesh;
        public CloudMesh(Material cloudParticleMaterial, Vector2 size, Transform parent, float magnitude, HexSeg hexGeometry) //size should be passed to material as a parameter, to control quad generation
        {
            cloudMesh = new GameObject();

            cloudMesh.transform.parent = parent;
            cloudMesh.transform.localPosition = Vector3.zero;
            
            //Vector3 worldUp = cloudMesh.transform.position - parent.parent.position;
            //cloudMesh.transform.up = worldUp.normalized;

            cloudMesh.transform.localRotation = Quaternion.Euler(0, 0, 0);

            cloudMesh.transform.localScale = Vector3.one;

            cloudMesh.layer = (int)Tools.Layer.Local;

            //Vector3 up = cloudMesh.transform.InverseTransformDirection(worldUp);
            //Quad.Create(cloudMesh, (int)size.x, Color.white, up, size.y);
            
            MeshFilter filter = cloudMesh.AddComponent<MeshFilter>();
            filter.mesh = hexGeometry.BuildPointsMesh();
            filter.mesh.RecalculateBounds();


            //Debug.Log("vertices.Count() " + vertices.Count());

            MeshRenderer mr = cloudMesh.AddComponent<MeshRenderer>();
            //mr.sharedMaterial = cloudParticleMaterial;
            mr.sharedMaterial = new Material(InvisibleShader); //this may throw off scatterer's integration though, so check that

            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            mr.receiveShadows = false;
            mr.enabled = true;

            DeferredRendererNotifier notifier = cloudMesh.AddComponent<DeferredRendererNotifier>();
            notifier.mat = cloudParticleMaterial;
        }

        private static Shader invisibleShader = null;
        private static Shader InvisibleShader
        {
            get
            {
                if (invisibleShader == null)
                {
                    invisibleShader = ShaderLoaderClass.FindShader("EVE/Invisible");
                }
                return invisibleShader;
            }
        }

        internal void Destroy()
        {
            GameObject.DestroyImmediate(cloudMesh);
        }
    }

    class VolumeSection
    {
        
        private static System.Random Random = new System.Random();

        GameObject segment;
        float magnitude;
        float xComp, zComp;
        List<CloudParticle> Particles = new List<CloudParticle>();
        CloudMesh cloudMesh;

        float radius, divisions;

        public Vector3 Center { get { return segment.transform.localPosition; } }
        public bool Enabled { get { return segment.activeSelf; } set { segment.SetActive(value); } }

        public VolumeSection(Material cloudParticleMaterial, Vector2 size, Transform parent, Vector3 pos, float magnitude, float radius, int divisions)
        {
            segment = new GameObject();
            this.radius = radius;
            this.divisions = divisions;
            HexSeg hexGeometry = new HexSeg(radius, divisions);

            xComp = 360f * (radius / (Mathf.Pow(2f, divisions))) / (2f * Mathf.PI * magnitude);
            zComp = 360f * (2*Mathf.Sqrt(.75f) * radius / (Mathf.Pow(2f, divisions))) / (2f * Mathf.PI * magnitude);

            segment.transform.localPosition = pos;
            Reassign(pos, magnitude, parent);

            cloudMesh = new CloudMesh(cloudParticleMaterial, size, segment.transform, magnitude, hexGeometry);
        }

        public void Reassign(Vector3 pos, float magnitude = -1, Transform parent = null)
        {
            if(parent != null)
            {
                segment.transform.parent = parent;
            }
            if (magnitude > 0)
            {
                this.magnitude = magnitude;
            }


            Vector3 worldUp = segment.transform.position - segment.transform.parent.position;
            segment.transform.up = worldUp.normalized;
            Vector3 posWorldDir = Vector3.Normalize(segment.transform.parent.TransformDirection(pos));
            Vector3 xDir = Vector3.Normalize(segment.transform.TransformDirection(Vector3.forward));
            float xDot = Vector3.Dot(posWorldDir, xDir);
            Vector3 xWorldDir = posWorldDir - ( xDot * xDir );
            Vector3 zDir = Vector3.Normalize(segment.transform.TransformDirection(Vector3.right));
            float zDot = Vector3.Dot(posWorldDir, zDir);
            Vector3 zWorldDir = posWorldDir - (zDot * zDir);

            float xAngle = Vector3.Angle(worldUp, xWorldDir);
            float zAngle = Vector3.Angle(worldUp, zWorldDir);

            

            if (xAngle > xComp)
            {
                segment.transform.RotateAround(segment.transform.parent.position, xDir, -Mathf.Sign(zDot) * Mathf.Floor(xAngle / xComp) * xComp);
            }
            if (zAngle > zComp)
            {
                segment.transform.RotateAround(segment.transform.parent.position, zDir, Mathf.Sign(xDot) * Mathf.Floor(zAngle / zComp) * zComp);
            }
            //Rotate Around is in world cords and degrees.
            //if (segment.transform.RotateAround()
            //segment.transform.localPosition = pos;
            //
            //segment.transform.localScale = Vector3.one;
            //segment.transform.Translate(offset);

            worldUp = segment.transform.position - segment.transform.parent.position;
            segment.transform.up = worldUp.normalized;
            segment.transform.localPosition = this.magnitude * segment.transform.localPosition.normalized;

        }

        internal void Destroy()
        {
            foreach (CloudParticle particle in Particles)
            {
                particle.Destroy();
            }
            GameObject.DestroyImmediate(segment);
        }

    }
}
