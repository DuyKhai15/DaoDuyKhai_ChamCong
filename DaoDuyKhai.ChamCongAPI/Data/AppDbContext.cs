using DaoDuyKhai.ChamCongAPI.Models;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Department> Departments => Set<Department>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<OtpCode> OtpCodes => Set<OtpCode>();
    public DbSet<Attendance> Attendances => Set<Attendance>();
    public DbSet<LeaveRequest> LeaveRequests => Set<LeaveRequest>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<User>().HasIndex(x => x.Username).IsUnique();
        b.Entity<User>().HasIndex(x => x.Email).IsUnique();
        b.Entity<Attendance>().HasIndex(x => new { x.UserId, x.Date }).IsUnique();
    }
}

public static class Seed
{
    public static void Run(AppDbContext db)
    {
        if (db.Users.Any()) return;
        var shift = new Shift { Name = "Ca hành chính", StartTime = new TimeSpan(8, 0, 0), EndTime = new TimeSpan(17, 0, 0) };
        var dep = new Department { Name = "Phòng IT", Description = "Công nghệ thông tin" };
        db.Shifts.Add(shift);
        db.Departments.AddRange(dep, new Department { Name = "Phòng Nhân sự", Description = "Hành chính - nhân sự" });
        db.SaveChanges();
        db.Users.AddRange(
            new User { Username = "admin", Email = "admin@daoduykhai.com", FullName = "Đào Duy Khải (Admin)", Role = "Admin", IsEmailVerified = true, PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin@123") },
            new User { Username = "ql01", Email = "ql01@daoduykhai.com", FullName = "Quản lý Demo", Role = "QuanLy", IsEmailVerified = true, DepartmentId = dep.Id, ShiftId = shift.Id, PasswordHash = BCrypt.Net.BCrypt.HashPassword("Ql@12345") },
            new User { Username = "nv01", Email = "nv01@daoduykhai.com", FullName = "Nhân viên Demo", Role = "NhanVien", IsEmailVerified = true, DepartmentId = dep.Id, ShiftId = shift.Id, PasswordHash = BCrypt.Net.BCrypt.HashPassword("Nv@12345") });
        db.SaveChanges();
    }
}
