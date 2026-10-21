using System.Text.Json.Serialization;
namespace DaoDuyKhai.ChamCongAPI.Models;

public class Department { public int Id { get; set; } public string Name { get; set; } = ""; public string? Description { get; set; } }

public class Shift
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
}

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = "";
    public string Email { get; set; } = "";
    [JsonIgnore] public string PasswordHash { get; set; } = "";
    public string FullName { get; set; } = "";
    public string? Phone { get; set; }
    public string Role { get; set; } = "NhanVien";   // Admin | QuanLy | NhanVien
    public bool IsEmailVerified { get; set; }
    public bool IsActive { get; set; } = true;
    public int? DepartmentId { get; set; }
    public Department? Department { get; set; }
    public int? ShiftId { get; set; }
    public Shift? Shift { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class OtpCode
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Code { get; set; } = "";
    public string Purpose { get; set; } = "Login";   // Register | Login
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
}

public class Attendance
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public DateTime Date { get; set; }
    public DateTime CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public double CheckInLat { get; set; }
    public double CheckInLng { get; set; }
    public double? CheckOutLat { get; set; }
    public double? CheckOutLng { get; set; }
    public string Method { get; set; } = "GPS";      // GPS | QR | BIOMETRIC
    public string Status { get; set; } = "DungGio";   // DungGio | DiTre
    public int LateMinutes { get; set; }
    public int EarlyMinutes { get; set; }
    public double WorkHours { get; set; }
    public string? Note { get; set; }
}

public class LeaveRequest
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public User? User { get; set; }
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string Reason { get; set; } = "";
    public string Status { get; set; } = "ChoDuyet";  // ChoDuyet | DaDuyet | TuChoi
    public string? ReviewNote { get; set; }
}

public record RegisterDto(string Username, string Email, string Password, string FullName, string? Phone);
public record LoginDto(string Username, string Password);
public record VerifyOtpDto(int UserId, string Code);
public record ResendOtpDto(int UserId, string Purpose);
public record EmployeeDto(string Username, string Email, string? Password, string FullName, string? Phone, string Role, int? DepartmentId, int? ShiftId, bool IsActive);
public record CheckDto(double Latitude, double Longitude, string Method, string? QrToken, bool IsMockLocation);
public record LeaveDto(DateTime FromDate, DateTime ToDate, string Reason);
public record ReviewDto(string Status, string? Note);
public record AttendanceEditDto(string Status, string? Note);

public static class Vn { public static DateTime Now => DateTime.UtcNow.AddHours(7); }
