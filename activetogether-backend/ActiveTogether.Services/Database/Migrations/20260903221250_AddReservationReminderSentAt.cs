using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ActiveTogether.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationReminderSentAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ReminderSentAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ReminderSentAt",
                table: "Reservations");
        }
    }
}
