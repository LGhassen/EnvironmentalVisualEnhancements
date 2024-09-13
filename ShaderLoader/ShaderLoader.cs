using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEngine;
using Utils;
using KSPAssets;

namespace ShaderLoader
{
    [KSPAddon(KSPAddon.Startup.Instantly, true)]
    public class ShaderLoaderClass : MonoBehaviour
    {
        static Dictionary<string, Shader> shaderDictionary = null;
        static Dictionary<string, ComputeShader> computeShaderDictionary = null;

        public static Vector3Int stbnDimensions = new Vector3Int(128, 128, 64);
        public static Texture2D stbnScalar, stbnUnitVec3;

        public static bool loaded = false;

        private void Start()
        {
            LoadShaders();
        }

        private void LoadShaders()
        {
            if (shaderDictionary == null)
            {
                shaderDictionary = new Dictionary<string, Shader>();
                computeShaderDictionary = new Dictionary<string, ComputeShader>();

                // Add all other shaders
                Shader[] shaders = Resources.FindObjectsOfTypeAll<Shader>();
                foreach (Shader shader in shaders)
                {
                    shaderDictionary[shader.name] = shader;
                }

                using (WWW www = new WWW("file://" + KSPUtil.ApplicationRootPath + "GameData/EnvironmentalVisualEnhancements/eveshaders.bundle"))
                {
                    if (www.error != null)
                    {
                        KSPLog.print("[EVE] eveshaders.bundle not found!");
                        return;
                    }

                    AssetBundle bundle = www.assetBundle;

                    shaders = bundle.LoadAllAssets<Shader>();

                    foreach (Shader shader in shaders)
                    {
                        KSPLog.print("[EVE] Shader " + shader.name + " loaded");
                        shaderDictionary.Add(shader.name, shader);
                    }

                    ComputeShader[] computeShaders = bundle.LoadAllAssets<ComputeShader>();

                    foreach (ComputeShader computeShader in computeShaders)
                    {
                        KSPLog.print("[EVE] Compute Shader " + computeShader.name + " loaded");
                        computeShaderDictionary.Add(computeShader.name, computeShader);
                    }

                    bundle.Unload(false);
                    www.Dispose();
                }
            }

            if (stbnScalar == null)
            {
                stbnScalar = new Texture2D((int)stbnDimensions.x, (int)(stbnDimensions.y * stbnDimensions.z), TextureFormat.R8, false);
                stbnScalar.filterMode = FilterMode.Point;
                stbnScalar.wrapMode = TextureWrapMode.Repeat;
                stbnScalar.LoadRawTextureData(System.IO.File.ReadAllBytes(KSPUtil.ApplicationRootPath + "GameData/EnvironmentalVisualEnhancements/stbn.R8"));
                stbnScalar.Apply();
            }

            if (stbnUnitVec3 == null)
            {
                stbnUnitVec3 = new Texture2D((int)stbnDimensions.x, (int)(stbnDimensions.y * stbnDimensions.z), TextureFormat.ARGB32, false);
                stbnUnitVec3.filterMode = FilterMode.Point;
                stbnUnitVec3.wrapMode = TextureWrapMode.Repeat;
                stbnUnitVec3.LoadRawTextureData(System.IO.File.ReadAllBytes(KSPUtil.ApplicationRootPath + "GameData/EnvironmentalVisualEnhancements/stbn_unitvec3.ARGB32"));
                stbnUnitVec3.Apply();
            }

            loaded = true;
        }

        public static Shader FindShader(string name)
        {
            if (shaderDictionary == null)
            {
                KSPLog.print("[EVE] Trying to find shader before assets loaded");
                return null;
            }

            if (shaderDictionary.ContainsKey(name))
            {
                return shaderDictionary[name];
            }

            KSPLog.print("[EVE] Could not find shader " + name);
            return null;
        }

        public static ComputeShader FindComputeShader(string name)
        {
            if (computeShaderDictionary == null)
            {
                KSPLog.print("[EVE] Trying to find compute shader before assets loaded");
                return null;
            }
            if (computeShaderDictionary.ContainsKey(name))
            {
                return computeShaderDictionary[name];
            }
            KSPLog.print("[EVE] Could not find compute shader " + name);
            return null;
        }
    }
}
