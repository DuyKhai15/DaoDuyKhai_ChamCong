using DaoDuyKhai.ChamCongAPI.Data;
using DaoDuyKhai.ChamCongAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Controllers;

[ApiController, Route("api/departments"), Authorize]
public class DepartmentsController(AppDbContext db) : ControllerBase
{
    [HttpGet] public async Task<IActionResult> List() => Ok(await db.Departments.OrderBy(x => x.Id).ToListAsync());

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(Department d) { d.Id = 0; db.Departments.Add(d); await db.SaveChangesAsync(); return Ok(d); }

    [HttpPut("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, Department d)
    {
        var x = await db.Departments.FindAsync(id); if (x == null) return NotFound();
        x.Name = d.Name; x.Description = d.Description; await db.SaveChangesAsync(); return Ok(x);
    }

    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var x = await db.Departments.FindAsync(id); if (x == null) return NotFound();
        if (await db.Users.AnyAsync(u => u.DepartmentId == id)) return BadRequest(new { message = "Phòng ban đang có nhân viên, không thể xóa" });
        db.Departments.Remove(x); await db.SaveChangesAsync(); return Ok(new { message = "Đã xóa" });
    }
}

[ApiController, Route("api/shifts"), Authorize]
public class ShiftsController(AppDbContext db) : ControllerBase
{
    [HttpGet] public async Task<IActionResult> List() => Ok(await db.Shifts.OrderBy(x => x.Id).ToListAsync());

    [HttpPost, Authorize(Roles = "Admin")]
    public async Task<IActionResult> Create(Shift s)
    {
        if (s.EndTime <= s.StartTime) return BadRequest(new { message = "Giờ kết thúc phải sau giờ bắt đầu" });
        s.Id = 0; db.Shifts.Add(s); await db.SaveChangesAsync(); return Ok(s);
    }

    [HttpPut("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Update(int id, Shift s)
    {
        var x = await db.Shifts.FindAsync(id); if (x == null) return NotFound();
        if (s.EndTime <= s.StartTime) return BadRequest(new { message = "Giờ kết thúc phải sau giờ bắt đầu" });
        x.Name = s.Name; x.StartTime = s.StartTime; x.EndTime = s.EndTime; await db.SaveChangesAsync(); return Ok(x);
    }

    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var x = await db.Shifts.FindAsync(id); if (x == null) return NotFound();
        if (await db.Users.AnyAsync(u => u.ShiftId == id)) return BadRequest(new { message = "Ca đang được gán cho nhân viên, không thể xóa" });
        db.Shifts.Remove(x); await db.SaveChangesAsync(); return Ok(new { message = "Đã xóa" });
    }
}
