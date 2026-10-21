using System.Security.Claims;
using DaoDuyKhai.ChamCongAPI.Data;
using DaoDuyKhai.ChamCongAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Controllers;

[ApiController, Route("api/leaves"), Authorize]
public class LeaveController(AppDbContext db) : ControllerBase
{
    int Uid => int.Parse(User.FindFirstValue("uid")!);

    static object Row(LeaveRequest l) => new { l.Id, l.UserId, fullName = l.User != null ? l.User.FullName : null, l.FromDate, l.ToDate, l.Reason, l.Status, l.ReviewNote };

    [HttpGet("my")]
    public async Task<IActionResult> My() => Ok((await db.LeaveRequests.Where(x => x.UserId == Uid).OrderByDescending(x => x.Id).ToListAsync()).Select(Row));

    [HttpGet, Authorize(Roles = "Admin,QuanLy")]
    public async Task<IActionResult> All() => Ok((await db.LeaveRequests.Include(x => x.User).OrderByDescending(x => x.Id).ToListAsync()).Select(Row));

    [HttpPost]
    public async Task<IActionResult> Create(LeaveDto d)
    {
        if (d.ToDate < d.FromDate) return BadRequest(new { message = "Ngày kết thúc phải sau ngày bắt đầu" });
        if (string.IsNullOrWhiteSpace(d.Reason)) return BadRequest(new { message = "Vui lòng nhập lý do" });
        var l = new LeaveRequest { UserId = Uid, FromDate = d.FromDate.Date, ToDate = d.ToDate.Date, Reason = d.Reason };
        db.LeaveRequests.Add(l); await db.SaveChangesAsync();
        return Ok(Row(l));
    }

    [HttpPut("{id:int}/review"), Authorize(Roles = "Admin,QuanLy")]
    public async Task<IActionResult> Review(int id, ReviewDto d)
    {
        var l = await db.LeaveRequests.FindAsync(id); if (l == null) return NotFound();
        if (d.Status is not ("DaDuyet" or "TuChoi")) return BadRequest(new { message = "Trạng thái không hợp lệ" });
        l.Status = d.Status; l.ReviewNote = d.Note; await db.SaveChangesAsync();
        return Ok(new { message = "Đã cập nhật" });
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var l = await db.LeaveRequests.FindAsync(id); if (l == null) return NotFound();
        var isAdmin = User.IsInRole("Admin");
        if (!isAdmin && (l.UserId != Uid || l.Status != "ChoDuyet")) return StatusCode(403, new { message = "Chỉ được xóa đơn của mình khi chưa duyệt" });
        db.LeaveRequests.Remove(l); await db.SaveChangesAsync();
        return Ok(new { message = "Đã xóa" });
    }
}
