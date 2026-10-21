using System.Security.Claims;
using DaoDuyKhai.ChamCongAPI.Data;
using DaoDuyKhai.ChamCongAPI.Models;
using DaoDuyKhai.ChamCongAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace DaoDuyKhai.ChamCongAPI.Controllers;

[ApiController, Route("api/attendance"), Authorize]
public class AttendanceController(AppDbContext db, QrService qr, IConfiguration cfg) : ControllerBase
{
    int Uid => int.Parse(User.FindFirstValue("uid")!);
    double OfficeLat => cfg.GetValue<double>("Office:Latitude");
    double OfficeLng => cfg.GetValue<double>("Office:Longitude");
    double Radius => cfg.GetValue("Office:RadiusMeters", 200.0);

    static object Row(Attendance a) => new
    {
        a.Id, a.UserId, fullName = a.User != null ? a.User.FullName : null, a.Date, a.CheckInTime, a.CheckOutTime,
        a.Method, a.Status, a.LateMinutes, a.EarlyMinutes, a.WorkHours, a.Note
    };

    // Kiểm tra: vị trí giả + khoảng cách tới công ty + QR động
    IActionResult? Validate(CheckDto d)
    {
        if (d.IsMockLocation) return BadRequest(new { message = "Phát hiện vị trí giả (Fake GPS). Không thể chấm công!" });
        var dist = Geo.Distance(d.Latitude, d.Longitude, OfficeLat, OfficeLng);
        if (dist > Radius) return BadRequest(new { message = $"Bạn đang cách công ty {dist:F0} m (cho phép {Radius:F0} m)" });
        if (d.Method == "QR" && !qr.Validate(d.QrToken)) return BadRequest(new { message = "Mã QR không hợp lệ hoặc đã hết hạn" });
        return null;
    }

    [HttpPost("check-in")]
    public async Task<IActionResult> CheckIn(CheckDto d)
    {
        var bad = Validate(d); if (bad != null) return bad;
        var now = Vn.Now;
        if (await db.Attendances.AnyAsync(x => x.UserId == Uid && x.Date == now.Date)) return Conflict(new { message = "Hôm nay bạn đã check-in rồi" });
        var user = await db.Users.Include(x => x.Shift).FirstAsync(x => x.Id == Uid);
        int late = 0;
        if (user.Shift != null)
        {
            var over = (now.TimeOfDay - user.Shift.StartTime).TotalMinutes - cfg.GetValue("Attendance:GraceMinutes", 5);
            if (over > 0) late = (int)Math.Ceiling(over);
        }
        var a = new Attendance
        {
            UserId = Uid, Date = now.Date, CheckInTime = now, CheckInLat = d.Latitude, CheckInLng = d.Longitude,
            Method = d.Method, LateMinutes = late, Status = late > 0 ? "DiTre" : "DungGio"
        };
        db.Attendances.Add(a);
        await db.SaveChangesAsync();
        return Ok(new { message = late > 0 ? $"Check-in thành công (đi trễ {late} phút)" : "Check-in đúng giờ. Chúc bạn làm việc tốt!", attendance = Row(a) });
    }

    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut(CheckDto d)
    {
        var bad = Validate(d); if (bad != null) return bad;
        var now = Vn.Now;
        var a = await db.Attendances.FirstOrDefaultAsync(x => x.UserId == Uid && x.Date == now.Date);
        if (a == null) return BadRequest(new { message = "Hôm nay bạn chưa check-in" });
        if (a.CheckOutTime != null) return Conflict(new { message = "Hôm nay bạn đã check-out rồi" });
        var user = await db.Users.Include(x => x.Shift).FirstAsync(x => x.Id == Uid);
        a.CheckOutTime = now; a.CheckOutLat = d.Latitude; a.CheckOutLng = d.Longitude;
        a.WorkHours = Math.Round((now - a.CheckInTime).TotalHours, 2);
        if (user.Shift != null && now.TimeOfDay < user.Shift.EndTime) a.EarlyMinutes = (int)(user.Shift.EndTime - now.TimeOfDay).TotalMinutes;
        await db.SaveChangesAsync();
        return Ok(new { message = $"Check-out thành công. Hôm nay bạn làm {a.WorkHours} giờ", attendance = Row(a) });
    }

    [HttpGet("today")]
    public async Task<IActionResult> Today()
    {
        var now = Vn.Now;
        var a = await db.Attendances.FirstOrDefaultAsync(x => x.UserId == Uid && x.Date == now.Date);
        var user = await db.Users.Include(x => x.Shift).FirstAsync(x => x.Id == Uid);
        return Ok(new { record = a == null ? null : Row(a), shift = user.Shift, radius = Radius });
    }

    [HttpGet("my")]
    public async Task<IActionResult> My(int? month, int? year)
    {
        var n = Vn.Now; var from = new DateTime(year ?? n.Year, month ?? n.Month, 1);
        var list = await db.Attendances.Where(x => x.UserId == Uid && x.Date >= from && x.Date < from.AddMonths(1)).OrderByDescending(x => x.Date).ToListAsync();
        return Ok(list.Select(Row));
    }

    // ---- Quản trị ----
    [HttpGet, Authorize(Roles = "Admin,QuanLy")]
    public async Task<IActionResult> List(DateTime? date, int? userId)
    {
        var q = db.Attendances.Include(x => x.User).AsQueryable();
        if (date != null) q = q.Where(x => x.Date == date.Value.Date);
        if (userId != null) q = q.Where(x => x.UserId == userId);
        return Ok((await q.OrderByDescending(x => x.CheckInTime).Take(300).ToListAsync()).Select(Row));
    }

    [HttpPut("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Edit(int id, AttendanceEditDto d)
    {
        var a = await db.Attendances.FindAsync(id); if (a == null) return NotFound();
        a.Status = d.Status; a.Note = d.Note; await db.SaveChangesAsync(); return Ok(new { message = "Đã cập nhật" });
    }

    [HttpDelete("{id:int}"), Authorize(Roles = "Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        var a = await db.Attendances.FindAsync(id); if (a == null) return NotFound();
        db.Attendances.Remove(a); await db.SaveChangesAsync(); return Ok(new { message = "Đã xóa" });
    }

    [HttpGet("summary-today"), Authorize(Roles = "Admin,QuanLy")]
    public async Task<IActionResult> SummaryToday()
    {
        var d = Vn.Now.Date;
        return Ok(new
        {
            totalEmployees = await db.Users.CountAsync(x => x.Role == "NhanVien" && x.IsActive),
            present = await db.Attendances.CountAsync(x => x.Date == d),
            late = await db.Attendances.CountAsync(x => x.Date == d && x.LateMinutes > 0),
            onLeave = await db.LeaveRequests.CountAsync(x => x.Status == "DaDuyet" && x.FromDate <= d && x.ToDate >= d),
            pendingLeaves = await db.LeaveRequests.CountAsync(x => x.Status == "ChoDuyet")
        });
    }

    // Báo cáo tháng: số ngày công, số lần đi trễ, tổng giờ làm của từng nhân viên
    [HttpGet("report"), Authorize(Roles = "Admin,QuanLy")]
    public async Task<IActionResult> Report(int month, int year)
    {
        var from = new DateTime(year, month, 1);
        var data = await db.Attendances.Where(a => a.Date >= from && a.Date < from.AddMonths(1))
            .GroupBy(a => new { a.UserId, a.User!.FullName })
            .Select(g => new
            {
                userId = g.Key.UserId, fullName = g.Key.FullName, days = g.Count(),
                lateCount = g.Count(a => a.LateMinutes > 0), lateMinutes = g.Sum(a => a.LateMinutes),
                totalHours = Math.Round(g.Sum(a => a.WorkHours), 2)
            }).OrderBy(x => x.fullName).ToListAsync();
        return Ok(data);
    }

    // QR động cho màn hình đặt tại công ty
    [HttpGet("/api/qr/current"), Authorize(Roles = "Admin,QuanLy")]
    public IActionResult Qr() { var (t, e) = qr.Current(); return Ok(new { token = t, expiresIn = e }); }
}
