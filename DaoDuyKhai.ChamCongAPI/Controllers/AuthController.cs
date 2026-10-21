using System.Security.Claims;
using System.Security.Cryptography;
using DaoDuyKhai.ChamCongAPI.Data;
using DaoDuyKhai.ChamCongAPI.Models;
using DaoDuyKhai.ChamCongAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Controllers;

[ApiController, Route("api/auth")]
public class AuthController(AppDbContext db, TokenService tokens, EmailService mail, IConfiguration cfg) : ControllerBase
{
    // Khi Email:Enabled=false (dev) -> trả OTP về app để demo không cần SMTP
    async Task<string?> SendOtp(User u, string purpose)
    {
        var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        db.OtpCodes.Add(new OtpCode { UserId = u.Id, Code = code, Purpose = purpose, ExpiresAt = DateTime.UtcNow.AddMinutes(5) });
        await db.SaveChangesAsync();
        await mail.SendAsync(u.Email, "Mã OTP - DaoDuyKhai ChamCong", $"Mã OTP của bạn là {code}. Có hiệu lực trong 5 phút.");
        return cfg.GetValue<bool>("Email:Enabled") ? null : code;
    }

    async Task<bool> ConsumeOtp(int userId, string code, string purpose)
    {
        var o = await db.OtpCodes.Where(x => x.UserId == userId && x.Purpose == purpose && !x.IsUsed && x.ExpiresAt > DateTime.UtcNow && x.Code == code)
            .OrderByDescending(x => x.Id).FirstOrDefaultAsync();
        if (o == null) return false;
        o.IsUsed = true;
        await db.SaveChangesAsync();
        return true;
    }

    // 1. Đăng ký tài khoản qua email (mặc định vai trò NhanVien) -> xác thực email bằng OTP
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto d)
    {
        if (string.IsNullOrWhiteSpace(d.Username) || d.Password.Length < 6) return BadRequest(new { message = "Tên đăng nhập bắt buộc, mật khẩu tối thiểu 6 ký tự" });
        if (!d.Email.Contains('@')) return BadRequest(new { message = "Email không hợp lệ" });
        if (await db.Users.AnyAsync(x => x.Username == d.Username)) return Conflict(new { message = "Tên đăng nhập đã tồn tại" });
        if (await db.Users.AnyAsync(x => x.Email == d.Email)) return Conflict(new { message = "Email đã được sử dụng" });
        var shift = await db.Shifts.FirstOrDefaultAsync();
        var u = new User { Username = d.Username.Trim(), Email = d.Email.Trim(), FullName = d.FullName, Phone = d.Phone, ShiftId = shift?.Id, PasswordHash = BCrypt.Net.BCrypt.HashPassword(d.Password) };
        db.Users.Add(u);
        await db.SaveChangesAsync();
        var dev = await SendOtp(u, "Register");
        return Ok(new { message = "Đã gửi OTP xác thực về email", userId = u.Id, devOtp = dev });
    }

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail(VerifyOtpDto d)
    {
        if (!await ConsumeOtp(d.UserId, d.Code, "Register")) return BadRequest(new { message = "OTP sai hoặc đã hết hạn" });
        var u = await db.Users.FindAsync(d.UserId);
        u!.IsEmailVerified = true;
        await db.SaveChangesAsync();
        return Ok(new { message = "Xác thực email thành công, hãy đăng nhập" });
    }

    // 2. Đăng nhập: bước 1 = tên đăng nhập + mật khẩu -> gửi OTP
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto d)
    {
        var u = await db.Users.FirstOrDefaultAsync(x => x.Username == d.Username);
        if (u == null || !BCrypt.Net.BCrypt.Verify(d.Password, u.PasswordHash)) return Unauthorized(new { message = "Sai tên đăng nhập hoặc mật khẩu" });
        if (!u.IsActive) return StatusCode(403, new { message = "Tài khoản đã bị khóa" });
        if (!u.IsEmailVerified)
        {
            var dev0 = await SendOtp(u, "Register");
            return StatusCode(403, new { message = "Email chưa xác thực. Đã gửi lại OTP xác thực", needVerify = true, userId = u.Id, devOtp = dev0 });
        }
        var dev = await SendOtp(u, "Login");
        return Ok(new { message = "Đã gửi OTP đăng nhập về email", userId = u.Id, devOtp = dev });
    }

    // bước 2 = OTP -> JWT (chứa role để app phân quyền)
    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp(VerifyOtpDto d)
    {
        if (!await ConsumeOtp(d.UserId, d.Code, "Login")) return BadRequest(new { message = "OTP sai hoặc đã hết hạn" });
        var u = await db.Users.Include(x => x.Department).Include(x => x.Shift).FirstAsync(x => x.Id == d.UserId);
        return Ok(new { token = tokens.Create(u), user = u });
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> Resend(ResendOtpDto d)
    {
        var u = await db.Users.FindAsync(d.UserId);
        if (u == null) return NotFound();
        var dev = await SendOtp(u, d.Purpose == "Register" ? "Register" : "Login");
        return Ok(new { message = "Đã gửi lại OTP", devOtp = dev });
    }

    [HttpGet("me"), Authorize]
    public async Task<IActionResult> Me()
    {
        var id = int.Parse(User.FindFirstValue("uid")!);
        return Ok(await db.Users.Include(x => x.Department).Include(x => x.Shift).FirstAsync(x => x.Id == id));
    }
}
