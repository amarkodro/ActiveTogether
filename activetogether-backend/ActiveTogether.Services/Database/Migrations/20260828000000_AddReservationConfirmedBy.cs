using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ActiveTogether.Services.Database.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationConfirmedBy : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ConfirmedByUserId",
                table: "Reservations",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ConfirmedByUserId",
                table: "Reservations");
        }
    }
}
