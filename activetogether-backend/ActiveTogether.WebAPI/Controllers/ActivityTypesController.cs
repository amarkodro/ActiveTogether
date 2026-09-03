using ActiveTogether.Model.Constants;
using ActiveTogether.Model.Requests;
using ActiveTogether.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ActiveTogether.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ActivityTypesController : ControllerBase
    {
        private readonly IActivityTypeService _service;

        public ActivityTypesController(IActivityTypeService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] ReferenceSearchObject search)
        {
            return Ok(await _service.GetPagedAsync(search));
        }

        /// <summary>
        /// Kompletan (neparaginiran) spisak tipova aktivnosti, namijenjen za dropdown/lookup prikaze.
        /// </summary>
        [HttpGet("lookup")]
        public async Task<IActionResult> GetLookup()
        {
            return Ok(await _service.GetAllAsync());
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            return Ok(await _service.GetByIdAsync(id));
        }

        [HttpPost]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Create([FromBody] ActivityTypeUpsertRequest request)
        {
            var result = await _service.CreateAsync(request);
            return CreatedAtAction(nameof(GetById), new { id = result.Id }, result);
        }

        [HttpPut("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Update(int id, [FromBody] ActivityTypeUpsertRequest request)
        {
            return Ok(await _service.UpdateAsync(id, request));
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Delete(int id)
        {
            await _service.DeleteAsync(id);
            return NoContent();
        }
    }
}