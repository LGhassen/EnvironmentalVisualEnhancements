using System.Diagnostics;
using System;
using UnityEditor;
using UnityEngine;

class BuildABs {
    [MenuItem("Assets/Build Asset Bundles")]
    static void BuildAssetBundles()
    {
        Stopwatch stopwatch = Stopwatch.StartNew();

        // Put the bundles in a folder called "ABs" within the
        // Assets folder.
        var outDir = "C:/Steam/steamapps/common/Kerbal Space Program/GameData/EnvironmentalVisualEnhancements";
        var outDir2 = "D:/gh/scattererGithub/EVE/EnvironmentalVisualEnhancements/ContentEVE/GameData/EnvironmentalVisualEnhancements";
        //        var opts = BuildAssetBundleOptions.DeterministicAssetBundle
        //            | BuildAssetBundleOptions.ForceRebuildAssetBundle;

        var opts = BuildAssetBundleOptions.None;

        /* We've made sure all graphics APIs are present for StandaloneWindows, so no need for separate versions (for now).
         * 
        BuildTarget[] platforms = { BuildTarget.StandaloneWindows, BuildTarget.StandaloneOSXUniversal, BuildTarget.StandaloneLinux };
        string[] platformExts = { "-windows", "-macosx", "-linux" };
        */
        BuildTarget[] platforms = { BuildTarget.StandaloneWindows };
        string[] platformExts = { "" };

        for (var i = 0; i < platforms.Length; ++i) {
            BuildPipeline.BuildAssetBundles(outDir, opts, platforms[i]);
            var outFile = outDir + "/eveshaders"+ platformExts[i]+".bundle";
            FileUtil.ReplaceFile(outDir + "/eveshaders", outFile);
            FileUtil.DeleteFileOrDirectory(outDir2 + "/eveshaders.bundle");
            FileUtil.CopyFileOrDirectory(outFile, outDir2 + "/eveshaders.bundle");
        }
        // Delete unused guff
        FileUtil.DeleteFileOrDirectory(outDir + "/EnvironmentalVisualEnhancements");
        FileUtil.DeleteFileOrDirectory(outDir + "/EnvironmentalVisualEnhancements.manifest");
        FileUtil.DeleteFileOrDirectory(outDir + "/eveshaders");
        FileUtil.DeleteFileOrDirectory(outDir + "/eveshaders.manifest");
        
        stopwatch.Stop();
        TimeSpan elapsed = stopwatch.Elapsed;
        string elapsedTime = string.Format("{0:00}:{1:00}:{2:00}", elapsed.Hours, elapsed.Minutes, elapsed.Seconds);

        UnityEngine.Debug.Log($"Shader bundles built in {elapsedTime}");
    }
}