using System.Security.Claims;
using DaoDuyKhai.ChamCongAPI.Data;
using DaoDuyKhai.ChamCongAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Controllers;

// CRUD nhân viên: Admin được thêm/sửa/xóa, QuanLy chỉ xem
[ApiController, Route("api/employees"), Authorize(Roles = "Admin,QuanLy")]
public class EmployeesController(AppDbContext db) : ControllerBase
{
    static readonly string[] Roles = ["Admin", "QuanLy", "NhanVien"];

    [HttpGet]
    public async Task<IActionResult> List(string? q)
    {
        var query = db.Users.Include(x => x.Department).Include(x => x.Shift).AsQueryable();
        if (!string.IsNullOrWhiteSpace(q)) query = query.Where(x => x.FullName.Contains(q) || x.Username.Contains(q) || x.Email.Contains(q));
        return Ok(await query.OrderBy(x => x.Id).ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> Get(int id)
    {
        var u = await db.Users.Include(x => x.Department).Include(x => x.Shift).FirstOrDefaultAsync(x => x.Id == id);
        return u == null ? NotFound() : Ok(u);
    }

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(EmployeeDto d)
    {
        if (string.IsNullOrWhiteSpace(d.Password) || d.Password.Length < 6) return BadRequest(new { message = "Mật khẩu tối thiểu 6 ký tự" });
        if (!Roles.Contains(d.Role)) return BadRequest(new { message = "Vai trò không hợp lệ" });
        if (await db.Users.AnyAsync(x => x.Username == d.Username || x.Email == d.Email)) return Conflict(new { message = "Tên đăng nhập hoặc email đã tồn tại" });
        var u = new User
        {
            Username = d.Username, Email = d.Email, FullName = d.FullName, Phone = d.Phone, Role = d.Role,
            DepartmentId = d.DepartmentId, ShiftId = d.ShiftId, IsActive = d.IsActive, IsEmailVerified = true,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(d.Password)
        };
        db.Users.Add(u);
        await db.SaveChangesAsync();
        return Ok(u);
    }

    [HttpPut("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, EmployeeDto d)
    {
        var u = await db.Users.FindAsync(id);
        if (u == null) return NotFound();
        if (!Roles.Contains(d.Role)) return BadRequest(new { message = "Vai trò không hợp lệ" });
        if (await db.Users.AnyAsync(x => x.Id != id && (x.Username == d.Username || x.Email == d.Email))) return Conflict(new { message = "Tên đăng nhập hoặc email đã tồn tại" });
        u.Username = d.Username; u.Email = d.Email; u.FullName = d.FullName; u.Phone = d.Phone; u.Role = d.Role;
        u.DepartmentId = d.DepartmentId; u.ShiftId = d.ShiftId; u.IsActive = d.IsActive;
        if (!string.IsNullOrWhiteSpace(d.Password)) u.PasswordHash = BCrypt.Net.BCrypt.HashPassword(d.Password);
        await db.SaveChangesAsync();
        return Ok(u);
    }

    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        if (id == int.Parse(User.FindFirstValue("uid")!)) return BadRequest(new { message = "Không thể tự xóa chính mình" });
        var u = await db.Users.FindAsync(id);
        if (u == null) return NotFound();
        db.Users.Remove(u);
        await db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa" });
    }
}
