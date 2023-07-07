using Microsoft.AspNetCore.Mvc;
using PuppeteerSharp;

namespace PdfConverter.Controllers
{
	public record ConversionRequest(string Url, string OutputFileName);

	[ApiController]
	[Route("api/convert")]
	public sealed class ConvertController : ControllerBase
	{
		[HttpPost]
		public async Task<IActionResult> ConvertToPdf([FromBody] ConversionRequest request)
		{
			var url = DecodeUrl(request.Url);
			var outputFileName = request.OutputFileName.ToLower().EndsWith(".pdf") ? request.OutputFileName : $"{request.OutputFileName}.pdf";

			// Generate unique output file path
			var outputFile = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid()}.pdf");

			await new BrowserFetcher().DownloadAsync(BrowserFetcher.DefaultChromiumRevision);
			var launchOptions = new LaunchOptions
			{
				Headless = true,
				Args = new[] { "--no-sandbox" } // Disable the sandbox
			};
			using (var browser = await Puppeteer.LaunchAsync(launchOptions))
			using (var page = await browser.NewPageAsync())
			{
				await page.GoToAsync(url);
				await page.PdfAsync(outputFile);
			}

			// Read the generated PDF file
			var fileBytes = await System.IO.File.ReadAllBytesAsync(outputFile);

			// Clean up the temporary PDF file
			System.IO.File.Delete(outputFile);

			// Return the PDF file as the API response
			return File(fileBytes, "application/pdf", outputFileName);
		}

		private static string DecodeUrl(string encodedUrl)
		{
			var bytes = Convert.FromBase64String(encodedUrl);
			return System.Text.Encoding.UTF8.GetString(bytes);
		}
	}
}