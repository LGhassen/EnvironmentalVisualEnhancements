using UnityEngine;


namespace Atmosphere
{
    [KSPAddon(KSPAddon.Startup.Instantly, true)]
    public class AudioSettingsStartupHandler : MonoBehaviour
    {
        private static readonly int numRealVoices = 128; // this seems really high but the game's mach effects spam audio sources that conflict with mine and the engine sounds

        private void Start()
        {
            UpdateAudioSettings();
        }

        private void UpdateAudioSettings()
        {
            var currentSettings = AudioSettings.GetConfiguration();

            if (currentSettings.numRealVoices < numRealVoices)
            {
                currentSettings.numRealVoices = numRealVoices;
                bool success = AudioSettings.Reset(currentSettings); // this only works when done at startup, otherwise it fails silently and 3d audio just stops working

                if (success)
                    Debug.Log($"[EVE] Sucessfully updated number of real voices to: " + numRealVoices);
                else
                    Debug.Log($"[EVE] Failed to update number of real voices");

            }
        }
    }
}