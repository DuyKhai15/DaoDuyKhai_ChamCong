using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Mail;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using DaoDuyKhai.ChamCongAPI.Models;
using Microsoft.IdentityModel.Tokens;
namespace DaoDuyKhai.ChamCongAPI.Services;

public class TokenService(IConfiguration cfg)
{
    public string Create(User u)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(cfg["Jwt:Key"]!));
        var claims = new[] { new Claim("uid", u.Id.ToString()), new Claim("name", u.Username), new Claim("role", u.Role) };
        var token = new JwtSecurityToken(cfg["Jwt:Issuer"], cfg["Jwt:Audience"], claims,
            expires: DateTime.UtcNow.AddHours(cfg.GetValue("Jwt:ExpireHours", 12)),
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}

public class EmailService(IConfiguration cfg, ILogger<EmailService> log)
{
    public async Task SendAsync(string to, string subject, string body)
    {
        if (!cfg.GetValue<bool>("Email:Enabled")) { log.LogWarning("[DEV] Email to {To}: {Body}", to, body); return; }
        using var client = new SmtpClient(cfg["Email:Host"], cfg.GetValue("Email:Port", 587))
        {
            EnableSsl = true,
            Credentials = new NetworkCredential(cfg["Email:User"], cfg["Email:AppPassword"])
        };
        var msg = new MailMessage { From = new MailAddress(cfg["Email:User"]!, cfg["Email:FromName"]), Subject = subject, Body = body };
        msg.To.Add(to);
        await client.SendMailAsync(msg);
    }
}

/// QR động: đổi mỗi 30 giây, ký HMAC => không thể chụp ảnh QR gửi cho người khác chấm hộ.
public class QrService(IConfiguration cfg)
{
    const int Step = 30;
    static long Window() => DateTimeOffset.UtcNow.ToUnixTimeSeconds() / Step;
    string Sign(long w)
    {
        using var h = new HMACSHA256(Encoding.UTF8.GetBytes(cfg["Attendance:QrSecret"]!));
        return Convert.ToHexString(h.ComputeHash(Encoding.UTF8.GetBytes(w.ToString())))[..16];
    }
    public (string token, int expiresIn) Current()
    {
        var w = Window();
        var left = Step - (int)(DateTimeOffset.UtcNow.ToUnixTimeSeconds() % Step);
        return ($"CC|{w}|{Sign(w)}", left);
    }
    public bool Validate(string? token)
    {
        var p = token?.Split('|');
        if (p is not { Length: 3 } || p[0] != "CC" || !long.TryParse(p[1], out var w)) return false;
        if (Math.Abs(Window() - w) > 1) return false;
        return CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(Sign(w)), Encoding.UTF8.GetBytes(p[2]));
    }
}

public static class Geo
{
    public static double Distance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371000;
        double d(double x) => x * Math.PI / 180;
        var a = Math.Pow(Math.Sin(d(lat2 - lat1) / 2), 2) + Math.Cos(d(lat1)) * Math.Cos(d(lat2)) * Math.Pow(Math.Sin(d(lon2 - lon1) / 2), 2);
        return 2 * R * Math.Asin(Math.Sqrt(a));
    }
}
