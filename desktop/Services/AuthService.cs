using System.IO;
using System.Text.Json;

namespace KioslyDesktop.Services
{
    public class AuthService
    {
        private readonly string _settingsFilePath;

        public AuthService()
        {
            var folder = System.Environment.SpecialFolder.LocalApplicationData;
            var path = System.Environment.GetFolderPath(folder);
            _settingsFilePath = Path.Join(path, "KioslyDesktop", "settings.json");
        }

        public void SaveSettings(object settings)
        {
            var json = JsonSerializer.Serialize(settings);
            File.WriteAllText(_settingsFilePath, json);
        }

        public string? GetLicenseKey()
        {
            if (!File.Exists(_settingsFilePath)) return null;
            var json = File.ReadAllText(_settingsFilePath);
            try
            {
                var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("license_key", out var keyProp))
                    return keyProp.GetString();
            }
            catch { }
            return null;
        }
    }
}
