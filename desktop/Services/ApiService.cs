using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace KioslyDesktop.Services
{
    public class ApiService
    {
        private const string BaseUrl = "https://cashiro.web.id";
        private readonly HttpClient _httpClient;

        public ApiService()
        {
            _httpClient = new HttpClient { BaseAddress = new Uri(BaseUrl) };
        }

        public async Task<JsonElement?> LoginWithLicenseAsync(string email, string licenseKey)
        {
            var payload = new { email, license_key = licenseKey };
            var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("/api/license/login", content);
            var responseString = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                return JsonSerializer.Deserialize<JsonElement>(responseString);
            }

            throw new Exception(ParseError(responseString));
        }

        private string ParseError(string responseBody)
        {
            try
            {
                var doc = JsonDocument.Parse(responseBody);
                if (doc.RootElement.TryGetProperty("error", out var errorProp))
                    return errorProp.GetString() ?? "Terjadi kesalahan";
                if (doc.RootElement.TryGetProperty("message", out var msgProp))
                    return msgProp.GetString() ?? "Terjadi kesalahan";
            }
            catch { }
            return "Gagal memproses data di server";
        }
    }
}
